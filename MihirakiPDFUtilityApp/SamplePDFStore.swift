import CryptoKit
import Foundation
import Network
import Observation

@MainActor
@Observable
final class SamplePDFStore {
    static let maximumFileSize: Int64 = 100 * 1024 * 1024

    private(set) var catalog: SamplePDFCatalog?
    private(set) var states: [String: SamplePDFDownloadState] = [:]
    private(set) var isUsingCellular = false
    private(set) var isNetworkPathKnown = false
    var errorMessage: String?

    private let fileManager: FileManager
    private let session: URLSession
    private let catalogBundle: Bundle
    private let documentsDirectory: URL
    private var isRefreshingCatalog = false
    private let pathMonitor: NWPathMonitor
    private let pathMonitorQueue = DispatchQueue(label: "SamplePDFStore.NetworkPath")

    init(
        fileManager: FileManager = .default,
        session: URLSession = .shared,
        catalogBundle: Bundle = .main,
        documentsDirectory: URL = .documentsDirectory,
        pathMonitor: NWPathMonitor = NWPathMonitor()
    ) {
        self.fileManager = fileManager
        self.session = session
        self.catalogBundle = catalogBundle
        self.documentsDirectory = documentsDirectory
        self.pathMonitor = pathMonitor

        pathMonitor.pathUpdateHandler = { [weak self] path in
            let cellular = path.status == .satisfied && path.usesInterfaceType(.cellular)
            Task { @MainActor [weak self] in
                self?.isUsingCellular = cellular
                self?.isNetworkPathKnown = true
            }
        }
        pathMonitor.start(queue: pathMonitorQueue)
    }

    deinit {
        pathMonitor.cancel()
    }

    func loadCatalog() {
        guard catalog == nil else { refreshDownloadStates(); return }
        do {
            guard let url = catalogBundle.url(
                forResource: "SamplePDFCatalog",
                withExtension: "json"
            ) else {
                throw SamplePDFStoreError.catalogUnavailable
            }

            let decodedCatalog = try JSONDecoder().decode(
                SamplePDFCatalog.self,
                from: Data(contentsOf: url)
            )
            try Self.validate(decodedCatalog)
            // A malformed cached list must never prevent the bundled fallback from loading.
            let cached = try? Data(contentsOf: catalogCacheURL)
            let cachedCatalog = cached.flatMap { try? JSONDecoder().decode(SamplePDFCatalog.self, from: $0) }
            let validCached = cachedCatalog.flatMap { candidate -> SamplePDFCatalog? in
                do { try Self.validate(candidate); return candidate } catch { return nil }
            }
            catalog = validCached ?? decodedCatalog
            migrateLegacyFilesIfPossible(for: catalog?.samples ?? decodedCatalog.samples)
            refreshDownloadStates()
        } catch {
            errorMessage = SamplePDFStoreError.catalogUnavailable.localizedDescription
        }
    }

    private var catalogCacheURL: URL {
        documentsDirectory.appending(path: "MihirakiSamplePdfs/catalog-v1.json")
    }

    /// Best-effort metadata refresh. An offline/invalid response keeps the usable list.
    @discardableResult
    func refreshCatalog() async -> Bool {
        guard !isRefreshingCatalog else { return false }
        if catalog == nil { loadCatalog() }
        guard let previous = catalog else { return false }
        isRefreshingCatalog = true
        defer { isRefreshingCatalog = false }
        do {
            var request = URLRequest(url: SamplePDFURLPolicy.manifestURL,
                cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
            // Metadata refresh must not silently use the mobile-data download path.
            request.allowsCellularAccess = false
            let (bytes, response) = try await session.bytes(for: request,
                delegate: SamplePDFRedirectDelegate(manifest: true))
            guard let response = response as? HTTPURLResponse, response.statusCode == 200,
                  response.expectedContentLength <= Int64(SamplePDFURLPolicy.maximumManifestSize) else {
                throw SamplePDFStoreError.invalidServerResponse
            }
            try SamplePDFURLPolicy.validateResponse(response.url, manifest: true)
            var data = Data()
            for try await byte in bytes {
                guard data.count < SamplePDFURLPolicy.maximumManifestSize else {
                    throw SamplePDFStoreError.invalidCatalog
                }
                data.append(byte)
            }
            try Task.checkCancellation()
            try applyManifest(data, preserving: previous)
            return true
        } catch {
            // Do not replace a working catalog or show a download error merely for being offline.
            return false
        }
    }

    func applyManifest(_ data: Data, preserving previous: SamplePDFCatalog) throws {
        guard data.count <= SamplePDFURLPolicy.maximumManifestSize else {
            throw SamplePDFStoreError.invalidCatalog
        }
        let manifest = try JSONDecoder().decode(SamplePDFManifest.self, from: data)
        // Even if a previous remote list omitted an uninstalled sample, keep the
        // bundled identity/name mapping when that ID reappears (notably fil -> tl).
        var identities = previous.samples
        if let url = catalogBundle.url(forResource: "SamplePDFCatalog", withExtension: "json"),
           let bundledData = try? Data(contentsOf: url),
           let bundled = try? JSONDecoder().decode(SamplePDFCatalog.self, from: bundledData) {
            try Self.validate(bundled)
            let previousIDs = Set(identities.map(\.id))
            identities += bundled.samples.filter { !previousIDs.contains($0.id) }
        }
        let known = SamplePDFCatalog(schemaVersion: previous.schemaVersion,
            license: previous.license, samples: identities)
        var candidate = try manifest.catalog(preserving: known)
        try Self.validate(candidate)
        // Keep the exact metadata/cache path of installed or in-flight PDFs, even if
        // the latest manifest changes or omits them. Only explicit user actions delete PDFs.
        let retained = previous.samples.filter { sample in
            fileManager.fileExists(atPath: localURL(for: sample).path)
                || state(for: sample) == .downloading || state(for: sample) == .deleting
        }
        let retainedByID = Dictionary(uniqueKeysWithValues: retained.map { ($0.id, $0) })
        var merged = candidate.samples.map { retainedByID[$0.id] ?? $0 }
        let candidateIDs = Set(merged.map(\.id))
        merged += retained.filter { !candidateIDs.contains($0.id) }
        candidate = SamplePDFCatalog(schemaVersion: candidate.schemaVersion,
            license: candidate.license, samples: merged)
        try Self.validate(candidate)
        let encoded = try JSONEncoder().encode(candidate)
        try fileManager.createDirectory(at: catalogCacheURL.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try encoded.write(to: catalogCacheURL, options: .atomic)
        catalog = candidate
        refreshDownloadStates()
    }

    func refreshDownloadStates() {
        guard let catalog else { return }

        for sample in catalog.samples {
            let state = states[sample.id]
            guard state != .downloading, state != .deleting else { continue }
            states[sample.id] = fileManager.fileExists(atPath: localURL(for: sample).path)
                ? .downloaded
                : .notDownloaded
        }
    }

    func state(for sample: SamplePDF) -> SamplePDFDownloadState {
        states[sample.id] ?? .notDownloaded
    }

    func download(_ sample: SamplePDF, allowsCellular: Bool) async {
        guard state(for: sample) != .downloading else { return }
        // A metadata update never triggers re-download of an installed PDF.
        if fileManager.fileExists(atPath: localURL(for: sample).path) {
            states[sample.id] = .downloaded
            return
        }

        states[sample.id] = .downloading
        errorMessage = nil

        do {
            try Self.validateDownloadURL(sample.downloadURL)
            let destinationURL = localURL(for: sample)
            let destinationDirectory = destinationURL.deletingLastPathComponent()
            try fileManager.createDirectory(
                at: destinationDirectory,
                withIntermediateDirectories: true
            )

            var request = URLRequest(
                url: sample.downloadURL,
                cachePolicy: .reloadIgnoringLocalCacheData,
                timeoutInterval: 300
            )
            request.allowsCellularAccess = allowsCellular
            let (temporaryURL, response) = try await session.download(for: request,
                delegate: SamplePDFRedirectDelegate(manifest: false))
            // Failed validation must not leave a temporary download behind.
            defer { try? fileManager.removeItem(at: temporaryURL) }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw SamplePDFStoreError.invalidServerResponse
            }
            try Self.validateResponseURL(httpResponse.url)
            try await Self.validateDownloadedFile(at: temporaryURL, sample: sample)

            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: temporaryURL, to: destinationURL)

            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            var mutableDestinationURL = destinationURL
            try mutableDestinationURL.setResourceValues(resourceValues)

            states[sample.id] = .downloaded
        } catch is CancellationError {
            states[sample.id] = .notDownloaded
        } catch {
            states[sample.id] = .notDownloaded
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? SamplePDFStoreError.downloadFailed.localizedDescription
        }
    }

    @discardableResult
    func delete(_ sample: SamplePDF) -> Bool {
        states[sample.id] = .deleting
        errorMessage = nil

        do {
            let url = localURL(for: sample)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            // Remove verified directory if empty
            let dirURL = url.deletingLastPathComponent()
            if let contents = try? fileManager.contentsOfDirectory(atPath: dirURL.path), contents.isEmpty {
                try? fileManager.removeItem(at: dirURL)
            }

            // Also remove legacy file if present
            let legacyURL = legacyLocalURL(for: sample)
            if fileManager.fileExists(atPath: legacyURL.path) {
                try? fileManager.removeItem(at: legacyURL)
            }

            states[sample.id] = .notDownloaded
            return true
        } catch {
            states[sample.id] = .downloaded
            errorMessage = SamplePDFStoreError.deleteFailed.localizedDescription
            return false
        }
    }

    // fileName is the stable on-device name, not the remote URL basename.
    // In particular, Filipino ep1/ep2 retain _fil.pdf while the release uses _tl.pdf.
    func localURL(for sample: SamplePDF) -> URL {
        documentsDirectory
            .appending(path: "MihirakiSamplePdfs/verified", directoryHint: .isDirectory)
            .appending(path: sample.sha256.lowercased(), directoryHint: .isDirectory)
            .appending(path: sample.fileName, directoryHint: .notDirectory)
    }

    private func legacyLocalURL(for sample: SamplePDF) -> URL {
        documentsDirectory
            .appending(path: "SamplePDFs", directoryHint: .isDirectory)
            .appending(path: sample.fileName, directoryHint: .notDirectory)
    }

    private func migrateLegacyFilesIfPossible(for samples: [SamplePDF]) {
        for sample in samples {
            let verifiedPath = localURL(for: sample)
            if fileManager.fileExists(atPath: verifiedPath.path) {
                continue
            }
            let legacyPath = legacyLocalURL(for: sample)
            guard fileManager.fileExists(atPath: legacyPath.path) else {
                continue
            }
            // Verify size matches before migrating
            if let values = try? legacyPath.resourceValues(forKeys: [.fileSizeKey]),
               Int64(values.fileSize ?? 0) == sample.byteSize {
                let dir = verifiedPath.deletingLastPathComponent()
                try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
                try? fileManager.moveItem(at: legacyPath, to: verifiedPath)
            }
        }
    }

    static func validate(_ catalog: SamplePDFCatalog) throws {
        guard catalog.schemaVersion == 2 || catalog.schemaVersion == 1,
              catalog.license.identifier == "CC-BY-4.0",
              catalog.license.url.scheme == "https",
              catalog.license.url.host == "creativecommons.org",
              !catalog.samples.isEmpty else {
            throw SamplePDFStoreError.invalidCatalog
        }

        var ids = Set<String>()
        var fileNames = Set<String>()

        for sample in catalog.samples {
            guard !sample.id.isEmpty,
                  ids.insert(sample.id).inserted,
                  fileNames.insert(sample.fileName).inserted,
                  sample.byteSize > 0,
                  sample.byteSize <= maximumFileSize,
                  SamplePDFURLPolicy.isSafeFileName(sample.fileName),
                  sample.sha256.count == 64,
                  sample.sha256.allSatisfy(\.isHexDigit) else {
                throw SamplePDFStoreError.invalidCatalog
            }
            try validateDownloadURL(sample.downloadURL)
        }
    }

    static func validateDownloadURL(_ url: URL?) throws {
        try SamplePDFURLPolicy.validateDownload(url)
    }

    static func validateResponseURL(_ url: URL?) throws {
        try SamplePDFURLPolicy.validateResponse(url, manifest: false)
    }

    private static func validateDownloadedFile(at url: URL, sample: SamplePDF) async throws {
        let maximumFileSize = Self.maximumFileSize

        try await Task.detached(priority: .userInitiated) {
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            let actualSize = Int64(values.fileSize ?? 0)
            guard actualSize > 0,
                  actualSize <= maximumFileSize,
                  actualSize == sample.byteSize else {
                throw SamplePDFStoreError.invalidFileSize
            }

            let fileHandle = try FileHandle(forReadingFrom: url)
            defer { try? fileHandle.close() }

            guard let header = try fileHandle.read(upToCount: 5),
                  header == Data("%PDF-".utf8) else {
                throw SamplePDFStoreError.invalidPDF
            }

            try fileHandle.seek(toOffset: 0)
            var hasher = SHA256()
            while let chunk = try fileHandle.read(upToCount: 1024 * 1024), !chunk.isEmpty {
                hasher.update(data: chunk)
            }

            let digest = hasher.finalize().map { String(format: "%02x", $0) }.joined()
            guard digest == sample.sha256.lowercased() else {
                throw SamplePDFStoreError.checksumMismatch
            }
        }.value
    }
}

enum SamplePDFStoreError: LocalizedError {
    case catalogUnavailable
    case invalidCatalog
    case invalidDownloadURL
    case invalidServerResponse
    case invalidFileSize
    case invalidPDF
    case checksumMismatch
    case downloadFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .catalogUnavailable, .invalidCatalog:
            String(localized: "The sample PDF list could not be loaded.")
        case .invalidDownloadURL:
            String(localized: "The sample PDF download URL is invalid.")
        case .invalidServerResponse:
            String(localized: "The sample PDF could not be downloaded from the server.")
        case .invalidFileSize:
            String(localized: "The downloaded file size is invalid.")
        case .invalidPDF:
            String(localized: "The downloaded file is not a valid PDF.")
        case .checksumMismatch:
            String(localized: "The downloaded PDF failed its integrity check.")
        case .downloadFailed:
            String(localized: "The sample PDF could not be downloaded.")
        case .deleteFailed:
            String(localized: "The sample PDF could not be deleted.")
        }
    }
}

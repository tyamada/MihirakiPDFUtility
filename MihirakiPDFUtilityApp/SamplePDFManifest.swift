import Foundation

/// Public distribution format; intentionally separate from the app's bundled/cache format.
struct SamplePDFManifest: Decodable {
    let schemaVersion: Int
    let license: String
    let entries: [Entry]

    struct Entry: Decodable {
        let sampleID: String
        let episode: Int
        let languageKey: String
        let locale: String
        let title: String
        let filename: String
        let pages: Int
        let bytes: Int64
        let sha256: String
        let license: String
        let newDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case sampleID = "sample_id", episode, languageKey = "language_key", locale
            case title, filename, pages, bytes, sha256, license
            case newDownloadURL = "new_download_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version", license, entries
    }

    func catalog(preserving known: SamplePDFCatalog) throws -> SamplePDFCatalog {
        guard schemaVersion == 1, license == "CC-BY-4.0", !entries.isEmpty,
              entries.count <= 1000 else { throw SamplePDFStoreError.invalidCatalog }
        let knownByID = Dictionary(uniqueKeysWithValues: known.samples.map { ($0.id, $0) })
        let languages = Set(SamplePDFLanguages.entries.map(\.code))
        var ids = Set<String>()
        var urls = Set<URL>()
        let samples = try entries.map { entry in
            guard ids.insert(entry.sampleID).inserted,
                  urls.insert(entry.newDownloadURL).inserted,
                  entry.episode > 0, entry.pages > 0, !entry.locale.isEmpty,
                  !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  languages.contains(entry.languageKey),
                  entry.sampleID == "ep\(entry.episode)_\(entry.languageKey)",
                  entry.license == license,
                  SamplePDFURLPolicy.isSafeFileName(entry.filename),
                  entry.newDownloadURL.lastPathComponent == entry.filename else {
                throw SamplePDFStoreError.invalidCatalog
            }
            try SamplePDFURLPolicy.validateDownload(entry.newDownloadURL)
            let existing = knownByID[entry.sampleID]
            guard existing == nil || (existing?.languageCode == entry.languageKey
                && existing?.episode == entry.episode) else {
                throw SamplePDFStoreError.invalidCatalog
            }
            // Remote filenames may change (fil -> tl); on-device cache keys must not.
            return SamplePDF(id: entry.sampleID, title: entry.title,
                languageCode: existing?.languageCode ?? entry.languageKey,
                fileName: existing?.fileName ?? entry.filename,
                downloadURL: entry.newDownloadURL, byteSize: entry.bytes,
                sha256: entry.sha256.lowercased(), episode: entry.episode, pages: entry.pages)
        }
        return SamplePDFCatalog(schemaVersion: 2, license: known.license, samples: samples)
    }
}

enum SamplePDFURLPolicy {
    static let manifestURL = URL(string: "https://raw.githubusercontent.com/tyamada/manga-prompt-kit/main/releases/pdf-manifest.json")!
    static let maximumManifestSize = 2 * 1024 * 1024

    static func isSafeFileName(_ value: String) -> Bool {
        !value.isEmpty && value != "." && value != ".."
            && value.utf8.allSatisfy { byte in
                (65...90).contains(byte) || (97...122).contains(byte)
                    || (48...57).contains(byte) || [45, 46, 95].contains(byte)
            } && value.lowercased().hasSuffix(".pdf")
    }

    static func validateDownload(_ url: URL?) throws {
        guard let url, url.scheme == "https", url.host == "github.com",
              url.user == nil, url.password == nil, url.port == nil,
              url.query == nil, url.fragment == nil,
              !url.absoluteString.contains("%"),
              url.pathComponents.count == 7 else {
            throw SamplePDFStoreError.invalidDownloadURL
        }
        let parts = url.pathComponents
        let tag = parts[5]
        guard Array(parts[1...4]) == ["tyamada", "manga-prompt-kit", "releases", "download"],
              tag != "latest", tag != ".", tag != "..", !tag.isEmpty,
              tag.utf8.allSatisfy({ byte in
                  (65...90).contains(byte) || (97...122).contains(byte)
                    || (48...57).contains(byte) || [45, 46, 95].contains(byte)
              }), isSafeFileName(parts[6]) else {
            throw SamplePDFStoreError.invalidDownloadURL
        }
    }

    static func validateResponse(_ url: URL?, manifest: Bool) throws {
        guard let url, url.scheme == "https", url.user == nil, url.password == nil,
              url.port == nil else { throw SamplePDFStoreError.invalidDownloadURL }
        if manifest {
            guard url == manifestURL else { throw SamplePDFStoreError.invalidDownloadURL }
        } else {
            guard ["github.com", "objects.githubusercontent.com", "release-assets.githubusercontent.com"]
                .contains(url.host ?? "") else { throw SamplePDFStoreError.invalidDownloadURL }
        }
    }
}

/// Check each redirect before allowing the next network request, not just the final URL.
final class SamplePDFRedirectDelegate: NSObject, URLSessionTaskDelegate, Sendable {
    let manifest: Bool
    init(manifest: Bool) { self.manifest = manifest }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        do {
            try SamplePDFURLPolicy.validateResponse(request.url, manifest: manifest)
            completionHandler(request)
        } catch {
            completionHandler(nil)
        }
    }
}

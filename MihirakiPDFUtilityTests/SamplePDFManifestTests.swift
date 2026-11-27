import Foundation
import Testing
@testable import MihirakiPDFUtility

private final class ManifestFixtureAnchor: NSObject {}

@Suite(.serialized)
@MainActor
struct SamplePDFManifestTests {
    private func bundled() throws -> SamplePDFCatalog {
        let url = try #require(Bundle.main.url(forResource: "SamplePDFCatalog", withExtension: "json"))
        return try JSONDecoder().decode(SamplePDFCatalog.self, from: Data(contentsOf: url))
    }

    private func fixture() throws -> Data {
        let url = try #require(Bundle(for: ManifestFixtureAnchor.self)
            .url(forResource: "pdf-manifest-fixture", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    private func modified(_ edit: (inout [String: Any]) -> Void) throws -> Data {
        var object = try #require(JSONSerialization.jsonObject(with: fixture()) as? [String: Any])
        edit(&object)
        return try JSONSerialization.data(withJSONObject: object)
    }

    private func temporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    @Test("Published v1 manifest maps all 51 entries without changing identities or cache keys")
    func publishedManifest() throws {
        let previous = try bundled()
        let manifest = try JSONDecoder().decode(SamplePDFManifest.self, from: fixture())
        let result = try manifest.catalog(preserving: previous)
        try SamplePDFStore.validate(result)
        #expect(result.samples.count == 51)
        for original in previous.samples {
            let updated = try #require(result.samples.first { $0.id == original.id })
            #expect(updated == original)
        }
        let filipino = result.samples.filter { $0.languageCode == "fil" }
        #expect(filipino.count == 3)
        #expect(filipino.filter { $0.episode < 3 }.allSatisfy { $0.fileName.hasSuffix("_fil.pdf") })
        #expect(filipino.allSatisfy { $0.downloadURL.lastPathComponent.hasSuffix("_tl.pdf") })
    }

    @Test("Invalid manifest cannot replace either memory or the persisted last-good catalog")
    func invalidManifestsKeepLastGood() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = SamplePDFStore(documentsDirectory: root)
        store.loadCatalog()
        try store.applyManifest(fixture(), preserving: try #require(store.catalog))
        let expected = store.catalog
        let cache = root.appendingPathComponent("MihirakiSamplePdfs/catalog-v1.json")
        let cachedBytes = try Data(contentsOf: cache)
        var invalid: [Data] = [Data("{invalid".utf8)]
        invalid += [
            try modified { $0["schema_version"] = 999 },
            try modified { $0["entries"] = [] },
            try modified { $0["license"] = "all-rights-reserved" },
            try modified {
                var entries = $0["entries"] as! [[String: Any]]
                entries.append(entries[0]); $0["entries"] = entries
            }
        ]
        for (field, value) in [
            ("new_download_url", "http://github.com/tyamada/manga-prompt-kit/releases/download/v2/a.pdf" as Any),
            ("new_download_url", "https://example.com/a.pdf" as Any),
            ("filename", "../escape.pdf" as Any),
            ("sha256", "bad" as Any), ("bytes", 0 as Any), ("bytes", 200_000_000 as Any),
            ("sample_id", "ep1_tl" as Any), ("language_key", "tl" as Any),
            ("pages", 0 as Any), ("license", "CC-BY-NC" as Any)
        ] {
            invalid.append(try modified {
                var entries = $0["entries"] as! [[String: Any]]
                entries[0][field] = value; $0["entries"] = entries
            })
        }
        invalid.append(Data(repeating: 32, count: SamplePDFURLPolicy.maximumManifestSize + 1))
        for data in invalid {
            #expect(throws: (any Error).self) {
                try store.applyManifest(data, preserving: try #require(store.catalog))
            }
            #expect(store.catalog == expected)
            #expect(try Data(contentsOf: cache) == cachedBytes)
        }
    }

    @Test("Cache reload remains offline and corrupted cache falls back to bundled data")
    func cachedAndBundledOfflineFallback() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = SamplePDFStore(documentsDirectory: root)
        store.loadCatalog()
        let data = try modified {
            var entries = $0["entries"] as! [[String: Any]]
            entries[0]["title"] = "Updated remote title"; $0["entries"] = entries
        }
        try store.applyManifest(data, preserving: try #require(store.catalog))
        let reloaded = SamplePDFStore(documentsDirectory: root)
        reloaded.loadCatalog()
        #expect(reloaded.catalog?.samples.first?.title == "Updated remote title")
        try Data("broken cache".utf8).write(to: root.appendingPathComponent("MihirakiSamplePdfs/catalog-v1.json"))
        let fallback = SamplePDFStore(documentsDirectory: root)
        fallback.loadCatalog()
        #expect(fallback.catalog == (try bundled()))
    }

    @Test("Installed PDFs survive replacement metadata and removal from the remote list")
    func installedFilesAreNeverReplaced() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = SamplePDFStore(documentsDirectory: root)
        store.loadCatalog()
        let sample = try #require(store.catalog?.samples.first { $0.id == "ep1_fil" })
        let localURL = store.localURL(for: sample)
        try FileManager.default.createDirectory(at: localURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let sentinel = Data("existing PDF cache must remain untouched".utf8)
        try sentinel.write(to: localURL)
        let changed = try modified {
            var entries = $0["entries"] as! [[String: Any]]
            let index = entries.firstIndex { $0["sample_id"] as? String == sample.id }!
            entries[index]["sha256"] = String(repeating: "a", count: 64)
            entries[index]["bytes"] = 1234
            $0["entries"] = entries
        }
        try store.applyManifest(changed, preserving: try #require(store.catalog))
        #expect(store.catalog?.samples.first { $0.id == sample.id } == sample)
        #expect(store.state(for: sample) == .downloaded)
        let omitted = try modified {
            $0["entries"] = ($0["entries"] as! [[String: Any]]).filter { $0["sample_id"] as? String != sample.id }
        }
        try store.applyManifest(omitted, preserving: try #require(store.catalog))
        #expect(store.catalog?.samples.first { $0.id == sample.id } == sample)
        #expect(try Data(contentsOf: localURL) == sentinel)
        let reloaded = SamplePDFStore(documentsDirectory: root)
        reloaded.loadCatalog()
        #expect(reloaded.state(for: sample) == .downloaded)
        #expect(reloaded.localURL(for: sample) == localURL)
    }

    @Test("A temporarily omitted Filipino ID keeps its original cache name when it returns")
    func omittedIdentityReturnsWithStableName() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = SamplePDFStore(documentsDirectory: root)
        store.loadCatalog()
        let original = try #require(store.catalog?.samples.first { $0.id == "ep1_fil" })
        let omitted = try modified {
            $0["entries"] = ($0["entries"] as! [[String: Any]]).filter { $0["sample_id"] as? String != original.id }
        }
        try store.applyManifest(omitted, preserving: try #require(store.catalog))
        #expect(store.catalog?.samples.contains { $0.id == original.id } == false)
        try store.applyManifest(fixture(), preserving: try #require(store.catalog))
        #expect(store.catalog?.samples.first { $0.id == original.id } == original)
    }

    @Test("Only fixed release PDF URLs and exact HTTPS metadata source are accepted")
    func urlValidation() throws {
        try SamplePDFStore.validateDownloadURL(URL(string: "https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261201-v1/new.pdf"))
        for value in [
            "https://github.com/tyamada/manga-prompt-kit/releases/latest/download/a.pdf",
            "https://github.com/tyamada/manga-prompt-kit/releases/download/latest/a.pdf",
            "https://github.com/tyamada/manga-prompt-kit/releases/download/v1/../a.pdf",
            "https://github.com/tyamada/manga-prompt-kit/releases/download/v1/%2e%2e.pdf",
            "https://github.com/tyamada/manga-prompt-kit/releases/download/v1/a.pdf?url=bad",
            "https://user@github.com/tyamada/manga-prompt-kit/releases/download/v1/a.pdf",
            "https://github.com:443/tyamada/manga-prompt-kit/releases/download/v1/a.pdf",
            "https://github.com/other/repo/releases/download/v1/a.pdf"
        ] {
            #expect(throws: SamplePDFStoreError.self) { try SamplePDFStore.validateDownloadURL(URL(string: value)) }
        }
        try SamplePDFURLPolicy.validateResponse(SamplePDFURLPolicy.manifestURL, manifest: true)
        for value in ["http://raw.githubusercontent.com/tyamada/manga-prompt-kit/main/releases/pdf-manifest.json",
                      "https://raw.githubusercontent.com/other/repo/main/pdf-manifest.json",
                      "https://example.com/pdf-manifest.json"] {
            #expect(throws: SamplePDFStoreError.self) {
                try SamplePDFURLPolicy.validateResponse(URL(string: value), manifest: true)
            }
        }
    }

    @Test("Successful network refresh persists metadata; offline, HTTP and corrupt responses retain it")
    func networkRefreshAndFailures() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ManifestURLProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let store = SamplePDFStore(session: session, documentsDirectory: root)
        store.loadCatalog()
        ManifestURLProtocol.set(data: try modified {
            var entries = $0["entries"] as! [[String: Any]]
            entries[0]["title"] = "Fetched remote title"; $0["entries"] = entries
        })
        #expect(await store.refreshCatalog())
        #expect(store.catalog?.samples.first?.title == "Fetched remote title")
        let previous = store.catalog
        for mode in 0...3 {
            switch mode {
            case 0: ManifestURLProtocol.set(data: Data(), error: URLError(.notConnectedToInternet))
            case 1: ManifestURLProtocol.set(data: Data(), status: 503)
            case 2: ManifestURLProtocol.set(data: Data("bad JSON".utf8))
            default: ManifestURLProtocol.set(data: Data(repeating: 32, count: SamplePDFURLPolicy.maximumManifestSize + 1))
            }
            #expect(await !store.refreshCatalog())
            #expect(store.catalog == previous)
            #expect(store.errorMessage == nil)
        }
    }
}

private final class ManifestURLProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var payload = Data()
    nonisolated(unsafe) private static var status = 200
    nonisolated(unsafe) private static var failure: URLError?

    static func set(data: Data, status: Int = 200, error: URLError? = nil) {
        lock.lock(); defer { lock.unlock() }
        payload = data; self.status = status; failure = error
    }
    override class func canInit(with request: URLRequest) -> Bool { request.url == SamplePDFURLPolicy.manifestURL }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        let data = Self.payload, status = Self.status, error = Self.failure
        Self.lock.unlock()
        if let error { client?.urlProtocol(self, didFailWithError: error); return }
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil,
            headerFields: ["Content-Length": String(data.count)])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

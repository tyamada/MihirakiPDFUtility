import CryptoKit
import Foundation
import PDFKit
import Testing
@testable import MihirakiPDFUtility

private final class Episode4FixtureAnchor: NSObject {}

@Suite(.serialized)
@MainActor
struct Episode4IntegrationTests {
    @Test("Episode 4 extends the old 51 list and keeps cached samples and Filipino aliases")
    func extendsCachedCatalog() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = SamplePDFStore(documentsDirectory: root)
        store.loadCatalog()
        let old = try #require(store.catalog)
        #expect(old.samples.count == 51)
        let retained = try #require(old.samples.first { $0.id == "ep1_ja" })
        let cache = store.localURL(for: retained)
        try FileManager.default.createDirectory(at: cache.deletingLastPathComponent(), withIntermediateDirectories: true)
        let saved = Data("existing cache sentinel".utf8)
        try saved.write(to: cache)
        let fixture = try #require(Bundle(for: Episode4FixtureAnchor.self).url(forResource: "episode4-manifest-fixture", withExtension: "json"))
        try store.applyManifest(Data(contentsOf: fixture), preserving: old)
        let latest = try #require(store.catalog)
        #expect(latest.samples.count == 52)
        let ja = latest.samples.filter { $0.languageCode == "ja" }
        #expect(ja.count == 4)
        #expect(SamplePDFSortOrder.latestFirst.sort(samples: ja).first?.id == "ep4_ja")
        #expect(latest.samples.filter { $0.episode == 4 }.map(\.languageCode) == ["ja"])
        for original in old.samples {
            #expect(latest.samples.first { $0.id == original.id } == original)
        }
        #expect(try Data(contentsOf: cache) == saved)
        #expect(store.state(for: retained) == .downloaded)
        let restarted = SamplePDFStore(documentsDirectory: root)
        restarted.loadCatalog()
        #expect(restarted.catalog?.samples.count == 52)
        #expect(restarted.state(for: retained) == .downloaded)
    }

    @Test("Live manifest refresh downloads episode 4 and opens the verified eight-page PDF")
    func liveDownloadAndOpen() async throws {
        // Run only in the dedicated simulator created by the integration runner.
        let store = SamplePDFStore()
        store.loadCatalog()
        let refreshed = await store.refreshCatalog()
        #expect(refreshed)
        let catalog = try #require(store.catalog)
        #expect(catalog.samples.count >= 52)
        let sample = try #require(catalog.samples.first { $0.id == "ep4_ja" })
        #expect(sample.episode == 4 && sample.languageCode == "ja" && sample.pages == 8)
        #expect(sample.byteSize == 99_981_486)
        #expect(sample.sha256 == "7c4bde39dc25800aa097854c6e47f31934abe12b3a05d97450fb73523af3c3dc")
        #expect(sample.downloadURL.absoluteString == "https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261127-ep4-ja-v1/tameshibu_episode4_ja.pdf")
        await store.download(sample, allowsCellular: false)
        #expect(store.errorMessage == nil)
        #expect(store.state(for: sample) == .downloaded)
        let url = store.localURL(for: sample)
        let data = try Data(contentsOf: url)
        #expect(data.count == 99_981_486)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        #expect(digest == sample.sha256)
        let pdf = try #require(PDFDocument(url: url))
        #expect(pdf.pageCount == 8 && !pdf.isLocked)
        #expect(pdf.page(at: 0) != nil && pdf.page(at: 7) != nil)
        let offline = SamplePDFStore()
        offline.loadCatalog() // No network request: persisted list and PDF remain usable.
        #expect(offline.catalog?.samples.contains { $0.id == "ep4_ja" } == true)
        #expect(offline.state(for: sample) == .downloaded)
        print("EP4_VERIFIED path=\(url.path) bytes=\(data.count) sha256=\(digest) pages=\(pdf.pageCount)")
    }
}

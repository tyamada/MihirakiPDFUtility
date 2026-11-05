import Foundation
import Testing
@testable import MihirakiPDFUtility

@MainActor
struct SamplePDFTests {
    @Test("The bundled sample catalog is valid")
    func bundledCatalogIsValid() throws {
        let url = try #require(
            Bundle.main.url(forResource: "SamplePDFCatalog", withExtension: "json")
        )
        let catalog = try JSONDecoder().decode(
            SamplePDFCatalog.self,
            from: Data(contentsOf: url)
        )

        try SamplePDFStore.validate(catalog)

        #expect(catalog.schemaVersion == 2)
        #expect(catalog.license.identifier == "CC-BY-4.0")
        #expect(catalog.license.creator == "Komairo Hiyori")
        #expect(catalog.samples.count == 51)
        #expect(Set(catalog.samples.map(\.id)).count == 51)
        #expect(Set(catalog.samples.map(\.fileName)).count == 51)
    }

    @Test("Catalog samples point to the approved GitHub Releases directory")
    func catalogUsesApprovedHost() throws {
        let catalog = try loadCatalog()

        for sample in catalog.samples {
            #expect(sample.downloadURL.scheme == "https")
            #expect(sample.downloadURL.host == "github.com")
            #expect(sample.downloadURL.path.hasPrefix("/tyamada/MihirakiPDFUtility_Android/releases/download/sample-manga-v2/"))
            #expect(sample.byteSize <= SamplePDFStore.maximumFileSize)
            let digestLength = sample.sha256.count
            let isHexDigest = sample.sha256.allSatisfy(\.isHexDigit)
            #expect(digestLength == 64)
            #expect(isHexDigest)
            #expect((1...3).contains(sample.episode))
        }
    }

    @Test("Catalog validation rejects an unapproved download host")
    func invalidHostIsRejected() throws {
        let catalog = try loadCatalog()
        let original = try #require(catalog.samples.first)
        let invalidSample = SamplePDF(
            id: original.id,
            title: original.title,
            languageCode: original.languageCode,
            fileName: original.fileName,
            downloadURL: try #require(URL(string: "https://example.com/sample.pdf")),
            byteSize: original.byteSize,
            sha256: original.sha256,
            episode: original.episode,
            pages: original.pages
        )
        let invalidCatalog = SamplePDFCatalog(
            schemaVersion: catalog.schemaVersion,
            license: catalog.license,
            samples: [invalidSample]
        )

        #expect(throws: SamplePDFStoreError.self) {
            try SamplePDFStore.validate(invalidCatalog)
        }
    }

    @Test("Sample languages cover all 17 distinct regional entries")
    func sampleLanguagesCoverAllEntries() {
        #expect(SamplePDFLanguages.entries.count == 17)
        let codes = Set(SamplePDFLanguages.entries.map(\.code))
        #expect(codes.contains("ja"))
        #expect(codes.contains("en"))
        #expect(codes.contains("es_419"))
        #expect(codes.contains("pt_pt"))
        #expect(codes.contains("zh_hk"))
    }

    @Test("The language filter matches a preferred language with a region")
    func languageFilterMatchesRegion() {
        let result = SamplePDFLanguageFilter.initialLanguageCode(
            preferredLanguages: ["ja-JP"],
            availableLanguageCodes: ["en", "ja", "ko", "zh_cn"]
        )

        #expect(result == "ja")
    }

    @Test("The language filter falls back to Latin America Spanish when appropriate")
    func languageFilterMatchesLatinAmericaSpanish() {
        let result = SamplePDFLanguageFilter.initialLanguageCode(
            preferredLanguages: ["es-MX"],
            availableLanguageCodes: ["en", "es", "es_419"]
        )

        #expect(result == "es_419")
    }

    @Test("The language filter falls back to English")
    func languageFilterFallsBackToEnglish() {
        let result = SamplePDFLanguageFilter.initialLanguageCode(
            preferredLanguages: ["it-IT"],
            availableLanguageCodes: ["en", "ja", "ko"]
        )

        #expect(result == "en")
    }

    @Test("Sample sorting orders by episode correctly")
    func sortOrderSortsByEpisode() throws {
        let catalog = try loadCatalog()
        let sortedLatest = SamplePDFSortOrder.latestFirst.sort(samples: catalog.samples)
        #expect(sortedLatest.first?.episode == 3)
        #expect(sortedLatest.last?.episode == 1)

        let sortedEpisode1 = SamplePDFSortOrder.episode1First.sort(samples: catalog.samples)
        #expect(sortedEpisode1.first?.episode == 1)
        #expect(sortedEpisode1.last?.episode == 3)
    }

    private func loadCatalog() throws -> SamplePDFCatalog {
        let url = try #require(
            Bundle.main.url(forResource: "SamplePDFCatalog", withExtension: "json")
        )
        return try JSONDecoder().decode(
            SamplePDFCatalog.self,
            from: Data(contentsOf: url)
        )
    }
}

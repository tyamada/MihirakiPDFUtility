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

        #expect(catalog.schemaVersion == 1)
        #expect(catalog.license.identifier == "CC-BY-4.0")
        #expect(catalog.samples.count == 14)
        #expect(Set(catalog.samples.map(\.id)).count == catalog.samples.count)
        #expect(Set(catalog.samples.map(\.fileName)).count == catalog.samples.count)
    }

    @Test("Catalog samples point to the approved GitHub Pages directory")
    func catalogUsesApprovedHost() throws {
        let catalog = try loadCatalog()

        for sample in catalog.samples {
            #expect(sample.downloadURL.scheme == "https")
            #expect(sample.downloadURL.host == "tyamada.github.io")
            #expect(sample.downloadURL.path.hasPrefix("/MihirakiPDFViewer/sample/"))
            #expect(sample.byteSize <= SamplePDFStore.maximumFileSize)
            let digestLength = sample.sha256.count
            let isHexDigest = sample.sha256.allSatisfy(\.isHexDigit)
            #expect(digestLength == 64)
            #expect(isHexDigest)
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
            sha256: original.sha256
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

    @Test("The language filter matches a preferred language with a region")
    func languageFilterMatchesRegion() {
        let result = SamplePDFLanguageFilter.initialLanguageCode(
            preferredLanguages: ["ja-JP"],
            availableLanguageCodes: ["en", "ja", "ko", "zh-Hans"]
        )

        #expect(result == "ja")
    }

    @Test("The language filter falls back to English")
    func languageFilterFallsBackToEnglish() {
        let result = SamplePDFLanguageFilter.initialLanguageCode(
            preferredLanguages: ["es-MX"],
            availableLanguageCodes: ["en", "ja", "ko"]
        )

        #expect(result == "en")
    }

    @Test("The language filter can select all when no fallback exists")
    func languageFilterCanSelectAll() {
        let result = SamplePDFLanguageFilter.initialLanguageCode(
            preferredLanguages: ["es-MX"],
            availableLanguageCodes: ["ja", "ko"]
        )

        #expect(result == nil)
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

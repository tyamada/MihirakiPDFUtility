import Foundation
import PDFKit
import Testing
@testable import MihirakiPDFUtility

@Suite("Performance and stress tests", .serialized)
struct PerformanceAndStressTests {
    @Test("The on-device performance report contains environment and privacy information")
    @MainActor
    func performanceReportContents() async {
        let report = await PerformanceTestRunner.run()

        #expect(!report.deviceName.isEmpty)
        #expect(!report.operatingSystem.isEmpty)
        #expect(report.measurements.map(\.id) == ["cpu", "memory", "pdf"])
        #expect(report.measurements.allSatisfy { $0.duration > .zero })
        #expect(report.text.contains("Test Date:"))
        #expect(report.text.contains("Device:"))
        #expect(report.text.contains("OS:"))
        #expect(report.text.contains("not sent externally"))
    }

    @Test("A 1,100-page PDF loads and exports within the regression limit")
    @MainActor
    func largePDFPerformance() throws {
        let sourceURL = try #require(largePDFURL())
        let model = PDFEditorModel()
        let clock = ContinuousClock()

        let openDuration = clock.measure {
            _ = model.open(sourceURL)
        }

        #expect(model.pages.count == 1_100)
        #expect(openDuration < .seconds(30))

        let exportDuration = try clock.measure {
            let exported = try model.exportDocument()
            let reopened = try #require(PDFDocument(data: exported.data))
            #expect(reopened.pageCount == 1_100)
        }

        #expect(exportDuration < .seconds(30))
    }

    @Test("Bulk page editing remains responsive and preserves every page")
    @MainActor
    func bulkEditingPerformance() throws {
        let url = try makePDF(pageCount: 500)
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        #expect(model.open(url) == .opened)
        model.selection = Set(model.pages.enumerated().compactMap { index, page in
            index.isMultiple(of: 2) ? page.id : nil
        })

        let clock = ContinuousClock()
        let editDuration = clock.measure {
            model.rotateSelection(by: 90)
            model.moveSelectionToEnd()
            model.reverseSelectionOrder()
            model.moveSelectionToBeginning()
        }

        #expect(editDuration < .seconds(10))
        #expect(model.pages.count == 500)
        #expect(Set(model.pages.map(\.id)).count == 500)
        #expect(model.selection.count == 250)
        #expect(model.isModified)

        let exported = try model.exportDocument()
        let reopened = try #require(PDFDocument(data: exported.data))
        #expect(reopened.pageCount == 500)
    }

    @Test("Deterministic randomized editing exports a valid document")
    @MainActor
    func randomizedEditingStressTest() throws {
        let url = try makePDF(pageCount: 50)
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        #expect(model.open(url) == .opened)
        let originalIDs = Set(model.pages.map(\.id))
        var generator = SeededGenerator(seed: 0x4D_50_44_46)

        for _ in 0..<250 {
            let selectedIDs = (0..<5).map { _ in
                model.pages[Int.random(in: model.pages.indices, using: &generator)].id
            }
            model.selection = Set(selectedIDs)

            switch Int.random(in: 0..<5, using: &generator) {
            case 0:
                model.rotateSelection(by: 90)
            case 1:
                model.rotateSelection(by: -90)
            case 2:
                model.moveSelectionEarlier()
            case 3:
                model.moveSelectionLater()
            default:
                model.reverseSelectionOrder()
            }
        }

        #expect(model.pages.count == 50)
        #expect(Set(model.pages.map(\.id)) == originalIDs)
        #expect(model.pages.allSatisfy { [0, 90, 180, 270].contains($0.page.rotation) })

        let exported = try model.exportDocument()
        let reopened = try #require(PDFDocument(data: exported.data))
        #expect(reopened.pageCount == 50)
        #expect((0..<reopened.pageCount).allSatisfy { reopened.page(at: $0) != nil })
    }

    @Test("Truncated PDF-like data is rejected without changing the document")
    @MainActor
    func truncatedPDFStressTest() throws {
        let validURL = try makePDF(pageCount: 12)
        let truncatedURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("pdf")
        try Data("%PDF-1.7\n1 0 obj\n<< /Type /Catalog >>".utf8).write(to: truncatedURL)
        defer {
            try? FileManager.default.removeItem(at: validURL)
            try? FileManager.default.removeItem(at: truncatedURL)
        }

        let model = PDFEditorModel()
        #expect(model.open(validURL) == .opened)
        let originalIDs = model.pages.map(\.id)

        for _ in 0..<25 {
            #expect(model.open(truncatedURL) == .failed)
            #expect(model.pages.map(\.id) == originalIDs)
        }

        #expect(model.pages.count == 12)
        #expect(model.errorMessage != nil)
    }

    @Test("Diagnostic logs delete records older than 14 days")
    func diagnosticLogRetention() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = DiagnosticLogStore(baseDirectory: directory)
        let now = Date()
        let expiredDate = now.addingTimeInterval(-DiagnosticLogStore.retentionInterval - 1)

        await store.record(
            .documentOpened,
            category: .document,
            pageCount: 99,
            now: expiredDate
        )
        await store.record(
            .documentExported,
            category: .document,
            pageCount: 12,
            now: now
        )

        let records = await store.records(now: now)
        #expect(records.count == 1)
        #expect(records.first?.event == .documentExported)
        #expect(records.first?.pageCount == 12)
    }

    @Test("Diagnostic logs detect an unclosed previous session without storing private text")
    func diagnosticLogUnexpectedSessionAndPrivacy() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }

        let firstStore = DiagnosticLogStore(baseDirectory: directory)
        await firstStore.startSession()

        let relaunchedStore = DiagnosticLogStore(baseDirectory: directory)
        await relaunchedStore.startSession()

        let records = await relaunchedStore.records()
        let exportedText = await relaunchedStore.exportedText()

        #expect(records.contains { $0.event == .previousSessionEndedUnexpectedly })
        #expect(exportedText.contains("no file names"))
        #expect(exportedText.contains("not sent externally"))
        #expect(!exportedText.contains("password="))
        #expect(!exportedText.contains("path="))
    }

    private func largePDFURL() -> URL? {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let url = testsDirectory
            .deletingLastPathComponent()
            .appending(path: "testdata/load_test_1100_pages.pdf")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private func makePDF(pageCount: Int) throws -> URL {
        let data = NSMutableData()
        let consumer = try #require(CGDataConsumer(data: data as CFMutableData))
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        let context = try #require(CGContext(consumer: consumer, mediaBox: &mediaBox, nil))

        for pageNumber in 0..<pageCount {
            context.beginPDFPage(nil)
            context.setFillColor(CGColor(gray: 0.2, alpha: 1))
            context.fill(
                CGRect(
                    x: 72,
                    y: 700,
                    width: CGFloat(pageNumber % 10 + 1) * 40,
                    height: 8
                )
            )
            context.endPDFPage()
        }
        context.closePDF()

        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("pdf")
        try (data as Data).write(to: url)
        return url
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}

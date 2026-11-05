import Foundation
import Testing
@testable import MihirakiPDFUtility

struct DiagnosticReportExportTests {
    @Test func exportsEveryStatusAndEscapesJSON() throws {
        let statuses: [DiagnosticTestStatus] = [.passed, .failed, .skipped, .cancelled, .notRun]
        let report = DiagnosticTestReport(
            startedAt: Date(timeIntervalSince1970: 100), finishedAt: Date(timeIntervalSince1970: 200),
            results: statuses.map {
                DiagnosticTestResult(id: $0.rawValue, title: "Test", status: $0,
                                     duration: .microseconds(1500), detail: "日本語 \"quoted\"\nsecond line")
            }, wasInterrupted: true
        )
        let export = DiagnosticReportExport(report: report)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DiagnosticReportExport.self, from: export.jsonData())
        #expect(decoded.results.map(\.status) == statuses)
        #expect(decoded.results.allSatisfy { $0.milliseconds == 1.5 })
        #expect(decoded.results.first?.detail == "日本語 \"quoted\"\nsecond line")
        #expect(decoded.interrupted)
        #expect(decoded.environment == nil)
        #expect(export.text.contains("Run environment: unavailable"))
        for status in statuses { #expect(export.text.contains("\(status.rawValue): 1")) }
    }

    @Test @MainActor func sharingSurvivesCleanupRestoreAndDeletion() async throws {
        let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let store = DiagnosticReportStore(fileURL: base.appending(path: "report/latest.json"))
        let cases: [DiagnosticTestCase] = [.pdf(capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 })]
        let runner = DiagnosticsRunner(cases: cases, workspace: DiagnosticWorkspace(baseDirectory: base), store: store)
        await runner.run()
        #expect(try FileManager.default.contentsOfDirectory(atPath: base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
        let restored = DiagnosticsRunner(cases: cases, store: store)
        let snapshot = DiagnosticReportExport(report: try #require(restored.report))
        #expect(snapshot.results.first?.status == .passed)
        #expect(snapshot.environment?.testDefinitionVersion == 14)
        let jsonBefore = try snapshot.jsonData()
        restored.clearReport()
        #expect(restored.report == nil)
        #expect(try store.load() == nil)
        #expect(try snapshot.jsonData() == jsonBefore)
        #expect(!snapshot.text.contains(base.path))
        let object = try #require(try JSONSerialization.jsonObject(with: jsonBefore) as? [String: Any])
        #expect(object["deviceName"] == nil)
        #expect(object["filePath"] == nil)
    }

    @Test func olderCheckpointHasUnknownEnvironment() throws {
        let data = Data("""
        {"version":1,"startedAt":0,"updatedAt":1,"finished":false,"interrupted":false,"entries":[]}
        """.utf8)
        let checkpoint = try JSONDecoder().decode(DiagnosticCheckpoint.self, from: data)
        #expect(checkpoint.report.environment == nil)
        #expect(checkpoint.report.wasInterrupted)
    }
}

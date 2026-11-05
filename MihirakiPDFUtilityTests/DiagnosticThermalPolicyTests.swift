import Foundation
import Testing
@testable import MihirakiPDFUtility

struct DiagnosticThermalPolicyTests {
    @Test
    func thermalStates() {
        #expect(DiagnosticThermalPolicy(read: { .nominal }).skipReason() == nil)
        #expect(DiagnosticThermalPolicy(read: { .fair }).skipReason() == nil)
        #expect(DiagnosticThermalPolicy(read: { .serious }).skipReason() != nil)
        #expect(DiagnosticThermalPolicy(read: { .critical }).skipReason() != nil)
    }

    @Test @MainActor
    func hotDeviceSkipsWorkAndPersistsCleanup() async throws {
        let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let store = DiagnosticReportStore(fileURL: base.appending(path: "report.json"))
        let test = DiagnosticTestCase(id: "blocked", title: "Blocked") { _ in
            Issue.record("A hot device must not execute the case")
            return DiagnosticCaseOutcome(status: .passed, duration: .zero, detail: "")
        }
        let runner = DiagnosticsRunner(cases: [test], workspace: DiagnosticWorkspace(baseDirectory: base),
                                       store: store, thermalPolicy: DiagnosticThermalPolicy(read: { .critical }))
        await runner.run()
        #expect(runner.results.map(\.status) == [.skipped])
        let report = try #require(runner.report)
        let cleanup = try #require(report.finalCleanupMilliseconds)
        #expect(cleanup >= 0)
        #expect(try store.load()?.report.finalCleanupMilliseconds == cleanup)
        let exported = DiagnosticReportExport(report: report)
        #expect(exported.text.contains("Final workspace cleanup:"))
        let json = try JSONSerialization.jsonObject(with: exported.jsonData()) as? [String: Any]
        #expect(json?["finalCleanupMilliseconds"] as? Double == cleanup)
        #expect(try FileManager.default.contentsOfDirectory(atPath:
            base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
    }

    @Test @MainActor
    func temperatureIsRecheckedBetweenCases() async throws {
        let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }
        let signal = base.appending(path: "hot")
        let first = DiagnosticTestCase(id: "first", title: "First") { _ in
            try Data().write(to: signal)
            return DiagnosticCaseOutcome(status: .passed, duration: .zero, detail: "")
        }
        let second = DiagnosticTestCase(id: "second", title: "Second") { _ in
            Issue.record("The second case must be skipped")
            return DiagnosticCaseOutcome(status: .passed, duration: .zero, detail: "")
        }
        let runner = DiagnosticsRunner(cases: [first, second], workspace: DiagnosticWorkspace(baseDirectory: base),
            thermalPolicy: DiagnosticThermalPolicy(read: {
                FileManager.default.fileExists(atPath: signal.path) ? .serious : .nominal
            }))
        await runner.run()
        #expect(runner.results.map(\.status) == [.cancelled, .skipped])
    }

    @Test
    func oldCheckpointHasNoCleanupMeasurement() throws {
        let checkpoint = DiagnosticCheckpoint(startedAt: Date(), results: [], cases: [], finished: true)
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(checkpoint)) as? [String: Any])
        object.removeValue(forKey: "finalCleanupMilliseconds")
        let decoded = try JSONDecoder().decode(DiagnosticCheckpoint.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(decoded.report.finalCleanupMilliseconds == nil)
    }
}

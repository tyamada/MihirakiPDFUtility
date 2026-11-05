import Foundation
import Testing
@testable import MihirakiPDFUtility

struct DiagnosticResourceGuardTests {
    @Test @MainActor
    func pressureBeforeRunSkipsAllCases() async throws {
        let runner = DiagnosticsRunner(cases: [
            DiagnosticTestCase(id: "blocked", title: "Blocked") { _ in
                Issue.record("Memory pressure must prevent execution")
                return DiagnosticCaseOutcome(status: .passed, duration: .zero, detail: "")
            }
        ], thermalPolicy: DiagnosticThermalPolicy(read: { .nominal }), memoryPressure: { true })
        await runner.run()
        #expect(runner.results.map(\.status) == [.skipped])
        #expect(runner.results.first?.detail.isEmpty == false)
        #expect(runner.report?.finalCleanupMilliseconds != nil)
    }

    @Test @MainActor
    func resourceChangeDuringPDFGenerationCleansAndPersists() async throws {
        for thermal in [false, true] {
            let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: base) }
            let signal = base.appending(path: "started")
            let store = DiagnosticReportStore(fileURL: base.appending(path: "report.json"))
            let capacity = DiagnosticStorageCapacity { directory in
                if FileManager.default.fileExists(atPath: directory.appending(path: "basic-12.pdf").path) {
                    try? Data().write(to: signal)
                }
                return 4_000_000_000
            }
            let runner = DiagnosticsRunner(
                cases: [.pdf(capacity: capacity), DiagnosticTestCase(id: "later", title: "Later") { _ in
                    Issue.record("No later work may start after resource stop")
                    return DiagnosticCaseOutcome(status: .passed, duration: .zero, detail: "")
                }], workspace: DiagnosticWorkspace(baseDirectory: base), store: store,
                thermalPolicy: DiagnosticThermalPolicy(read: {
                    thermal && FileManager.default.fileExists(atPath: signal.path) ? .serious : .nominal
                }), memoryPressure: {
                    !thermal && FileManager.default.fileExists(atPath: signal.path)
                })
            await runner.run()
            #expect(runner.results.map(\.status) == [.cancelled, .skipped])
            #expect(runner.results[0].detail == runner.results[1].detail)
            #expect(!runner.cancellationRequested)
            #expect(try FileManager.default.contentsOfDirectory(atPath:
                base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
            #expect(try store.load()?.report.results.map(\.status) == [.cancelled, .skipped])
            let exported = DiagnosticReportExport(report: try #require(runner.report))
            #expect(exported.results[0].detail == runner.results[0].detail)
        }
    }

    @Test
    func taskLocalGuardDoesNotEscapeScope() throws {
        let guardValue = DiagnosticResourceGuard(thermalPolicy: DiagnosticThermalPolicy(read: { .nominal }),
                                                memoryPressure: { true })
        #expect(throws: DiagnosticResourceStop.self) {
            try DiagnosticResourceGuard.$current.withValue(guardValue) {
                try DiagnosticResourceGuard.check()
            }
        }
        try DiagnosticResourceGuard.check()
    }
}

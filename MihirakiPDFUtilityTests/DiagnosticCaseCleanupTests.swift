import Foundation
import Testing
@testable import MihirakiPDFUtility

struct DiagnosticCaseCleanupTests {
    @Test @MainActor
    func cleanupSurvivesSuccessFailureCancellationAndRestore() async throws {
        for status in [DiagnosticTestStatus.passed, .failed, .cancelled] {
            let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: base) }
            let store = DiagnosticReportStore(fileURL: base.appending(path: "report.json"))
            let test = DiagnosticTestCase(id: "fixture", title: "Fixture") { directory in
                let file = directory.appending(path: "fixture.pdf")
                try Data([1, 2, 3]).write(to: file)
                defer { DiagnosticCaseCleanup.remove(file) }
                if status == .cancelled { throw CancellationError() }
                if status == .failed { throw CocoaError(.fileReadCorruptFile) }
                return DiagnosticCaseOutcome(status: .passed, duration: .zero, detail: "")
            }
            let runner = DiagnosticsRunner(cases: [test], workspace: DiagnosticWorkspace(baseDirectory: base),
                                           store: store, thermalPolicy: DiagnosticThermalPolicy(read: { .nominal }),
                                           memoryPressure: { false })
            await runner.run()
            #expect(runner.results.map(\.status) == [status])
            let measurement = try #require(runner.results.first?.cleanup)
            #expect(measurement.succeeded)
            #expect(measurement.milliseconds >= 0)
            let restored = try #require(store.load()?.report)
            #expect(restored.results.first?.cleanup?.milliseconds == measurement.milliseconds)
            #expect(DiagnosticReportExport(report: restored).text.contains("Case cleanup:"))
            let json = try JSONSerialization.jsonObject(with: DiagnosticReportExport(report: restored).jsonData()) as? [String: Any]
            let results = json?["results"] as? [[String: Any]]
            #expect((results?.first?["cleanup"] as? [String: Any])?["succeeded"] as? Bool == true)
            #expect(try FileManager.default.contentsOfDirectory(atPath:
                base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
        }
    }

    @Test @MainActor
    func removalFailureIsReportedAndFinalCleanupRetries() async throws {
        let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let test = DiagnosticTestCase(id: "fixture", title: "Fixture") { directory in
            let file = directory.appending(path: "fixture.pdf")
            try Data([1]).write(to: file)
            DiagnosticCaseCleanup.remove(file, using: { _ in throw CocoaError(.fileWriteNoPermission) })
            return DiagnosticCaseOutcome(status: .passed, duration: .zero, detail: "")
        }
        let runner = DiagnosticsRunner(cases: [test], workspace: DiagnosticWorkspace(baseDirectory: base),
                                       thermalPolicy: DiagnosticThermalPolicy(read: { .nominal }), memoryPressure: { false })
        await runner.run()
        #expect(runner.results.map(\.id) == ["fixture", "fixture.cleanup"])
        #expect(runner.results.map(\.status) == [.passed, .failed])
        #expect(runner.results[0].cleanup?.succeeded == false)
        #expect(try FileManager.default.contentsOfDirectory(atPath:
            base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
    }

    @Test
    func missingFileAndOlderCheckpoint() throws {
        let recorder = DiagnosticCaseCleanup()
        DiagnosticCaseCleanup.$current.withValue(recorder) {
            DiagnosticCaseCleanup.remove(FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        }
        #expect(recorder.result?.succeeded == true)
        let result = DiagnosticTestResult(id: "old", title: "Old", status: .passed, duration: .zero, detail: "")
        let checkpoint = DiagnosticCheckpoint(startedAt: Date(), results: [result], cases: [], finished: true)
        let data = try JSONEncoder().encode(checkpoint)
        let decoded = try JSONDecoder().decode(DiagnosticCheckpoint.self, from: data)
        #expect(decoded.report.results.first?.cleanup == nil)
    }
}

import Foundation
import Testing
@testable import MihirakiPDFUtility

struct DiagnosticLogStoreCheckTests {
    @Test @MainActor
    func independentStoreAndCapacityProfiles() async throws {
        for available: Int64? in [nil, 0, 4_000_000_000] {
            let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: base) }
            let unrelated = base.appending(path: "existing-log.jsonl")
            let sentinel = Data("preserve unrelated log".utf8)
            try sentinel.write(to: unrelated)
            let runner = DiagnosticsRunner(
                cases: [DiagnosticLogStoreTest.testCase(capacity: DiagnosticStorageCapacity { _ in available })],
                workspace: DiagnosticWorkspace(baseDirectory: base),
                thermalPolicy: DiagnosticThermalPolicy(read: { .nominal }), memoryPressure: { false })
            await runner.run()
            #expect(runner.results.map(\.status) == [available == 4_000_000_000 ? .passed : .skipped])
            #expect(runner.results.first?.cleanup?.succeeded == true)
            #expect(try Data(contentsOf: unrelated) == sentinel)
            #expect(try FileManager.default.contentsOfDirectory(atPath:
                base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
        }
    }

    @Test @MainActor
    func interruptionAfterWritingCleansStore() async throws {
        for cancel in [false, true] {
            let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: base) }
            let capacity = DiagnosticStorageCapacity { directory in
                let log = directory.appending(path: "MihirakiPDFUtility/diagnostics.jsonl")
                if FileManager.default.fileExists(atPath: log.path) {
                    if cancel { withUnsafeCurrentTask { $0?.cancel() } }
                    else { return 0 }
                }
                return 4_000_000_000
            }
            let runner = DiagnosticsRunner(cases: [DiagnosticLogStoreTest.testCase(capacity: capacity)],
                workspace: DiagnosticWorkspace(baseDirectory: base),
                thermalPolicy: DiagnosticThermalPolicy(read: { .nominal }), memoryPressure: { false })
            await runner.run()
            #expect(runner.results.map(\.status) == [cancel ? .cancelled : .skipped])
            #expect(runner.results.first?.cleanup?.succeeded == true)
            #expect(try FileManager.default.contentsOfDirectory(atPath:
                base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
        }
    }
}

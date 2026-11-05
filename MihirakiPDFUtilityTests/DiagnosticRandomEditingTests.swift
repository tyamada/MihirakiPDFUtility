import Foundation
import Testing
@testable import MihirakiPDFUtility

struct DiagnosticRandomEditingTests {
    @Test func plansAreDeterministicAndBounded() {
        let first = DiagnosticRandomEditingTest.plan(seed: DiagnosticRandomEditingTest.seed)
        let second = DiagnosticRandomEditingTest.plan(seed: DiagnosticRandomEditingTest.seed)
        #expect(first.map(\.pages) == second.map(\.pages))
        #expect(first.map(\.index) == second.map(\.index))
        #expect(first.map(\.operation) == second.map(\.operation))
        #expect(Set(first.map(\.operation)) == Set(DiagnosticRandomEditingTest.Operation.allCases))
        for seed in UInt64(0)..<100 {
            let steps = DiagnosticRandomEditingTest.plan(seed: seed)
            #expect(steps.count == 64)
            #expect(steps.allSatisfy { (1...24).contains($0.pages.count) && $0.pages.indices.contains($0.selectedIndex) })
        }
    }

    @Test @MainActor
    func multipleSeedsExportAndClean() async throws {
        for seed: UInt64 in [DiagnosticRandomEditingTest.seed, 0, 42, UInt64.max] {
            let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: base) }
            let runner = DiagnosticsRunner(
                cases: [DiagnosticRandomEditingTest.testCase(
                    capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 }, seed: seed)],
                workspace: DiagnosticWorkspace(baseDirectory: base)
            )
            await runner.run()
            #expect(runner.results.map(\.status) == [.passed])
            #expect(runner.results.first?.detail.contains(String(seed)) == true)
            #expect(try FileManager.default.contentsOfDirectory(atPath:
                base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
        }
    }

    @Test @MainActor
    func interruptionBeforeEditingCleansFixture() async throws {
        for cancel in [false, true] {
            let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: base) }
            let capacity = DiagnosticStorageCapacity { directory in
                if FileManager.default.fileExists(atPath: directory.appending(path: "basic-12-rewritten.pdf").path) {
                    if cancel { withUnsafeCurrentTask { $0?.cancel() } }
                    else { return 0 }
                }
                return 4_000_000_000
            }
            let runner = DiagnosticsRunner(
                cases: [DiagnosticRandomEditingTest.testCase(capacity: capacity)],
                workspace: DiagnosticWorkspace(baseDirectory: base)
            )
            await runner.run()
            #expect(runner.results.map(\.status) == [cancel ? .cancelled : .skipped])
            #expect(try FileManager.default.contentsOfDirectory(atPath:
                base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
        }
    }
}

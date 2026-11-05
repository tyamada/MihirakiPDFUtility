import Foundation
import Synchronization
import Testing
@testable import MihirakiPDFUtility

struct DiagnosticComputationTests {
    private enum Stop: Error { case expected }

    @Test
    func calculationLoopsStopAtCheckpoints() throws {
        for cpu in [true, false] {
            var checks = 0
            let check = {
                checks += 1
                if checks == 4 { throw Stop.expected }
            }
            #expect(throws: Stop.self) {
                if cpu { _ = try PerformanceTestRunner.measureCPU(check: check) }
                else { _ = try PerformanceTestRunner.measureMemory(check: check) }
            }
            #expect(checks == 4)
        }
        #expect(try PerformanceTestRunner.measureCPU(check: DiagnosticResourceGuard.check).checksum == 13_606_452_728_900_348_576)
        #expect(try PerformanceTestRunner.measureMemory(check: DiagnosticResourceGuard.check).checksum == 43_253_760)
    }

    @Test
    func detachedWorkInheritsResourceGuard() async {
        let policy = DiagnosticResourceGuard(thermalPolicy: DiagnosticThermalPolicy(read: { .nominal }),
                                             memoryPressure: { true })
        do {
            _ = try await DiagnosticResourceGuard.$current.withValue(policy) {
                try await DiagnosticResourceGuard.measureOffMain {
                    Issue.record("Resource guard must stop detached work before calculation")
                    return PerformanceTestRunner.measureCPU()
                }
            }
            Issue.record("Expected resource stop")
        } catch is DiagnosticResourceStop {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func cancellationReachesDetachedWork() async {
        let started = Mutex(false)
        let task = Task {
            try await DiagnosticResourceGuard.measureOffMain {
                started.withLock { $0 = true }
                let deadline = ContinuousClock.now.advanced(by: .seconds(2))
                while ContinuousClock.now < deadline {
                    try Task.checkCancellation()
                    Thread.sleep(forTimeInterval: 0.001)
                }
                throw Stop.expected
            }
        }
        while !started.withLock({ $0 }) { await Task.yield() }
        task.cancel()
        do {
            _ = try await task.value
            Issue.record("Expected cancellation")
        } catch is CancellationError {
        } catch {
            Issue.record("Cancellation did not reach detached work: \(error)")
        }
    }

    @Test @MainActor
    func expiredCaseStopsAndCleansWorkspace() async throws {
        let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let test = DiagnosticTestCase(id: "timeout", title: "Timeout") { _ in
            Issue.record("An expired case must not start")
            return DiagnosticCaseOutcome(status: .passed, duration: .zero, detail: "")
        }
        let later = DiagnosticTestCase(id: "later", title: "Later", execute: test.execute)
        let runner = DiagnosticsRunner(cases: [test, later], workspace: DiagnosticWorkspace(baseDirectory: base),
                                       thermalPolicy: DiagnosticThermalPolicy(read: { .nominal }),
                                       caseTimeLimit: .zero, memoryPressure: { false })
        await runner.run()
        #expect(runner.results.map(\.status) == [.cancelled, .skipped])
        #expect(runner.results[0].detail == runner.results[1].detail)
        #expect(runner.report?.finalCleanupMilliseconds != nil)
        #expect(try FileManager.default.contentsOfDirectory(atPath:
            base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
    }
}

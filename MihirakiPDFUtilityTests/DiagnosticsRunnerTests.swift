import Foundation
import Testing
@testable import MihirakiPDFUtility

@Suite("Diagnostic runner")
struct DiagnosticsRunnerTests {
    @Test @MainActor
    func builtInChecks() async {
        let cases = DiagnosticTestCase.builtIn.filter { $0.id == "cpu" || $0.id == "memory" }
            + [.pdf(capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 })]
            + DiagnosticEditingCheck.allCases.map {
                $0.testCase(capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 })
            }
        let loadCases = DiagnosticPDFLoadTest.pageCounts.map {
            DiagnosticPDFLoadTest.testCase(pageCount: $0, capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 })
        }
        let runner = DiagnosticsRunner(cases: cases + loadCases + [
            DiagnosticRandomEditingTest.testCase(capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 }),
            DiagnosticImagePDFTest.testCase(capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 }),
            DiagnosticLogStoreTest.testCase(capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 }),
            DiagnosticImageImportTest.testCase(capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 })
        ])
        await runner.run()
        #expect(runner.results.map(\.id) == ["cpu", "memory", "pdf.basic"] + DiagnosticEditingCheck.allCases.map { "pdf.edit.\($0.rawValue)" } + DiagnosticPDFLoadTest.pageCounts.map { "pdf.load.\($0)" } + ["pdf.stress.randomEditing", "pdf.stress.images", "logs.isolatedStore", "images.folderConversion"])
        #expect(runner.report?.count(.passed) == 19)
        #expect(runner.report?.count(.failed) == 0)
        #expect(!runner.isRunning)
        #expect(runner.currentTitle == nil)
    }

    @Test @MainActor
    func failureDoesNotStopFollowingCases() async {
        let trace = DiagnosticTrace()
        let runner = DiagnosticsRunner(cases: [
            DiagnosticTestCase(id: "wrong", title: "Wrong", expectedChecksum: 1) {
                await trace.append("wrong")
                return PerformanceTestMeasurement(id: "wrong", name: "", duration: .zero, detail: "", checksum: 2)
            },
            DiagnosticTestCase(id: "error", title: "Error", expectedChecksum: 1) {
                await trace.append("error")
                throw DiagnosticTestError.expected
            },
            DiagnosticTestCase(id: "ok", title: "OK", expectedChecksum: 1) {
                await trace.append("ok")
                return PerformanceTestMeasurement(id: "ok", name: "", duration: .zero, detail: "", checksum: 1)
            }
        ])
        await runner.run()
        #expect(await trace.values == ["wrong", "error", "ok"])
        #expect(runner.results.map(\.status) == [.failed, .failed, .passed])
        #expect(runner.report?.count(.failed) == 2)
    }

    @Test @MainActor
    func duplicateRunIsIgnoredAndRerunReplacesResults() async {
        let gate = DiagnosticGate()
        let runner = DiagnosticsRunner(cases: [
            DiagnosticTestCase(id: "gate", title: "Gate", expectedChecksum: 1) {
                await gate.wait()
                return PerformanceTestMeasurement(id: "gate", name: "", duration: .zero, detail: "", checksum: 1)
            }
        ])
        let first = Task { await runner.run() }
        while !(await gate.entered) { await Task.yield() }
        #expect(runner.isRunning)
        await runner.run()
        #expect(await gate.count == 1)
        await gate.release()
        await first.value
        await runner.run()
        #expect(await gate.count == 2)
        #expect(runner.results.count == 1)
        #expect(runner.report?.count(.passed) == 1)
    }

    @Test @MainActor
    func cancelledRunDoesNotReportUnexecutedCasesAsPassed() async {
        let gate = DiagnosticGate()
        let runner = DiagnosticsRunner(cases: [
            DiagnosticTestCase(id: "first", title: "First", expectedChecksum: 1) {
                await gate.wait()
                return PerformanceTestMeasurement(id: "first", name: "", duration: .zero, detail: "", checksum: 1)
            },
            DiagnosticTestCase(id: "second", title: "Second", expectedChecksum: 1) {
                Issue.record("A cancelled run must not start the next case")
                throw DiagnosticTestError.expected
            }
        ])
        let task = Task { await runner.run() }
        while !(await gate.entered) { await Task.yield() }
        task.cancel()
        await gate.release()
        await task.value
        #expect(runner.results.map(\.status) == [.cancelled, .notRun])
        #expect(runner.report?.count(.passed) == 0)
        #expect(!runner.isRunning)
    }
}

private enum DiagnosticTestError: Error {
    case expected
}

private actor DiagnosticTrace {
    var values: [String] = []
    func append(_ value: String) { values.append(value) }
}

private actor DiagnosticGate {
    var entered = false
    var count = 0
    private var released = false
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        count += 1
        entered = true
        guard !released else { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func release() {
        released = true
        continuation?.resume()
        continuation = nil
    }
}

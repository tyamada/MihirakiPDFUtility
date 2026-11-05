import Foundation
import Testing
@testable import MihirakiPDFUtility

@MainActor
struct DiagnosticReportStoreTests {
    private func temporaryStore() -> DiagnosticReportStore {
        DiagnosticReportStore(fileURL: FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString).appending(path: "latest.json"))
    }

    private func passingCase(_ id: String) -> DiagnosticTestCase {
        DiagnosticTestCase(id: id, title: "Test", expectedChecksum: 1) {
            PerformanceTestMeasurement(id: id, name: "", duration: .milliseconds(25), detail: "Verified", checksum: 1)
        }
    }

    @Test func completedReportSurvivesNewRunner() async throws {
        let store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        let cases = [passingCase("one")]
        let runner = DiagnosticsRunner(cases: cases, store: store)
        await runner.run()
        let restored = DiagnosticsRunner(cases: cases, store: store)
        #expect(restored.results.map(\.status) == [.passed])
        #expect(restored.results.first?.duration == .milliseconds(25))
        #expect(restored.results.first?.detail == "Verified")
        #expect(!restored.restoredInterruptedRun)
        #expect(!restored.isRunning)
        #expect(!runner.persistenceFailed)
    }

    @Test func checkpointsRetainPartialResultsAndCancelLeavesRestNotRun() async throws {
        let store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        let gate = ReportTestGate()
        let cases = [
            passingCase("one"),
            DiagnosticTestCase(id: "two", title: "Two", expectedChecksum: 1) {
                await gate.wait()
                return PerformanceTestMeasurement(id: "two", name: "", duration: .zero, detail: "", checksum: 1)
            },
            passingCase("three")
        ]
        let runner = DiagnosticsRunner(cases: cases, store: store)
        let task = Task { await runner.run() }
        while !(await gate.entered) { await Task.yield() }
        #expect(runner.completedCount == 1)
        let partial = try #require(try store.load())
        #expect(!partial.finished)
        #expect(partial.report.results.map(\.status) == [.passed, .notRun, .notRun])
        // A new owner simulates the next process after abrupt termination.
        let restored = DiagnosticsRunner(cases: cases, store: store)
        #expect(restored.restoredInterruptedRun)
        #expect(!restored.isRunning)
        #expect(restored.report?.count(.passed) == 1)
        runner.cancel()
        #expect(runner.cancellationRequested)
        await gate.release()
        await task.value
        #expect(runner.results.map(\.status) == [.passed, .cancelled, .notRun])
        #expect(try store.load()?.finished == true)
        #expect(!runner.isRunning)
        // The next run must reset cancellation state and replace the old entries.
        await runner.run()
        #expect(!runner.cancellationRequested)
        #expect(runner.results.map(\.status) == [.passed, .passed, .passed])
    }

    @Test func initialCheckpointExistsBeforeFirstTestFinishes() async throws {
        let store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        let gate = ReportTestGate()
        let runner = DiagnosticsRunner(cases: [
            DiagnosticTestCase(id: "first", title: "First", expectedChecksum: 1) {
                await gate.wait()
                return PerformanceTestMeasurement(id: "first", name: "", duration: .zero, detail: "", checksum: 1)
            }
        ], store: store)
        let task = Task { await runner.run() }
        while !(await gate.entered) { await Task.yield() }
        #expect(try store.load()?.report.wasInterrupted == true)
        #expect(try store.load()?.report.count(.notRun) == 1)
        runner.cancel()
        await gate.release()
        await task.value
    }

    @Test func corruptCheckpointIsVisibleAndNextRunRepairsIt() async throws {
        let store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try Data("invalid JSON".utf8).write(to: store.fileURL)
        let runner = DiagnosticsRunner(cases: [passingCase("one")], store: store)
        #expect(runner.persistenceFailed)
        #expect(runner.report == nil)
        await runner.run()
        #expect(!runner.persistenceFailed)
        #expect(try store.load()?.report.count(.passed) == 1)
    }

    @Test func writeFailureKeepsResultsInMemory() async throws {
        let store = temporaryStore()
        let parent = store.fileURL.deletingLastPathComponent()
        defer { try? FileManager.default.removeItem(at: parent) }
        // A file where the report directory belongs forces a deterministic write error.
        try Data("blocked".utf8).write(to: parent)
        let runner = DiagnosticsRunner(cases: [passingCase("one")], store: store)
        await runner.run()
        #expect(runner.persistenceFailed)
        #expect(runner.report?.count(.passed) == 1)
        #expect(!runner.isRunning)
    }
}

private actor ReportTestGate {
    var entered = false
    private var released = false
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
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

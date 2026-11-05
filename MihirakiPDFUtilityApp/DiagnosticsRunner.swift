import Foundation
import Observation

enum DiagnosticTestStatus: String, Codable, Sendable {
    case passed, failed, skipped, cancelled, notRun

    var title: LocalizedStringResource {
        switch self {
        case .passed: "Passed"
        case .failed: "Failed"
        case .skipped: "Skipped"
        case .cancelled: "Cancelled"
        case .notRun: "Not Run"
        }
    }
}

struct DiagnosticTestResult: Identifiable, Sendable {
    let id: String
    let title: LocalizedStringResource
    let status: DiagnosticTestStatus
    let duration: Duration
    let detail: String
    var cleanup: DiagnosticCleanupMeasurement? = nil
}

struct DiagnosticTestReport: Sendable {
    let startedAt: Date
    let finishedAt: Date
    let results: [DiagnosticTestResult]
    var wasInterrupted = false
    var environment: DiagnosticRunEnvironment? = nil
    var finalCleanupMilliseconds: Double? = nil

    func count(_ status: DiagnosticTestStatus) -> Int {
        results.filter { $0.status == status }.count
    }
}

struct DiagnosticTestCase: Identifiable, Sendable {
    let id: String
    let title: LocalizedStringResource
    let execute: @Sendable (URL) async throws -> DiagnosticCaseOutcome

    init(
        id: String, title: LocalizedStringResource, expectedChecksum: UInt64,
        measure: @escaping @Sendable () async throws -> PerformanceTestMeasurement
    ) {
        self.id = id
        self.title = title
        self.execute = { _ in
            let measurement = try await measure()
            let passed = measurement.checksum == expectedChecksum
            return DiagnosticCaseOutcome(
                status: passed ? .passed : .failed, duration: measurement.duration,
                detail: passed ? measurement.detail
                    : String(localized: "The calculated checksum did not match the expected value.")
            )
        }
    }

    init(
        id: String, title: LocalizedStringResource,
        execute: @escaping @Sendable (URL) async throws -> DiagnosticCaseOutcome
    ) {
        self.id = id
        self.title = title
        self.execute = execute
    }

    static func pdf(capacity: DiagnosticStorageCapacity = .live) -> Self {
        Self(id: "pdf.basic", title: "PDF Generation and Reopening") { directory in
            let start = ContinuousClock.now
            defer {
                DiagnosticCaseCleanup.remove(directory.appending(path: "basic-12.pdf"))
                DiagnosticCaseCleanup.remove(directory.appending(path: "basic-12-rewritten.pdf"))
            }
            let detail = try await DiagnosticPDFTest(capacity: capacity).run(in: directory)
            return DiagnosticCaseOutcome(status: .passed, duration: start.duration(to: .now), detail: detail)
        }
    }

    static let builtIn: [Self] = [
        Self(id: "cpu", title: "CPU Calculation", expectedChecksum: 13_606_452_728_900_348_576) {
            try await DiagnosticResourceGuard.measureOffMain {
                try PerformanceTestRunner.measureCPU(check: DiagnosticResourceGuard.check)
            }
        },
        Self(id: "memory", title: "Memory Processing", expectedChecksum: 43_253_760) {
            try await DiagnosticResourceGuard.measureOffMain {
                try PerformanceTestRunner.measureMemory(check: DiagnosticResourceGuard.check)
            }
        },
        .pdf()
    ] + DiagnosticEditingCheck.allCases.map { $0.testCase() }
        + DiagnosticPDFLoadTest.pageCounts.map { DiagnosticPDFLoadTest.testCase(pageCount: $0) }
        + [DiagnosticRandomEditingTest.testCase(), DiagnosticImagePDFTest.testCase(), DiagnosticLogStoreTest.testCase(), DiagnosticImageImportTest.testCase()]
}

struct DiagnosticCaseOutcome: Sendable {
    let status: DiagnosticTestStatus
    let duration: Duration
    let detail: String
}

@MainActor
@Observable
final class DiagnosticsRunner {
    private(set) var isRunning = false
    private(set) var results: [DiagnosticTestResult] = []
    private(set) var report: DiagnosticTestReport?
    private(set) var currentTitle: LocalizedStringResource?
    let cases: [DiagnosticTestCase]
    private let caseTimeLimit: Duration
    private let thermalPolicy: DiagnosticThermalPolicy
    private let memoryPressure: @Sendable () -> Bool
    private var finalCleanupMilliseconds: Double?
    private let workspace: DiagnosticWorkspace
    private let store: DiagnosticReportStore?
    private var runEnvironment: DiagnosticRunEnvironment?
    private var activeTask: Task<Void, Never>?
    private(set) var cancellationRequested = false
    private(set) var startedAt: Date?
    private(set) var persistenceFailed = false
    private(set) var restoredInterruptedRun = false

    var completedCount: Int {
        results.filter { result in cases.contains { $0.id == result.id } }.count
    }

    func clearReport() {
        guard !isRunning else { return }
        do {
            try store?.delete()
            report = nil
            results = []
            restoredInterruptedRun = false
            persistenceFailed = false
        } catch {
            persistenceFailed = true
        }
    }

    func cancel() {
        guard isRunning else { return }
        cancellationRequested = true
        activeTask?.cancel()
    }

    init(
        cases: [DiagnosticTestCase] = DiagnosticTestCase.builtIn,
        workspace: DiagnosticWorkspace = .shared,
        store: DiagnosticReportStore? = nil,
        thermalPolicy: DiagnosticThermalPolicy = DiagnosticThermalPolicy(),
        caseTimeLimit: Duration = .seconds(120),
        memoryPressure: @escaping @Sendable () -> Bool = { DiagnosticMemoryPressure.shared.isPressured }
    ) {
        self.caseTimeLimit = caseTimeLimit
        self.thermalPolicy = thermalPolicy
        self.memoryPressure = memoryPressure
        self.cases = cases
        self.workspace = workspace
        self.store = store
        do {
            if let checkpoint = try store?.load() {
                report = checkpoint.report
                results = checkpoint.report.results
                restoredInterruptedRun = checkpoint.report.wasInterrupted
            }
        } catch {
            persistenceFailed = true
        }
    }

    func run() async {
        guard !isRunning else { return }
        isRunning = true
        cancellationRequested = false
        restoredInterruptedRun = false
        persistenceFailed = false
        results = []
        report = nil
        finalCleanupMilliseconds = nil
        startedAt = Date()
        runEnvironment = .current
        let task = Task { await self.executeRun() }
        activeTask = task
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
        activeTask = nil
        currentTitle = nil
        isRunning = false
    }

    private func saveCheckpoint(finished: Bool) {
        guard let startedAt, let store else { return }
        do {
            try store.save(DiagnosticCheckpoint(
                startedAt: startedAt, results: results, cases: cases, finished: finished,
                environment: runEnvironment, finalCleanupMilliseconds: finalCleanupMilliseconds
            ))
        } catch {
            persistenceFailed = true
        }
    }

    private func executeRun() async {
        guard let startedAt else { return }
        saveCheckpoint(finished: false)

        let runID: UUID
        do {
            runID = try await workspace.begin()
        } catch {
            results = cases.map {
                DiagnosticTestResult(id: $0.id, title: $0.title, status: .notRun,
                                     duration: .zero, detail: String(localized: "The test workspace could not be prepared."))
            }
            results.append(DiagnosticTestResult(
                id: "workspace.prepare", title: "Test Workspace", status: .failed,
                duration: .zero, detail: String(localized: "The test workspace could not be prepared.")
            ))
            report = DiagnosticTestReport(startedAt: startedAt, finishedAt: Date(), results: results, environment: runEnvironment)
            saveCheckpoint(finished: true)
            return
        }

        let directory = await workspace.directory(for: runID)
        let resourceGuard = DiagnosticResourceGuard(thermalPolicy: thermalPolicy, memoryPressure: memoryPressure)
        var resourceStopReason: String?
        for test in cases {
            defer { saveCheckpoint(finished: false) }
            if Task.isCancelled {
                results.append(DiagnosticTestResult(
                    id: test.id, title: test.title, status: .notRun,
                    duration: .zero, detail: String(localized: "Not run because the test run was cancelled.")
                ))
                continue
            }
            if let reason = resourceStopReason ?? resourceGuard.reason() {
                resourceStopReason = reason
                results.append(DiagnosticTestResult(id: test.id, title: test.title, status: .skipped,
                                                    duration: .zero, detail: reason))
                continue
            }
            currentTitle = test.title
            let clock = ContinuousClock()
            let start = clock.now
            let cleanup = DiagnosticCaseCleanup()
            do {
                var caseGuard = resourceGuard
                caseGuard.deadline = start.advanced(by: caseTimeLimit)
                let outcome = try await DiagnosticResourceGuard.$current.withValue(caseGuard) {
                    try DiagnosticResourceGuard.check()
                    let value = try await DiagnosticCaseCleanup.$current.withValue(cleanup) {
                        try await test.execute(directory)
                    }
                    try DiagnosticResourceGuard.check()
                    return value
                }
                try Task.checkCancellation()
                results.append(DiagnosticTestResult(
                    id: test.id, title: test.title, status: outcome.status,
                    duration: outcome.duration, detail: outcome.detail
                ))
            } catch let stop as DiagnosticResourceStop {
                resourceStopReason = stop.detail
                results.append(DiagnosticTestResult(id: test.id, title: test.title, status: .cancelled,
                                                    duration: start.duration(to: clock.now), detail: stop.detail))
            } catch let skip as any DiagnosticSkipReason {
                results.append(DiagnosticTestResult(
                    id: test.id, title: test.title, status: .skipped,
                    duration: start.duration(to: clock.now), detail: skip.detail
                ))
            } catch {
                results.append(DiagnosticTestResult(
                    id: test.id, title: test.title,
                    status: error is CancellationError ? .cancelled : .failed,
                    duration: start.duration(to: clock.now),
                    detail: error is CancellationError
                        ? String(localized: "The test was cancelled.")
                        : String(localized: "The test could not be completed.")
                ))
            }
            if let measurement = cleanup.result {
                results[results.count - 1].cleanup = measurement
                if !measurement.succeeded {
                    results.append(DiagnosticTestResult(
                        id: test.id + ".cleanup", title: "Test Data Cleanup", status: .failed,
                        duration: .zero, detail: String(localized: "Case test data could not be deleted. Final workspace cleanup will retry."),
                        cleanup: measurement))
                }
            }
        }
        let cleanupStart = ContinuousClock.now
        do {
            try await workspace.finish(runID)
        } catch {
            results.append(DiagnosticTestResult(
                id: "workspace.cleanup", title: "Test Data Cleanup", status: .failed,
                duration: .zero, detail: String(localized: "Test data could not be deleted. Cleanup will be retried next time.")
            ))
        }
        let cleanupDuration = cleanupStart.duration(to: .now)
        finalCleanupMilliseconds = Double(cleanupDuration.components.seconds) * 1_000
            + Double(cleanupDuration.components.attoseconds) / 1_000_000_000_000_000
        report = DiagnosticTestReport(startedAt: startedAt, finishedAt: Date(), results: results,
                                      environment: runEnvironment, finalCleanupMilliseconds: finalCleanupMilliseconds)
        saveCheckpoint(finished: true)
    }
}

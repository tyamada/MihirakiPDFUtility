import Foundation

/// One local checkpoint, separate from disposable generated PDFs.
/// Titles/details preserve the language used when the run was recorded.
struct DiagnosticCheckpoint: Codable {
    struct Entry: Codable {
        let id: String
        let title: String
        let status: DiagnosticTestStatus
        let seconds: Int64
        let attoseconds: Int64
        let detail: String
        let cleanup: DiagnosticCleanupMeasurement?

        init(_ result: DiagnosticTestResult) {
            id = result.id
            title = String(localized: result.title)
            status = result.status
            seconds = result.duration.components.seconds
            attoseconds = result.duration.components.attoseconds
            detail = result.detail
            cleanup = result.cleanup
        }

        var result: DiagnosticTestResult {
            DiagnosticTestResult(
                id: id, title: LocalizedStringResource(stringLiteral: title),
                status: status, duration: Duration(secondsComponent: seconds, attosecondsComponent: attoseconds),
                detail: detail, cleanup: cleanup
            )
        }
    }

    let version: Int
    let startedAt: Date
    let updatedAt: Date
    let finished: Bool
    let interrupted: Bool
    let entries: [Entry]
    let environment: DiagnosticRunEnvironment?
    let finalCleanupMilliseconds: Double?

    init(startedAt: Date, results: [DiagnosticTestResult], cases: [DiagnosticTestCase],
         finished: Bool, interrupted: Bool = false, environment: DiagnosticRunEnvironment? = nil, finalCleanupMilliseconds: Double? = nil) {
        self.finalCleanupMilliseconds = finalCleanupMilliseconds
        self.environment = environment
        version = 1
        self.startedAt = startedAt
        updatedAt = Date()
        self.finished = finished
        self.interrupted = interrupted
        let completed = Set(results.map(\.id))
        entries = results.map(Entry.init) + cases.filter { !completed.contains($0.id) }.map {
            Entry(DiagnosticTestResult(
                id: $0.id, title: $0.title, status: .notRun, duration: .zero,
                detail: String(localized: "No completed result was saved before the diagnostic run was interrupted.")
            ))
        }
    }

    var report: DiagnosticTestReport {
        DiagnosticTestReport(startedAt: startedAt, finishedAt: updatedAt,
                             results: entries.map(\.result), wasInterrupted: interrupted || !finished, environment: environment, finalCleanupMilliseconds: finalCleanupMilliseconds)
    }
}

struct DiagnosticReportStore {
    let fileURL: URL

    static var live: Self {
        Self(fileURL: URL.applicationSupportDirectory
            .appending(path: "DiagnosticReports", directoryHint: .isDirectory)
            .appending(path: "latest.json"))
    }

    func save(_ checkpoint: DiagnosticCheckpoint) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var excludedDirectory = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try excludedDirectory.setResourceValues(values)
        try JSONEncoder().encode(checkpoint).write(to: fileURL, options: .atomic)
    }

    func delete() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }

    func load() throws -> DiagnosticCheckpoint? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        // A corrupt or unexpected file must not cause an unbounded allocation.
        let size = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size > 0, size <= 1_048_576 else { throw CocoaError(.fileReadCorruptFile) }
        let checkpoint = try JSONDecoder().decode(DiagnosticCheckpoint.self, from: Data(contentsOf: fileURL))
        guard checkpoint.version == 1 else { throw CocoaError(.fileReadCorruptFile) }
        return checkpoint
    }
}

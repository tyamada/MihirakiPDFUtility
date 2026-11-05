import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct DiagnosticRunEnvironment: Codable, Sendable {
    let appVersion: String
    let build: String
    let operatingSystem: String
    let platform: String
    let simulator: Bool
    let testDefinitionVersion: Int

    static var current: Self {
        let version = AppVersionInfo()
#if os(macOS)
        let platform = "macOS"
#else
        let platform = "iOS/iPadOS"
#endif
#if targetEnvironment(simulator)
        let simulator = true
#else
        let simulator = false
#endif
        return Self(appVersion: version.versionNumber, build: version.buildNumber,
                    operatingSystem: ProcessInfo.processInfo.operatingSystemVersionString,
                    platform: platform, simulator: simulator, testDefinitionVersion: 14)
    }
}

/// A value snapshot: sharing never reads the generated PDF workspace.
struct DiagnosticReportExport: Codable, Sendable {
    struct Result: Codable, Sendable {
        let id: String
        let title: String
        let status: DiagnosticTestStatus
        let milliseconds: Double
        let detail: String
        let cleanup: DiagnosticCleanupMeasurement?
    }

    let schemaVersion: Int
    let purpose: String
    let startedAt: Date
    let lastRecordedAt: Date
    let interrupted: Bool
    let environment: DiagnosticRunEnvironment?
    let finalCleanupMilliseconds: Double?
    let results: [Result]

    init(report: DiagnosticTestReport) {
        schemaVersion = 1
        purpose = "Optional diagnostic bug report for investigating or responding to app problems."
        startedAt = report.startedAt
        lastRecordedAt = report.finishedAt
        interrupted = report.wasInterrupted
        environment = report.environment
        finalCleanupMilliseconds = report.finalCleanupMilliseconds
        results = report.results.map {
            Result(id: $0.id, title: String(localized: $0.title), status: $0.status,
                   milliseconds: Double($0.duration.components.seconds) * 1_000
                    + Double($0.duration.components.attoseconds) / 1_000_000_000_000_000,
                   detail: $0.detail, cleanup: $0.cleanup)
        }
    }

    func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    var text: String {
        var lines = ["Mihiraki PDF Utility — Diagnostic Bug Report", purpose,
                     "Started: \(startedAt.ISO8601Format())",
                     "Last recorded: \(lastRecordedAt.ISO8601Format())",
                     "Interrupted: \(interrupted)"]
        if let environment {
            lines += ["App: \(environment.appVersion) (\(environment.build))",
                      "OS: \(environment.operatingSystem)", "Platform: \(environment.platform)",
                      "Simulator: \(environment.simulator)", "Test definition: \(environment.testDefinitionVersion)"]
        } else {
            lines.append("Run environment: unavailable (older saved report)")
        }
        if let finalCleanupMilliseconds {
            lines.append("Final workspace cleanup: \(finalCleanupMilliseconds.formatted(.number.precision(.fractionLength(3)))) ms (excludes per-case cleanup)")
        }
        for status in [DiagnosticTestStatus.passed, .failed, .skipped, .cancelled, .notRun] {
            lines.append("\(status.rawValue): \(results.filter { $0.status == status }.count)")
        }
        for result in results {
            lines += ["", "[\(result.status.rawValue)] \(result.title) (\(result.id))",
                      "\(result.milliseconds) ms", result.detail]
            if let cleanup = result.cleanup {
                lines.append("Case cleanup: \(cleanup.milliseconds.formatted(.number.precision(.fractionLength(3)))) ms; succeeded: \(cleanup.succeeded)")
            }
        }
        return lines.joined(separator: "\n")
    }
}

struct DiagnosticTextTransfer: Transferable {
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .utf8PlainText) { $0.data }
            .suggestedFileName("diagnostic-report.txt")
    }
}

struct DiagnosticJSONTransfer: Transferable {
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { $0.data }
            .suggestedFileName("diagnostic-report.json")
    }
}

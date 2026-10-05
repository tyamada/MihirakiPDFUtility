import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum DiagnosticLogCategory: String, Codable, Sendable {
    case lifecycle
    case document
    case editing
    case performance
}

enum DiagnosticLogEvent: String, Codable, Sendable {
    case appLaunched
    case appBecameActive
    case appEnteredBackground
    case previousSessionEndedUnexpectedly
    case documentOpened
    case documentOpenFailed
    case documentNeedsPassword
    case documentAppended
    case documentAppendFailed
    case documentExported
    case documentExportFailed
    case pagesRotated
    case pagesDuplicated
    case pagesInserted
    case pagesDeleted
    case pagesMoved
    case undo
    case redo
    case metadataUpdated
    case viewerPreferencesUpdated
    case passwordProtectionUpdated
    case performanceTestCompleted
}

enum DiagnosticLogOutcome: String, Codable, Sendable {
    case info
    case success
    case failure
    case warning
}

struct DiagnosticLogRecord: Codable, Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let category: DiagnosticLogCategory
    let event: DiagnosticLogEvent
    let outcome: DiagnosticLogOutcome
    let durationMilliseconds: Int64?
    let pageCount: Int?
    let selectionCount: Int?

    var formattedLine: String {
        var components = [
            timestamp.formatted(.iso8601),
            "[\(category.rawValue)]",
            event.rawValue,
            "outcome=\(outcome.rawValue)"
        ]
        if let durationMilliseconds {
            components.append("duration_ms=\(durationMilliseconds)")
        }
        if let pageCount {
            components.append("pages=\(pageCount)")
        }
        if let selectionCount {
            components.append("selection=\(selectionCount)")
        }
        return components.joined(separator: " ")
    }
}

actor DiagnosticLogStore {
    static let shared = DiagnosticLogStore()

    static let retentionInterval: TimeInterval = 14 * 24 * 60 * 60

    private let fileManager: FileManager
    private let directoryURL: URL
    private let logFileURL: URL
    private let sessionMarkerURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var lastPruneDate: Date?

    init(baseDirectory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let root = baseDirectory
            ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        directoryURL = root.appending(path: "MihirakiPDFUtility", directoryHint: .isDirectory)
        logFileURL = directoryURL.appending(path: "diagnostics.jsonl")
        sessionMarkerURL = directoryURL.appending(path: "active-session")
    }

    func startSession(now: Date = Date()) {
        prepareDirectory()
        pruneExpiredRecords(now: now)

        if fileManager.fileExists(atPath: sessionMarkerURL.path) {
            append(
                event: .previousSessionEndedUnexpectedly,
                category: .lifecycle,
                outcome: .warning,
                timestamp: now
            )
        }

        try? Data().write(to: sessionMarkerURL, options: .atomic)
        append(event: .appLaunched, category: .lifecycle, outcome: .info, timestamp: now)
    }

    func handleScenePhase(_ phase: ScenePhase, now: Date = Date()) {
        switch phase {
        case .active:
            prepareDirectory()
            try? Data().write(to: sessionMarkerURL, options: .atomic)
            append(event: .appBecameActive, category: .lifecycle, outcome: .info, timestamp: now)
        case .background:
            append(event: .appEnteredBackground, category: .lifecycle, outcome: .info, timestamp: now)
            try? fileManager.removeItem(at: sessionMarkerURL)
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func record(
        _ event: DiagnosticLogEvent,
        category: DiagnosticLogCategory,
        outcome: DiagnosticLogOutcome = .success,
        duration: Duration? = nil,
        pageCount: Int? = nil,
        selectionCount: Int? = nil,
        now: Date = Date()
    ) {
        prepareDirectory()
        pruneIfNeeded(now: now)
        append(
            event: event,
            category: category,
            outcome: outcome,
            duration: duration,
            pageCount: pageCount,
            selectionCount: selectionCount,
            timestamp: now
        )
    }

    func records(now: Date = Date()) -> [DiagnosticLogRecord] {
        prepareDirectory()
        pruneExpiredRecords(now: now)
        return readRecords().sorted { $0.timestamp < $1.timestamp }
    }

    func exportedText(now: Date = Date()) -> String {
        let currentRecords = records(now: now)
        let header = [
            "Mihiraki PDF Utility Diagnostic Log",
            "Generated: \(now.formatted(.iso8601))",
            "Retention: 14 days",
            "Privacy: Logs contain no file names, file contents, document metadata, or passwords.",
            "Privacy: Logs remain on this device and are not sent externally.",
            ""
        ]
        return (header + currentRecords.map(\.formattedLine)).joined(separator: "\n")
    }

    private func append(
        event: DiagnosticLogEvent,
        category: DiagnosticLogCategory,
        outcome: DiagnosticLogOutcome,
        duration: Duration? = nil,
        pageCount: Int? = nil,
        selectionCount: Int? = nil,
        timestamp: Date
    ) {
        let record = DiagnosticLogRecord(
            id: UUID(),
            timestamp: timestamp,
            category: category,
            event: event,
            outcome: outcome,
            durationMilliseconds: duration.map(Self.milliseconds),
            pageCount: pageCount,
            selectionCount: selectionCount
        )

        guard var data = try? encoder.encode(record) else { return }
        data.append(0x0A)

        if !fileManager.fileExists(atPath: logFileURL.path) {
            try? data.write(to: logFileURL, options: .atomic)
            return
        }

        guard let handle = try? FileHandle(forWritingTo: logFileURL) else { return }
        defer { try? handle.close() }
        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } catch {
            return
        }
    }

    private func readRecords() -> [DiagnosticLogRecord] {
        guard let data = try? Data(contentsOf: logFileURL),
              let contents = String(data: data, encoding: .utf8) else {
            return []
        }

        return contents.split(whereSeparator: \.isNewline).compactMap { line in
            guard let data = String(line).data(using: .utf8) else { return nil }
            return try? decoder.decode(DiagnosticLogRecord.self, from: data)
        }
    }

    private func pruneIfNeeded(now: Date) {
        guard lastPruneDate.map({ now.timeIntervalSince($0) >= 60 * 60 }) ?? true else {
            return
        }
        pruneExpiredRecords(now: now)
    }

    private func pruneExpiredRecords(now: Date) {
        let cutoff = now.addingTimeInterval(-Self.retentionInterval)
        let retainedRecords = readRecords().filter { $0.timestamp >= cutoff }
        lastPruneDate = now

        guard !retainedRecords.isEmpty else {
            try? fileManager.removeItem(at: logFileURL)
            return
        }

        var data = Data()
        for record in retainedRecords {
            guard var encoded = try? encoder.encode(record) else { continue }
            encoded.append(0x0A)
            data.append(encoded)
        }
        try? data.write(to: logFileURL, options: .atomic)
    }

    private func prepareDirectory() {
        try? fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    private static func milliseconds(_ duration: Duration) -> Int64 {
        duration.components.seconds * 1_000
            + duration.components.attoseconds / 1_000_000_000_000_000
    }
}

struct DiagnosticLogView: View {
    @State private var records: [DiagnosticLogRecord] = []
    @State private var exportText = ""
    @State private var didCopy = false

    var body: some View {
        List {
            Section {
                Label(
                    "Logs stay on this device. This app has no feature that sends logs externally.",
                    systemImage: "hand.raised"
                )
                .foregroundStyle(.secondary)

                Text("Logs do not include file names, file contents, document metadata, or passwords. Records older than 14 days are deleted automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Actions") {
                Button {
                    copyLogs()
                } label: {
                    Label(
                        didCopy ? "Copied" : "Copy Logs",
                        systemImage: didCopy ? "checkmark" : "doc.on.doc"
                    )
                }
                .disabled(exportText.isEmpty)

                Button("Refresh", systemImage: "arrow.clockwise") {
                    Task { await loadLogs() }
                }
            }

            Section("Logs") {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No Logs",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Diagnostic events will appear here as you use the app.")
                    )
                } else {
                    ForEach(records.reversed()) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.event.rawValue)
                                .font(.body.weight(.medium))
                            Text(record.formattedLine)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .navigationTitle("Diagnostic Logs")
        .task {
            await loadLogs()
        }
    }

    private func loadLogs() async {
        records = await DiagnosticLogStore.shared.records()
        exportText = await DiagnosticLogStore.shared.exportedText()
        didCopy = false
    }

    private func copyLogs() {
#if canImport(UIKit)
        UIPasteboard.general.string = exportText
#elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(exportText, forType: .string)
#endif
        didCopy = true
    }
}

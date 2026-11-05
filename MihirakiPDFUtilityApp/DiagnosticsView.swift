import SwiftUI

struct DiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DiagnosticsRunner.self) private var runner

    var body: some View {
        NavigationStack {
            Form {
                Section("Tests") {
                    Text("This test suite includes CPU, memory, page editing and PDF load checks up to 1,100 pages. Available storage determines which sizes run. Temporary PDFs are deleted after testing.")
                    Button("Run All Tests") {
                        Task { await runner.run() }
                    }
                    .disabled(runner.isRunning)

                    if runner.isRunning {
                        ProgressView(value: Double(runner.completedCount), total: Double(max(1, runner.cases.count))) {
                            if let title = runner.currentTitle {
                                Text(title)
                            }
                        }
                        Text("Completed: \(runner.completedCount) / \(runner.cases.count)")
                        if let startedAt = runner.startedAt {
                            TimelineView(.periodic(from: startedAt, by: 1)) { context in
                                Text("Elapsed: \(Int(max(0, context.date.timeIntervalSince(startedAt)))) s")
                                    .monospacedDigit()
                            }
                        }
                        Button("Cancel Tests", role: .cancel) { runner.cancel() }
                            .disabled(runner.cancellationRequested)
                        if runner.cancellationRequested {
                            Text("Stopping tests and deleting temporary files…")
                        }
                    }
                    if runner.restoredInterruptedRun {
                        Text("The previous diagnostic run was interrupted. Saved results are shown below; unfinished tests were not resumed.")
                    }
                    if runner.persistenceFailed {
                        Text("Diagnostic results could not be saved or restored. Results from this session remain available while the app is open.")
                    }
                }

                if runner.isRunning {
                    Section("Test Progress") {
                        ForEach(runner.cases) { test in
                            VStack(alignment: .leading) {
                                Text(test.title)
                                if let result = runner.results.first(where: { $0.id == test.id }) {
                                    Text(result.status.title)
                                } else {
                                    Text("Pending")
                                }
                            }
                        }
                    }
                }

                if let report = runner.report {
                    Section("Results") {
                        NavigationLink("Review and Share Report") {
                            DiagnosticReportShareView(report: report)
                        }
                        Button("Delete Saved Report", role: .destructive) {
                            runner.clearReport()
                        }
                        Text("Passed: \(report.count(.passed))")
                        Text("Failed: \(report.count(.failed))")
                        Text("Skipped: \(report.count(.skipped))")
                        Text("Cancelled: \(report.count(.cancelled))")
                        Text("Not Run: \(report.count(.notRun))")
                        ForEach(report.results) { result in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.title).font(.headline)
                                Text(result.status.title)
                                Text("\(Int64(result.duration.components.seconds * 1_000 + result.duration.components.attoseconds / 1_000_000_000_000_000)) ms")
                                    .monospacedDigit()
                                Text(result.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Diagnostics") {
                    NavigationLink {
                        DiagnosticLogView()
                    } label: {
                        Label("View Diagnostic Logs", systemImage: "doc.text.magnifyingglass")
                    }

                    NavigationLink {
                        PerformanceTestView()
                    } label: {
                        Label("Run Performance Test", systemImage: "gauge.with.dots.needle.50percent")
                    }
                    .disabled(runner.isRunning)
                }
            }
            .interactiveDismissDisabled(runner.isRunning)
            .navigationTitle("Diagnostics")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .disabled(runner.isRunning)
                }
            }
        }
    }
}

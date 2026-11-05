import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct DiagnosticReportShareView: View {
    let report: DiagnosticTestReport
    @State private var jsonSelected = false
    @State private var copied = false

    var body: some View {
        let export = DiagnosticReportExport(report: report)
        let json = try? export.jsonData()
        let preview = jsonSelected ? json.flatMap { String(data: $0, encoding: .utf8) } : export.text
        Form {
            Section("Before Sharing") {
                Text("Share this optional bug report only to investigate or respond to an app problem. Nothing is sent automatically.")
                Text("This report includes test results and may include storage-related skip reasons. Review the complete report below before choosing a recipient.")
                    .font(.headline)
                Text("User documents, passwords, file paths and personal device names are not included.")
            }
            Section("Format") {
                Toggle("JSON", isOn: $jsonSelected)
                    .onChange(of: jsonSelected) { _, _ in copied = false }
                if let preview {
                    if jsonSelected, let json {
                        ShareLink(item: DiagnosticJSONTransfer(data: json),
                                  preview: SharePreview("Diagnostic Bug Report", image: Image(systemName: "doc.text"))) {
                            Label("Share JSON Report", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        ShareLink(item: DiagnosticTextTransfer(data: Data(preview.utf8)),
                                  preview: SharePreview("Diagnostic Bug Report", image: Image(systemName: "doc.text"))) {
                            Label("Share Text Report", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button("Copy Report") {
#if canImport(UIKit)
                        UIPasteboard.general.string = preview
#elseif canImport(AppKit)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(preview, forType: .string)
#endif
                        copied = true
                    }
                    if copied { Text("Copied") }
                } else {
                    Text("The report could not be prepared for sharing.")
                }
            }
            if let preview {
                Section("Report Preview") {
                    Text(verbatim: preview)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Share Diagnostic Report")
    }
}

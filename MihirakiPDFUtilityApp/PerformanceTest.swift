import CoreGraphics
import Foundation
import PDFKit
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct PerformanceTestMeasurement: Identifiable, Sendable {
    let id: String
    let name: String
    let duration: Duration
    let detail: String

    var formattedDuration: String {
        let milliseconds = duration.components.seconds * 1_000
            + duration.components.attoseconds / 1_000_000_000_000_000
        return "\(milliseconds) ms"
    }
}

struct PerformanceTestReport: Sendable {
    let date: Date
    let deviceName: String
    let operatingSystem: String
    let processorCount: Int
    let physicalMemory: UInt64
    let measurements: [PerformanceTestMeasurement]

    var text: String {
        var lines = [
            "Mihiraki PDF Utility Performance Test",
            "Test Date: \(date.formatted(.iso8601))",
            "Device: \(deviceName)",
            "OS: \(operatingSystem)",
            "Processors: \(processorCount)",
            "Physical Memory: \(ByteCountFormatter.string(fromByteCount: Int64(physicalMemory), countStyle: .memory))",
            ""
        ]

        for measurement in measurements {
            lines.append("\(measurement.name): \(measurement.formattedDuration)")
            lines.append("  \(measurement.detail)")
        }

        lines.append("")
        lines.append("Privacy: Test results remain on this device and are not sent externally.")
        return lines.joined(separator: "\n")
    }
}

enum PerformanceTestRunner {
    @MainActor
    static func run() async -> PerformanceTestReport {
        let device = currentDeviceInformation()

        let measurements = await Task.detached(priority: .userInitiated) {
            [
                measureCPU(),
                measureMemory(),
                measurePDFWorkflow()
            ]
        }.value

        return PerformanceTestReport(
            date: Date(),
            deviceName: device.name,
            operatingSystem: device.operatingSystem,
            processorCount: ProcessInfo.processInfo.processorCount,
            physicalMemory: ProcessInfo.processInfo.physicalMemory,
            measurements: measurements
        )
    }

    private static func measureCPU() -> PerformanceTestMeasurement {
        let clock = ContinuousClock()
        var checksum: UInt64 = 0

        let duration = clock.measure {
            for value in UInt64(0)..<5_000_000 {
                checksum = checksum &* 1_664_525 &+ value &+ 1_013_904_223
            }
        }

        return PerformanceTestMeasurement(
            id: "cpu",
            name: String(localized: "CPU Calculation"),
            duration: duration,
            detail: String(localized: "5,000,000 integer operations (checksum: \(checksum))")
        )
    }

    private static func measureMemory() -> PerformanceTestMeasurement {
        let clock = ContinuousClock()
        var checksum: UInt64 = 0
        let byteCount = 16 * 1_024 * 1_024

        let duration = clock.measure {
            let data = Data(repeating: 0xA5, count: byteCount)
            checksum = data.withUnsafeBytes { bytes in
                var value: UInt64 = 0
                for index in stride(from: 0, to: bytes.count, by: 64) {
                    value &+= UInt64(bytes[index])
                }
                return value
            }
        }

        return PerformanceTestMeasurement(
            id: "memory",
            name: String(localized: "Memory Processing"),
            duration: duration,
            detail: String(localized: "Created and scanned 16 MB of data (checksum: \(checksum))")
        )
    }

    private static func measurePDFWorkflow() -> PerformanceTestMeasurement {
        let clock = ContinuousClock()
        let pageCount = 100
        var outputSize = 0
        var loadedPageCount = 0

        let duration = clock.measure {
            autoreleasepool {
                guard let sourceData = makePDF(pageCount: pageCount),
                      let document = PDFDocument(data: sourceData),
                      let outputData = document.dataRepresentation() else {
                    return
                }

                loadedPageCount = document.pageCount
                outputSize = outputData.count
            }
        }

        return PerformanceTestMeasurement(
            id: "pdf",
            name: String(localized: "PDF Workflow"),
            duration: duration,
            detail: String(
                localized: "Generated, loaded, and exported \(loadedPageCount) pages (\(ByteCountFormatter.string(fromByteCount: Int64(outputSize), countStyle: .file)))"
            )
        )
    }

    private static func makePDF(pageCount: Int) -> Data? {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
            return nil
        }

        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }

        for pageNumber in 1...pageCount {
            context.beginPDFPage(nil)
            context.setFillColor(CGColor(gray: 0.2, alpha: 1))
            context.fill(CGRect(x: 72, y: 700, width: CGFloat(pageNumber % 10 + 1) * 40, height: 8))
            context.endPDFPage()
        }
        context.closePDF()

        return data as Data
    }

    @MainActor
    private static func currentDeviceInformation() -> (name: String, operatingSystem: String) {
#if canImport(UIKit)
        let device = UIDevice.current
        return (device.name, "\(device.systemName) \(device.systemVersion)")
#else
        return (
            Host.current().localizedName ?? String(localized: "Mac"),
            ProcessInfo.processInfo.operatingSystemVersionString
        )
#endif
    }
}

struct PerformanceTestView: View {
    @State private var report: PerformanceTestReport?
    @State private var isRunning = false
    @State private var didCopy = false

    var body: some View {
        Form {
            Section {
                Label(
                    "Tests run only on this device. Results are never sent externally.",
                    systemImage: "hand.raised"
                )
                .foregroundStyle(.secondary)
            }

            Section("Tests") {
                testDescription(
                    title: "CPU Calculation",
                    detail: "Measures a fixed set of integer calculations."
                )
                testDescription(
                    title: "Memory Processing",
                    detail: "Measures creation and scanning of a 16 MB data buffer."
                )
                testDescription(
                    title: "PDF Workflow",
                    detail: "Measures generation, loading, and export of a 100-page PDF."
                )

                Button {
                    runTests()
                } label: {
                    if isRunning {
                        Label {
                            Text("Running Tests…")
                        } icon: {
                            ProgressView()
                                .controlSize(.small)
                        }
                    } else {
                        Label("Run Tests", systemImage: "gauge.with.dots.needle.50percent")
                    }
                }
                .disabled(isRunning)
            }

            if let report {
                Section("Test Environment") {
                    LabeledContent("Test Date") {
                        Text(report.date, format: .dateTime.year().month().day().hour().minute().second())
                    }
                    LabeledContent("Device", value: report.deviceName)
                    LabeledContent("OS", value: report.operatingSystem)
                }

                Section("Results") {
                    ForEach(report.measurements) { measurement in
                        LabeledContent {
                            Text(measurement.formattedDuration)
                                .monospacedDigit()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(measurement.name)
                                Text(measurement.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button {
                        copyReport(report.text)
                    } label: {
                        Label(
                            didCopy ? "Copied" : "Copy Results",
                            systemImage: didCopy ? "checkmark" : "doc.on.doc"
                        )
                    }
                }
            }
        }
        .navigationTitle("Performance Test")
    }

    private func testDescription(title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func runTests() {
        isRunning = true
        didCopy = false

        Task {
            report = await PerformanceTestRunner.run()
            isRunning = false
        }
    }

    private func copyReport(_ text: String) {
#if canImport(UIKit)
        UIPasteboard.general.string = text
#elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#endif
        didCopy = true
    }
}

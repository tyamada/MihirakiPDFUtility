import Foundation

struct DiagnosticPDFMeasurement: Sendable {
    let pageCount: Int
    let inputBytes: Int64
    let outputBytes: Int64
    let generation: Duration
    let loading: Duration
    let writing: Duration
    let reopeningAndValidation: Duration
    let total: Duration

    var detail: String {
        func milliseconds(_ duration: Duration) -> String {
            let value = Double(duration.components.seconds) * 1_000
                + Double(duration.components.attoseconds) / 1_000_000_000_000_000
            return value.formatted(.number.precision(.fractionLength(3)))
        }
        return String(localized: "Pages: \(pageCount). Input: \(inputBytes) bytes; output: \(outputBytes) bytes. Generation: \(milliseconds(generation)) ms; opening and validation: \(milliseconds(loading)) ms; writing: \(milliseconds(writing)) ms; reopening and validation: \(milliseconds(reopeningAndValidation)) ms. Page counts and sizes matched. Times are reference measurements, not pass/fail thresholds.")
    }
}

enum DiagnosticPDFLoadTest {
    static let pageCounts = [100, 500, 1100]

    static func testCase(pageCount: Int, capacity: DiagnosticStorageCapacity = .live) -> DiagnosticTestCase {
        DiagnosticTestCase(id: "pdf.load.\(pageCount)", title: "PDF Load Test: \(pageCount) Pages") { directory in
            let fixture = directory.appending(path: "load-\(pageCount)", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: fixture, withIntermediateDirectories: false)
            defer { DiagnosticCaseCleanup.remove(fixture) }
            let measurement = try await DiagnosticPDFTest(capacity: capacity, pageCount: pageCount).measure(in: fixture)
            try DiagnosticResourceGuard.check()
            return DiagnosticCaseOutcome(status: .passed, duration: measurement.total, detail: measurement.detail)
        }
    }
}

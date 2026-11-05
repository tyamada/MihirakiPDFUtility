import Foundation
import Testing
@testable import MihirakiPDFUtility

struct DiagnosticImagePDFTests {
    @Test
    func generatesAndRendersImages() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let measurement = try await DiagnosticImagePDFTest(
            capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 }).measure(in: directory)
        #expect(measurement.pageCount == 8)
        #expect(measurement.inputBytes > 0)
        #expect(measurement.outputBytes > 0)
        #expect(measurement.total > .zero)
        print("Image fixture: input \(measurement.inputBytes), output \(measurement.outputBytes) bytes")
    }

    @Test @MainActor
    func capacityProfilesAndCleanup() async throws {
        for available: Int64? in [nil, 0, 600_000_000, 1_000_000_000, 4_000_000_000] {
            let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: base) }
            let runner = DiagnosticsRunner(
                cases: [DiagnosticImagePDFTest.testCase(capacity: DiagnosticStorageCapacity { _ in available })],
                workspace: DiagnosticWorkspace(baseDirectory: base))
            await runner.run()
            #expect(runner.results.map(\.status) == [available == 4_000_000_000 ? .passed : .skipped])
            #expect(try FileManager.default.contentsOfDirectory(atPath:
                base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
        }
    }

    @Test @MainActor
    func interruptionCleansPartialImages() async throws {
        for cancel in [false, true] {
            let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: base) }
            let capacity = DiagnosticStorageCapacity { directory in
                if FileManager.default.fileExists(atPath: directory.appending(path: "images.pdf").path) {
                    if cancel { withUnsafeCurrentTask { $0?.cancel() } }
                    else { return 0 }
                }
                return 4_000_000_000
            }
            let runner = DiagnosticsRunner(cases: [DiagnosticImagePDFTest.testCase(capacity: capacity)],
                                           workspace: DiagnosticWorkspace(baseDirectory: base))
            await runner.run()
            #expect(runner.results.map(\.status) == [cancel ? .cancelled : .skipped])
            #expect(try FileManager.default.contentsOfDirectory(atPath:
                base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
        }
    }
}

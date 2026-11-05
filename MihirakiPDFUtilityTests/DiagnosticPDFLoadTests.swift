import Foundation
import Testing
@testable import MihirakiPDFUtility

struct DiagnosticPDFLoadTests {
    @Test func allSizesProduceMeasuredValidPDFs() async throws {
        for count in DiagnosticPDFLoadTest.pageCounts {
            let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let measurement = try await DiagnosticPDFTest(
                capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 }, pageCount: count
            ).measure(in: directory)
            #expect(measurement.pageCount == count)
            #expect(measurement.inputBytes > 0 && measurement.outputBytes > 0)
            #expect(measurement.inputBytes + measurement.outputBytes < 4 * 1_024 * 1_024)
            #expect(measurement.generation > .zero && measurement.loading > .zero)
            #expect(measurement.writing > .zero && measurement.reopeningAndValidation > .zero)
            #expect(measurement.total >= measurement.generation + measurement.loading
                + measurement.writing + measurement.reopeningAndValidation)
            print("Load fixture \(count): input \(measurement.inputBytes), output \(measurement.outputBytes) bytes")
        }
    }

    @Test @MainActor
    func profilesSelectCasesAndCleanWorkspaces() async throws {
        for (available, expected) in [
            (Int64(4_000_000_000), [DiagnosticTestStatus.passed, .passed, .passed]),
            (640 * DiagnosticStorageBudget.mebibyte, [.passed, .skipped, .skipped]),
            (520 * DiagnosticStorageBudget.mebibyte, [.skipped, .skipped, .skipped])
        ] {
            let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: base) }
            let runner = DiagnosticsRunner(
                cases: DiagnosticPDFLoadTest.pageCounts.map {
                    DiagnosticPDFLoadTest.testCase(pageCount: $0, capacity: DiagnosticStorageCapacity { _ in available })
                },
                workspace: DiagnosticWorkspace(baseDirectory: base)
            )
            await runner.run()
            #expect(runner.results.map(\.status) == expected)
            #expect(try FileManager.default.contentsOfDirectory(atPath: base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
        }
    }

    @Test @MainActor
    func capacityDropAndCancellationCleanPartialLargePDFs() async throws {
        for cancel in [false, true] {
            let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: base) }
            let capacity = DiagnosticStorageCapacity { directory in
                let input = directory.appending(path: "basic-12.pdf")
                let size = (try? input.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                if size > 4_096 {
                    if cancel { withUnsafeCurrentTask { $0?.cancel() } }
                    else { return 0 }
                }
                return 4_000_000_000
            }
            let runner = DiagnosticsRunner(
                cases: [DiagnosticPDFLoadTest.testCase(pageCount: 1100, capacity: capacity)],
                workspace: DiagnosticWorkspace(baseDirectory: base)
            )
            await runner.run()
            #expect(runner.results.map(\.status) == [cancel ? .cancelled : .skipped])
            #expect(try FileManager.default.contentsOfDirectory(atPath: base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
        }
    }
}

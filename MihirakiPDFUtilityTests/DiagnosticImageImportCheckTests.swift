import Foundation
import Testing
@testable import MihirakiPDFUtility

struct DiagnosticImageImportCheckTests {
    @Test @MainActor
    func conversionAndCapacityProfiles() async throws {
        for available: Int64? in [nil, 0, 600_000_000, 4_000_000_000] {
            let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: base) }
            let runner = DiagnosticsRunner(
                cases: [DiagnosticImageImportTest.testCase(capacity: DiagnosticStorageCapacity { _ in available })],
                workspace: DiagnosticWorkspace(baseDirectory: base),
                thermalPolicy: DiagnosticThermalPolicy(read: { .nominal }), memoryPressure: { false })
            await runner.run()
            #expect(runner.results.map(\.status) == [(available ?? 0) >= 600_000_000 ? .passed : .skipped])
            #expect(runner.results.first?.cleanup?.succeeded == true)
            #expect(try FileManager.default.contentsOfDirectory(atPath:
                base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
        }
    }

    @Test @MainActor
    func partialGenerationAndSavedOutputAreCleaned() async throws {
        for marker in ["10.tiff", "converted.pdf"] {
            for cancel in [false, true] {
                let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
                defer { try? FileManager.default.removeItem(at: base) }
                let capacity = DiagnosticStorageCapacity { directory in
                    if FileManager.default.fileExists(atPath: directory.appending(path: marker).path) {
                        if cancel { withUnsafeCurrentTask { $0?.cancel() } }
                        else { return 0 }
                    }
                    return 4_000_000_000
                }
                let runner = DiagnosticsRunner(
                    cases: [DiagnosticImageImportTest.testCase(capacity: capacity)],
                    workspace: DiagnosticWorkspace(baseDirectory: base),
                    thermalPolicy: DiagnosticThermalPolicy(read: { .nominal }), memoryPressure: { false })
                await runner.run()
                #expect(runner.results.map(\.status) == [cancel ? .cancelled : .skipped])
                #expect(runner.results.first?.cleanup?.succeeded == true)
                #expect(try FileManager.default.contentsOfDirectory(atPath:
                    base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
            }
        }
    }
}

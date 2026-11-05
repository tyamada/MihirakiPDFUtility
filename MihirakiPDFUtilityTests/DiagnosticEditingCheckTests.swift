import Foundation
import Testing
@testable import MihirakiPDFUtility

struct DiagnosticEditingCheckTests {
    @Test @MainActor
    func passwordCheckCanStopBeforeProtectionRemoval() async throws {
        let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let capacity = DiagnosticStorageCapacity { directory in
            FileManager.default.fileExists(atPath: directory.appending(path: "protected.pdf").path)
                ? 0 : 4_000_000_000
        }
        let runner = DiagnosticsRunner(
            cases: [DiagnosticEditingCheck.password.testCase(capacity: capacity)],
            workspace: DiagnosticWorkspace(baseDirectory: base)
        )
        await runner.run()
        #expect(runner.results.map(\.status) == [.skipped])
        #expect(runner.results.first?.detail == DiagnosticPDFSkip.capacityChanged.detail)
        #expect(try FileManager.default.contentsOfDirectory(atPath:
            base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
    }

    @Test @MainActor
    func protectedReportDoesNotContainFixturePasswords() async throws {
        let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let runner = DiagnosticsRunner(
            cases: [DiagnosticEditingCheck.password.testCase(capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 })],
            workspace: DiagnosticWorkspace(baseDirectory: base)
        )
        await runner.run()
        let report = try #require(runner.report)
        #expect(report.count(.passed) == 1)
        let export = DiagnosticReportExport(report: report)
        let json = String(decoding: try export.jsonData(), as: UTF8.self)
        for value in ["diagnostic-fixture-2026", "incorrect-fixture-password", base.path] {
            #expect(!export.text.contains(value))
            #expect(!json.contains(value))
        }
    }

    @Test @MainActor
    func capacityDropBeforeEditedSaveSkipsAndCleans() async throws {
        let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let capacity = DiagnosticStorageCapacity { directory in
            FileManager.default.fileExists(atPath: directory.appending(path: "basic-12-rewritten.pdf").path)
                ? 0 : 4_000_000_000
        }
        let runner = DiagnosticsRunner(
            cases: [DiagnosticEditingCheck.saveReopen.testCase(capacity: capacity)],
            workspace: DiagnosticWorkspace(baseDirectory: base)
        )
        await runner.run()
        #expect(runner.results.map(\.status) == [.skipped])
        #expect(runner.results.first?.detail == DiagnosticPDFSkip.capacityChanged.detail)
        #expect(try FileManager.default.contentsOfDirectory(atPath:
            base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
    }

    @Test @MainActor
    func allEditingChecksUseIndependentDocuments() async throws {
        for check in DiagnosticEditingCheck.allCases {
            try await verifyIndependentDocument(check: check)
        }
    }

    @MainActor
    private func verifyIndependentDocument(check: DiagnosticEditingCheck) async throws {
        let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }
        _ = try await DiagnosticPDFTest(capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 }).run(in: base)
        let userModel = PDFEditorModel(recordsDiagnostics: false)
        userModel.open(base.appending(path: "basic-12.pdf"))
        userModel.selection = [userModel.pages[0].id]
        userModel.rotateSelection(by: 90)
        let ids = userModel.pages.map(\.id)
        let selection = userModel.selection
        let rotations = userModel.pages.map(\.page.rotation)
        let outcome = try await check.testCase(capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 }).execute(base)
        #expect(outcome.status == .passed)
        #expect(userModel.pages.map(\.id) == ids)
        #expect(userModel.selection == selection)
        #expect(userModel.pages.map(\.page.rotation) == rotations)
        #expect(userModel.canUndo)
        #expect(!FileManager.default.fileExists(atPath: base.appending(path: check.rawValue).path))
    }

    @Test @MainActor
    func allEditingChecksSkipAndCleanWhenStorageIsLow() async throws {
        for check in DiagnosticEditingCheck.allCases {
            try await verifyLowCapacity(check: check)
        }
    }

    @MainActor
    private func verifyLowCapacity(check: DiagnosticEditingCheck) async throws {
        let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let runner = DiagnosticsRunner(
            cases: [check.testCase(capacity: DiagnosticStorageCapacity { _ in 0 })],
            workspace: DiagnosticWorkspace(baseDirectory: base)
        )
        await runner.run()
        #expect(runner.results.map(\.status) == [.skipped])
        #expect(try FileManager.default.contentsOfDirectory(atPath: base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
    }
}

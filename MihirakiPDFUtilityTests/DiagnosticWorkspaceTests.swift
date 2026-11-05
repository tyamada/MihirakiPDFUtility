import Foundation
import Testing
@testable import MihirakiPDFUtility

struct DiagnosticWorkspaceTests {
    private func temporaryBase() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func recoveryPreservesActiveAndUnrelatedFiles() async throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let workspace = DiagnosticWorkspace(baseDirectory: base)
        let first = try await workspace.begin()
        let firstURL = await workspace.directory(for: first)
        try Data("fixture".utf8).write(to: firstURL.appending(path: "test.pdf"))
        let unrelated = base.appending(path: "user.pdf")
        try Data("user".utf8).write(to: unrelated)
        let abandoned = firstURL.deletingLastPathComponent().appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: abandoned, withIntermediateDirectories: false)
        let second = try await workspace.begin()
        #expect(FileManager.default.fileExists(atPath: firstURL.path))
        #expect(!FileManager.default.fileExists(atPath: abandoned.path))
        #expect(FileManager.default.fileExists(atPath: unrelated.path))
        try await workspace.finish(first)
        try await workspace.finish(second)
        #expect(!FileManager.default.fileExists(atPath: firstURL.path))
    }

    @Test func restartRecoversAbandonedRun() async throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let oldProcess = DiagnosticWorkspace(baseDirectory: base)
        let id = try await oldProcess.begin()
        let url = await oldProcess.directory(for: id)
        try Data("partial".utf8).write(to: url.appending(path: "partial.pdf"))
        // A new owner simulates a new process; the old one is no longer used.
        let restarted = DiagnosticWorkspace(baseDirectory: base)
        try await restarted.recoverAbandonedRuns()
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test func missingDirectoryIsAlreadyClean() async throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let workspace = DiagnosticWorkspace(baseDirectory: base)
        let id = try await workspace.begin()
        let url = await workspace.directory(for: id)
        try FileManager.default.removeItem(at: url.deletingLastPathComponent())
        try await workspace.finish(id)
    }

    @Test func recoveryNeverTraversesLinks() async throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let workspace = DiagnosticWorkspace(baseDirectory: base)
        let active = try await workspace.begin()
        let root = await workspace.directory(for: active).deletingLastPathComponent()
        let outside = base.appending(path: "documents")
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: false)
        let file = outside.appending(path: "keep.pdf")
        try Data("keep".utf8).write(to: file)
        let link = root.appending(path: UUID().uuidString)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)
        try await workspace.recoverAbandonedRuns()
        #expect(FileManager.default.fileExists(atPath: file.path))
        #expect(!FileManager.default.fileExists(atPath: link.path))
        try await workspace.finish(active)

        try FileManager.default.removeItem(at: root)
        try FileManager.default.createSymbolicLink(at: root, withDestinationURL: outside)
        await #expect(throws: DiagnosticWorkspaceError.self) {
            try await workspace.recoverAbandonedRuns()
        }
        #expect(FileManager.default.fileExists(atPath: file.path))
    }

    @Test @MainActor
    func cleanupFailureIsReportedAndRetried() async throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let workspace = DiagnosticWorkspace(baseDirectory: base)
        let root = base.appending(path: "MihirakiDiagnosticRuns")
        let saved = base.appending(path: "saved")
        let runner = DiagnosticsRunner(cases: [
            DiagnosticTestCase(id: "fixture", title: "Fixture", expectedChecksum: 1) {
                // Replace the root with a non-directory to force cleanup failure.
                try FileManager.default.moveItem(at: root, to: saved)
                try Data("blocked".utf8).write(to: root)
                return PerformanceTestMeasurement(id: "fixture", name: "", duration: .zero, detail: "", checksum: 1)
            }
        ], workspace: workspace)
        await runner.run()
        #expect(runner.results.map(\.status) == [.passed, .failed])
        #expect(runner.results.last?.id == "workspace.cleanup")
        #expect(!runner.isRunning)
        try FileManager.default.removeItem(at: root)
        try FileManager.default.moveItem(at: saved, to: root)
        try await workspace.recoverAbandonedRuns()
        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty)
    }

    @Test @MainActor
    func preparationFailurePreventsExecution() async throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        try Data("blocked".utf8).write(to: base.appending(path: "MihirakiDiagnosticRuns"))
        let runner = DiagnosticsRunner(cases: [
            DiagnosticTestCase(id: "never", title: "Never", expectedChecksum: 1) {
                Issue.record("Workspace preparation failed; test must not execute")
                throw DiagnosticWorkspaceError.unsafeDirectory
            }
        ], workspace: DiagnosticWorkspace(baseDirectory: base))
        await runner.run()
        #expect(runner.results.map(\.status) == [.notRun, .failed])
        #expect(runner.results.last?.id == "workspace.prepare")
    }

    @Test @MainActor
    func runnerCleansAfterSuccessFailureAndCancellation() async throws {
        for outcome in 0..<3 {
            let base = try temporaryBase()
            defer { try? FileManager.default.removeItem(at: base) }
            let workspace = DiagnosticWorkspace(baseDirectory: base)
            let runner = DiagnosticsRunner(cases: [
                DiagnosticTestCase(id: "fixture", title: "Fixture", expectedChecksum: 1) {
                    let root = base.appending(path: "MihirakiDiagnosticRuns")
                    let dirs = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
                    let dir = try #require(dirs.first)
                    try Data("generated".utf8).write(to: dir.appending(path: "test.pdf"))
                    if outcome == 1 { throw DiagnosticWorkspaceError.unknownRun }
                    if outcome == 2 { throw CancellationError() }
                    return PerformanceTestMeasurement(id: "fixture", name: "", duration: .zero, detail: "", checksum: 1)
                }
            ], workspace: workspace)
            await runner.run()
            #expect(runner.results.first?.status == [.passed, .failed, .cancelled][outcome])
            let remaining = try FileManager.default.contentsOfDirectory(
                at: base.appending(path: "MihirakiDiagnosticRuns"), includingPropertiesForKeys: nil
            )
            #expect(remaining.isEmpty)
        }
    }
}

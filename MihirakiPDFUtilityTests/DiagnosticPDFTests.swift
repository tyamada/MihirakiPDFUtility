import Foundation
import PDFKit
import Testing
@testable import MihirakiPDFUtility

struct DiagnosticPDFTests {
    private func temporaryBase() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func capacityFallbackPreservesZero() {
        #expect(DiagnosticStorageCapacity.resolve(opportunistic: { 0 }, fallback: {
            Issue.record("Zero must not trigger fallback")
            return 100
        }) == 0)
        #expect(DiagnosticStorageCapacity.resolve(opportunistic: { nil }, fallback: { 123 }) == 123)
        #expect(DiagnosticStorageCapacity.resolve(opportunistic: { -1 }, fallback: { 456 }) == 456)
        #expect(DiagnosticStorageCapacity.resolve(opportunistic: { throw CocoaError(.fileReadUnknown) },
                                                  fallback: { 789 }) == 789)
        #expect(DiagnosticStorageCapacity.resolve(opportunistic: { nil }, fallback: { -1 }) == nil)
        #expect(DiagnosticStorageCapacity.resolve(opportunistic: { nil },
                                                  fallback: { throw CocoaError(.fileReadUnknown) }) == nil)
    }

    @Test func createsAndReopensSmallPDF() async throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let fixture = DiagnosticPDFTest(capacity: DiagnosticStorageCapacity { _ in
            520 * DiagnosticStorageBudget.mebibyte // Minimum profile boundary.
        })
        _ = try await fixture.run(in: base)
        for filename in ["basic-12.pdf", "basic-12-rewritten.pdf"] {
            let url = base.appending(path: filename)
            let document = try #require(PDFDocument(url: url))
            #expect(document.pageCount == 12)
            #expect(document.page(at: 0)?.bounds(for: .mediaBox).size == CGSize(width: 420, height: 595))
            #expect(document.page(at: 11)?.bounds(for: .mediaBox).size == CGSize(width: 530, height: 300))
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize
            #expect(try #require(size) < 2 * 1_024 * 1_024)
        }
    }

    @Test(arguments: [Int64?.none, 0, 519 * DiagnosticStorageBudget.mebibyte])
    func refusesCreationBeforeWriting(available: Int64?) async throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let fixture = DiagnosticPDFTest(capacity: DiagnosticStorageCapacity { _ in available })
        do {
            _ = try await fixture.run(in: base)
            Issue.record("Expected storage skip")
        } catch is DiagnosticPDFSkip {
            #expect(try FileManager.default.contentsOfDirectory(atPath: base.path).isEmpty)
        }
    }

    @Test @MainActor
    func capacityDropSkipsAndCleansPartialPDF() async throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let probe = CapacityProbe(dropAt: 5)
        let runner = DiagnosticsRunner(
            cases: [.pdf(capacity: DiagnosticStorageCapacity { probe.read($0) })],
            workspace: DiagnosticWorkspace(baseDirectory: base)
        )
        await runner.run()
        #expect(probe.sawPartialFile)
        #expect(runner.results.map(\.status) == [.skipped])
        #expect(runner.results.first?.detail == DiagnosticPDFSkip.capacityChanged.detail)
        #expect(try FileManager.default.contentsOfDirectory(atPath:
            base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
    }

    @Test @MainActor
    func successfulRunCleansGeneratedFiles() async throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let runner = DiagnosticsRunner(
            cases: [.pdf(capacity: DiagnosticStorageCapacity { _ in 4_000_000_000 })],
            workspace: DiagnosticWorkspace(baseDirectory: base)
        )
        await runner.run()
        #expect(runner.results.map(\.status) == [.passed])
        #expect(try FileManager.default.contentsOfDirectory(atPath:
            base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
    }

    @Test @MainActor
    func cancellationDuringGenerationCleansPartialPDF() async throws {
        let base = try temporaryBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let probe = CapacityProbe(dropAt: 5, cancelInstead: true)
        let runner = DiagnosticsRunner(
            cases: [.pdf(capacity: DiagnosticStorageCapacity { probe.read($0) })],
            workspace: DiagnosticWorkspace(baseDirectory: base)
        )
        let task = Task { await runner.run() }
        await task.value
        #expect(probe.sawPartialFile)
        #expect(runner.results.map(\.status) == [.cancelled])
        #expect(try FileManager.default.contentsOfDirectory(atPath:
            base.appending(path: "MihirakiDiagnosticRuns").path).isEmpty)
    }
}

// All mutable state is guarded by the lock, including reads from the test actor.
private final class CapacityProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    private var partial = false
    private let dropAt: Int
    private let cancelInstead: Bool

    init(dropAt: Int, cancelInstead: Bool = false) {
        self.dropAt = dropAt
        self.cancelInstead = cancelInstead
    }

    var sawPartialFile: Bool { lock.withLock { partial } }

    func read(_ directory: URL) -> Int64? {
        lock.withLock {
            count += 1
            guard count >= dropAt else { return 4_000_000_000 }
            partial = FileManager.default.fileExists(atPath: directory.appending(path: "basic-12.pdf").path)
            if cancelInstead {
                withUnsafeCurrentTask { $0?.cancel() }
                return 4_000_000_000
            }
            return 0
        }
    }
}

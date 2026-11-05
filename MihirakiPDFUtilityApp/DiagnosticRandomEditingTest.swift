import Foundation
import PDFKit

enum DiagnosticRandomEditingTest {
    static let seed: UInt64 = 20_261_022
    static let operationCount = 64
    static let maximumPages = 24

    enum Operation: Int, CaseIterable, Sendable {
        case rotate, moveEarlier, duplicate, delete
    }

    struct PageState: Equatable, Sendable {
        let sourceIndex: Int
        var rotation: Int
    }

    struct Step: Sendable {
        let operation: Operation
        let index: Int
        let pages: [PageState]
        let selectedIndex: Int
    }

    /// Independent value-array oracle; never reads the editor's resulting state.
    static func plan(seed: UInt64) -> [Step] {
        var random = seed
        func next(_ limit: Int) -> Int {
            random = random &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int((random >> 32) % UInt64(limit))
        }
        var pages = (0..<12).map { PageState(sourceIndex: $0, rotation: 0) }
        var steps: [Step] = []
        for _ in 0..<operationCount {
            let operation = Operation.allCases[next(Operation.allCases.count)]
            let index = next(pages.count)
            var selectedIndex = index
            switch operation {
            case .rotate:
                pages[index].rotation = (pages[index].rotation + 90) % 360
            case .moveEarlier:
                if index > 0 {
                    let page = pages.remove(at: index)
                    pages.insert(page, at: index - 1)
                    selectedIndex = index - 1
                }
            case .duplicate:
                if pages.count < maximumPages {
                    pages.insert(pages[index], at: index + 1)
                    selectedIndex = index + 1
                }
            case .delete:
                if pages.count > 1 {
                    pages.remove(at: index)
                    selectedIndex = min(index, pages.count - 1)
                }
            }
            steps.append(Step(operation: operation, index: index, pages: pages, selectedIndex: selectedIndex))
        }
        return steps
    }

    static func testCase(
        capacity: DiagnosticStorageCapacity = .live, seed: UInt64 = Self.seed
    ) -> DiagnosticTestCase {
        DiagnosticTestCase(id: "pdf.stress.randomEditing", title: "PDF Randomized Editing") { directory in
            let fixture = directory.appending(path: "random-editing", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: fixture, withIntermediateDirectories: false)
            defer { DiagnosticCaseCleanup.remove(fixture) }
            let budget = DiagnosticStorageBudget().budget(availableBytes: capacity.read(fixture))
            _ = try await DiagnosticPDFTest(capacity: capacity).run(in: fixture)
            return try await verify(in: fixture, capacity: capacity, budget: budget, seed: seed)
        }
    }

    @MainActor
    private static func verify(
        in directory: URL, capacity: DiagnosticStorageCapacity, budget: Int64, seed: UInt64
    ) async throws -> DiagnosticCaseOutcome {
        let model = PDFEditorModel(recordsDiagnostics: false)
        model.open(directory.appending(path: "basic-12.pdf"))
        guard model.pages.count == 12, model.errorMessage == nil else { throw CocoaError(.fileReadCorruptFile) }
        let steps = plan(seed: seed)
        let start = ContinuousClock.now
        for (offset, step) in steps.enumerated() {
            await Task.yield()
            try DiagnosticResourceGuard.check()
            if offset.isMultiple(of: 8),
               !DiagnosticStorageBudget().plan(availableBytes: capacity.read(directory)).pageCounts.contains(12) {
                throw DiagnosticPDFSkip.capacityChanged
            }
            guard model.pages.indices.contains(step.index) else { return failure(step: offset, seed: seed, start: start) }
            model.selection = [model.pages[step.index].id]
            switch step.operation {
            case .rotate: model.rotateSelection(by: 90)
            case .moveEarlier: model.moveSelectionEarlier()
            case .duplicate:
                if model.pages.count < maximumPages { model.duplicateSelection() }
            case .delete: model.deleteSelection()
            }
            guard matches(model.pages.map(\.page), expected: step.pages),
                  model.selection == Set([model.pages[step.selectedIndex].id]),
                  model.errorMessage == nil else { return failure(step: offset, seed: seed, start: start) }
        }
        let output = try DiagnosticEditingCheck.writeExport(
            model, name: "random-edited.pdf", directory: directory, capacity: capacity, budget: budget)
        try DiagnosticResourceGuard.check()
        guard let reopened = PDFDocument(url: output), let last = steps.last else { throw CocoaError(.fileReadCorruptFile) }
        let pages = (0..<reopened.pageCount).compactMap { reopened.page(at: $0) }
        guard matches(pages, expected: last.pages) else {
            return failure(step: operationCount, seed: seed, start: start)
        }
        return DiagnosticCaseOutcome(
            status: .passed, duration: start.duration(to: .now),
            detail: String(localized: "Seed: \(String(seed)). Verified \(operationCount) rotation, movement, duplication and deletion operations against an independent page-state model. Saved and reopened \(pages.count) pages. Maximum: \(maximumPages) pages.")
        )
    }

    @MainActor
    private static func matches(_ pages: [PDFPage], expected: [PageState]) -> Bool {
        guard pages.count == expected.count else { return false }
        return zip(pages, expected).allSatisfy { page, state in
            let size = CGSize(width: 420 + state.sourceIndex * 10,
                              height: state.sourceIndex.isMultiple(of: 2) ? 595 : 300)
            return page.bounds(for: .mediaBox).size == size && page.rotation == state.rotation
        }
    }

    private static func failure(step: Int, seed: UInt64, start: ContinuousClock.Instant) -> DiagnosticCaseOutcome {
        DiagnosticCaseOutcome(status: .failed, duration: start.duration(to: .now),
                              detail: String(localized: "Random editing mismatch at step \(step + 1), seed \(String(seed))."))
    }
}

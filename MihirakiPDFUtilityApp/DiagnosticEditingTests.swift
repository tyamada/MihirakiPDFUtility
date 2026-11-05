import Foundation
import PDFKit

enum DiagnosticEditingCheck: String, CaseIterable, Sendable {
    case rotation, movement, deletion, duplication, blankInsertion, saveReopen, history, properties, password

    var title: LocalizedStringResource {
        switch self {
        case .rotation: "PDF Page Rotation"
        case .movement: "PDF Page Movement"
        case .deletion: "PDF Page Deletion"
        case .duplication: "PDF Page Duplication"
        case .blankInsertion: "PDF Blank Page Insertion"
        case .saveReopen: "PDF Edited Save and Reopen"
        case .history: "PDF Undo and Redo"
        case .properties: "PDF Document Properties"
        case .password: "PDF Password Protection"
        }
    }

    func testCase(capacity: DiagnosticStorageCapacity = .live) -> DiagnosticTestCase {
        DiagnosticTestCase(id: "pdf.edit.\(rawValue)", title: title) { directory in
            let fixtureDirectory = directory.appending(path: self.rawValue, directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: fixtureDirectory, withIntermediateDirectories: false)
            // The runner's workspace cleanup is the fallback if this removal fails.
            defer { DiagnosticCaseCleanup.remove(fixtureDirectory) }
            let budget = DiagnosticStorageBudget().budget(availableBytes: capacity.read(fixtureDirectory))
            _ = try await DiagnosticPDFTest(capacity: capacity).run(in: fixtureDirectory)
            try DiagnosticResourceGuard.check()
            return try await self.verify(url: fixtureDirectory.appending(path: "basic-12.pdf"),
                                         capacity: capacity, budget: budget)
        }
    }

    @MainActor
    private func verify(url: URL, capacity: DiagnosticStorageCapacity, budget: Int64) throws -> DiagnosticCaseOutcome {
        let model = PDFEditorModel(recordsDiagnostics: false)
        model.open(url)
        guard model.pages.count == 12, model.errorMessage == nil else {
            return DiagnosticCaseOutcome(status: .failed, duration: .zero,
                                         detail: String(localized: "The generated editing fixture could not be opened."))
        }
        let originalWidths: [CGFloat] = (0..<12).map { CGFloat(420 + $0 * 10) }
        let widths = { model.pages.map { $0.page.bounds(for: .mediaBox).width } }
        guard widths() == originalWidths else {
            return DiagnosticCaseOutcome(status: .failed, duration: .zero,
                                         detail: String(localized: "The generated editing fixture had unexpected page sizes."))
        }
        let selection = Set([model.pages[1].id, model.pages[4].id])
        model.selection = selection
        let start = ContinuousClock.now
        let passed: Bool
        let detail: String
        switch self {
        case .rotation:
            model.rotateSelection(by: -90)
            let expected = (0..<12).map { [1, 4].contains($0) ? 270 : 0 }
            passed = model.pages.map(\.page.rotation) == expected
                && widths() == originalWidths && model.selection == selection && model.isModified
            detail = passed
                ? String(localized: "Two selected pages rotated to 270 degrees; ten unselected pages remained at 0 degrees. Page order and selection matched.")
                : String(localized: "Rotation did not match the expected angles, page order or selection.")
        case .movement:
            model.moveSelectionToBeginning()
            let beginning = [1, 4] + (0..<12).filter { ![1, 4].contains($0) }
            let firstMatched = widths() == beginning.map { originalWidths[$0] }
                && model.selection == selection
            try DiagnosticResourceGuard.check()
            model.moveSelectionToEnd()
            let end = (0..<12).filter { ![1, 4].contains($0) } + [1, 4]
            passed = firstMatched && widths() == end.map { originalWidths[$0] }
                && model.selection == selection && model.isModified
            detail = passed
                ? String(localized: "Two selected pages moved to the beginning and then the end. All 12 pages retained their relative order and selection.")
                : String(localized: "Page movement did not match the expected order, page count or selection.")
        case .deletion:
            model.deleteSelection()
            let expected = (0..<12).filter { ![1, 4].contains($0) }
            let deletionMatched = widths() == expected.map { originalWidths[$0] }
                && model.pages.count == 10
                && model.selection == Set([model.pages[1].id]) && model.isModified
            let survivingIDs = model.pages.map(\.id)
            model.selectAllPages()
            model.deleteSelection()
            passed = deletionMatched && model.pages.map(\.id) == survivingIDs
                && model.selection.count == 10
            detail = passed
                ? String(localized: "Deleted two selected pages, preserved the remaining ten in order and selected the nearest page. Deleting all pages was prevented.")
                : String(localized: "Deletion did not match the expected remaining pages, selection or all-page deletion protection.")
        case .duplication:
            model.pages[1].page.rotation = 90
            model.pages[4].page.rotation = 270
            let firstPixels = try Self.raster(model.pages[1].page)
            let secondPixels = try Self.raster(model.pages[4].page)
            model.duplicateSelection()
            let expected = [0, 1, 1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10, 11]
            let structureMatched = widths() == expected.map { originalWidths[$0] }
            if structureMatched {
                let firstCopyPixels = try Self.raster(model.pages[2].page)
                let secondCopyPixels = try Self.raster(model.pages[6].page)
                passed = model.selection == Set([model.pages[2].id, model.pages[6].id])
                    && model.pages[2].page.rotation == 90 && model.pages[6].page.rotation == 270
                    && firstPixels.contains(where: { $0 < 240 })
                    && secondPixels.contains(where: { $0 < 240 })
                    && firstCopyPixels == firstPixels
                    && secondCopyPixels == secondPixels && model.isModified
            } else {
                passed = false
            }
            detail = passed
                ? String(localized: "Duplicated two pages after their originals. All 14 pages, copied rotations, selected duplicates and rendered content matched.")
                : String(localized: "Duplication did not match the expected page order, rotation, selection or rendered content.")
        case .blankInsertion:
            let beforeMatched = try Self.verifyBlankInsertion(url: url, before: true)
            try DiagnosticResourceGuard.check()
            let afterMatched = try Self.verifyBlankInsertion(url: url, before: false)
            passed = beforeMatched && afterMatched
            detail = passed
                ? String(localized: "Inserted blank pages before and after two selected pages in separate documents. All 14 pages, dimensions, rotations, selection and blank rendering matched.")
                : String(localized: "Blank insertion did not match the expected order, dimensions, rotation, selection or blank rendering.")
        case .saveReopen:
            model.rotateSelection(by: 90)
            model.moveSelectionToBeginning()
            let expected = [1, 4] + (0..<12).filter { ![1, 4].contains($0) }
            let expectedRotations = [90, 90] + Array(repeating: 0, count: 10)
            let originalPixels = try model.pages.map { try Self.raster($0.page) }
            let exported = try model.exportDocument()
            guard exported.data.count > 0, exported.data.count < 2 * 1_024 * 1_024 else {
                throw CocoaError(.fileWriteOutOfSpace)
            }
            let directory = url.deletingLastPathComponent()
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
            let used = try files.reduce(Int64(0)) { total, file in
                total + Int64(try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0)
            }
            guard DiagnosticStorageBudget().canContinue(
                initialBudgetBytes: budget, usedBytes: used,
                additionalEstimatedBytes: Int64(exported.data.count) * 2,
                availableBytes: capacity.read(directory)
            ) else { throw DiagnosticPDFSkip.capacityChanged }
            try DiagnosticResourceGuard.check()
            let output = directory.appending(path: "edited.pdf")
            try exported.data.write(to: output, options: .atomic)
            model.didExport(to: output)
            let savedStateMatched = !model.isModified
            let reopened = PDFEditorModel(recordsDiagnostics: false)
            reopened.open(output)
            let structureMatched = reopened.pages.map { $0.page.bounds(for: .mediaBox).width }
                == expected.map { originalWidths[$0] }
                && reopened.pages.map(\.page.rotation) == expectedRotations
            let reopenedPixels = try reopened.pages.map { try Self.raster($0.page) }
            passed = savedStateMatched && structureMatched && reopenedPixels == originalPixels
                && reopened.errorMessage == nil && !reopened.isModified && reopened.selection.isEmpty
            detail = passed
                ? String(localized: "Saved and reopened 12 edited pages. Page order, 90-degree rotations, rendered content and saved state matched.")
                : String(localized: "Saved editing results did not match the expected page order, rotations, rendered content or saved state.")
        case .history:
            let originalPixels = try model.pages.map { try Self.raster($0.page) }
            model.rotateSelection(by: 90)
            model.moveSelectionToBeginning()
            let expected = [1, 4] + (0..<12).filter { ![1, 4].contains($0) }
            let editedPixels = try model.pages.map { try Self.raster($0.page) }
            model.undo()
            let firstUndoMatched = widths() == originalWidths
                && model.pages.map(\.page.rotation) == (0..<12).map { [1, 4].contains($0) ? 90 : 0 }
            model.undo()
            let restoredPixels = try model.pages.map { try Self.raster($0.page) }
            let undoMatched = widths() == originalWidths && restoredPixels == originalPixels
                && model.pages.allSatisfy { $0.page.rotation == 0 }
                && model.selection == Set([model.pages[1].id, model.pages[4].id])
                && !model.isModified && !model.canUndo && model.canRedo
            try DiagnosticResourceGuard.check()
            model.redo()
            model.redo()
            let redonePixels = try model.pages.map { try Self.raster($0.page) }
            passed = firstUndoMatched && undoMatched
                && widths() == expected.map { originalWidths[$0] }
                && model.pages.map(\.page.rotation) == [90, 90] + Array(repeating: 0, count: 10)
                && redonePixels == editedPixels
                && model.selection == Set([model.pages[0].id, model.pages[1].id])
                && model.isModified && model.canUndo && !model.canRedo
            detail = passed
                ? String(localized: "Undid and redid rotation and movement. Page order, rotations, rendered content, selection and history state matched.")
                : String(localized: "Undo or redo did not restore the expected document, selection or history state.")
        case .properties:
            let metadata = PDFMetadata(title: "Diagnostic 日本語", author: "Generated Test",
                                       subject: "Property round trip", keywords: "alpha, beta")
            let preferences = PDFViewerPreferences(pageLayout: .twoColumnLeft, readingDirection: .rightToLeft)
            model.updateMetadata(metadata)
            model.updateViewerPreferences(preferences)
            let output = try Self.writeExport(model, name: "properties.pdf", directory: url.deletingLastPathComponent(),
                                              capacity: capacity, budget: budget)
            let reopened = PDFEditorModel(recordsDiagnostics: false)
            reopened.open(output)
            passed = reopened.pages.count == 12 && reopened.errorMessage == nil
                && reopened.metadata.title == metadata.title
                && reopened.metadata.author == metadata.author
                && reopened.metadata.subject == metadata.subject
                && reopened.metadata.keywords == "alpha, beta"
                && reopened.documentDetails.viewerPreferences == preferences
                && reopened.pages.map { $0.page.bounds(for: .mediaBox).width } == originalWidths
            detail = passed
                ? String(localized: "Saved and reopened title, author, subject, keywords, right-to-left reading and two-column layout. All 12 pages were preserved.")
                : String(localized: "Document properties or pages did not survive saving and reopening.")
        case .password:
            // Synthetic fixture passwords only; never include them in reports or logs.
            let testPassword = "diagnostic-fixture-2026"
            model.setViewingPassword(testPassword)
            let protectedURL = try Self.writeExport(model, name: "protected.pdf", directory: url.deletingLastPathComponent(),
                                                    capacity: capacity, budget: budget)
            guard let protected = PDFDocument(url: protectedURL) else { throw CocoaError(.fileReadCorruptFile) }
            let initiallyLocked = protected.isEncrypted && protected.isLocked
            let rejectsWrong = !protected.unlock(withPassword: "incorrect-fixture-password") && protected.isLocked
            let unlocks = protected.unlock(withPassword: testPassword)
            var contentsMatched = false
            if unlocks && protected.pageCount == 12 {
                contentsMatched = true
                for index in 0..<12 {
                    try DiagnosticResourceGuard.check()
                    guard let page = protected.page(at: index) else { contentsMatched = false; break }
                    let original = model.pages[index].page
                    let pixels = try Self.raster(page)
                    let originalPixels = try Self.raster(original)
                    if page.bounds(for: .mediaBox) != original.bounds(for: .mediaBox)
                        || pixels != originalPixels {
                        contentsMatched = false
                    }
                }
            }
            model.setViewingPassword(nil)
            let clearURL = try Self.writeExport(model, name: "unprotected.pdf", directory: url.deletingLastPathComponent(),
                                                capacity: capacity, budget: budget)
            guard let clear = PDFDocument(url: clearURL) else { throw CocoaError(.fileReadCorruptFile) }
            passed = initiallyLocked && rejectsWrong && unlocks && contentsMatched
                && !clear.isLocked && !clear.isEncrypted && clear.pageCount == 12 && !model.hasViewingPassword
            detail = passed
                ? String(localized: "Protected PDF rejected an incorrect password and opened with the test password. All 12 pages matched; removing protection produced an unlocked PDF.")
                : String(localized: "PDF password protection, unlocking, page content or protection removal did not match expectations.")
        }
        try DiagnosticResourceGuard.check()
        return DiagnosticCaseOutcome(status: passed ? .passed : .failed,
                                     duration: start.duration(to: .now), detail: detail)
    }

    @MainActor
    static func writeExport(
        _ model: PDFEditorModel, name: String, directory: URL,
        capacity: DiagnosticStorageCapacity, budget: Int64
    ) throws -> URL {
        try DiagnosticResourceGuard.check()
        let data = try model.exportDocument().data
        guard !data.isEmpty, data.count < 2 * 1_024 * 1_024 else { throw CocoaError(.fileWriteOutOfSpace) }
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
        let used = try files.reduce(Int64(0)) {
            $0 + Int64(try $1.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0)
        }
        guard DiagnosticStorageBudget().canContinue(
            initialBudgetBytes: budget, usedBytes: used,
            additionalEstimatedBytes: Int64(data.count) * 2,
            availableBytes: capacity.read(directory)
        ) else { throw DiagnosticPDFSkip.capacityChanged }
        try DiagnosticResourceGuard.check()
        let output = directory.appending(path: name)
        try data.write(to: output, options: .atomic)
        return output
    }

    @MainActor
    private static func verifyBlankInsertion(url: URL, before: Bool) throws -> Bool {
        let model = PDFEditorModel(recordsDiagnostics: false)
        model.open(url)
        guard model.pages.count == 12 else { return false }
        model.pages[1].page.rotation = 90
        model.pages[4].page.rotation = 270
        model.selection = Set([model.pages[1].id, model.pages[4].id])
        let originalPixels = try model.pages.map { try raster($0.page) }
        if before { model.insertBlankPagesBeforeSelection() }
        else { model.insertBlankPagesAfterSelection() }
        let order = [0, 1, 1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10, 11]
        guard model.pages.count == order.count else { return false }
        let blankIndexes = before ? [1, 5] : [2, 6]
        guard model.selection == Set(blankIndexes.map { model.pages[$0].id }), model.isModified else { return false }
        for (index, source) in order.enumerated() {
            try DiagnosticResourceGuard.check()
            let page = model.pages[index].page
            let expectedSize = CGSize(width: 420 + source * 10, height: source.isMultiple(of: 2) ? 595 : 300)
            let expectedRotation = source == 1 ? 90 : (source == 4 ? 270 : 0)
            guard page.bounds(for: .mediaBox).size == expectedSize,
                  page.rotation == expectedRotation else { return false }
            let pixels = try raster(page)
            if blankIndexes.contains(index) {
                guard pixels.allSatisfy({ $0 == 255 }) else { return false }
            } else {
                guard pixels == originalPixels[source] else { return false }
            }
        }
        return true
    }

    // Small deterministic grayscale raster: sufficient for the generated geometric
    // fixture. This is not a general PDF visual-equivalence comparison.
    @MainActor
    static func raster(_ page: PDFPage) throws -> [UInt8] {
        enum RenderError: Error { case unavailable }
        guard let reference = page.pageRef else { throw RenderError.unavailable }
        var bytes = [UInt8](repeating: 255, count: 128 * 128)
        try bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: 128, height: 128,
                                          bitsPerComponent: 8, bytesPerRow: 128,
                                          space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                throw RenderError.unavailable
            }
            context.concatenate(reference.getDrawingTransform(
                .mediaBox, rect: CGRect(x: 0, y: 0, width: 128, height: 128),
                rotate: 0, preserveAspectRatio: true))
            context.drawPDFPage(reference)
        }
        return bytes
    }
}

import Foundation
import PDFKit
import Testing
import UIKit
@testable import MihirakiPDFUtility

@Suite("PDF editor model")
struct PDFEditorModelTests {
    @Test("Editing without an open document is safely rejected")
    @MainActor
    func operationsWithoutDocument() throws {
        let appendedURL = try makePDF(sizes: [CGSize(width: 100, height: 200)])
        defer { try? FileManager.default.removeItem(at: appendedURL) }

        let model = PDFEditorModel()
        #expect(model.pages.isEmpty)
        #expect(!model.canEdit)
        #expect(!model.canDelete)
        #expect(!model.canMoveEarlier)
        #expect(!model.canMoveLater)

        model.rotateSelection(by: 90)
        model.insertBlankPagesAfterSelection()
        model.deleteSelection()
        model.moveSelectionEarlier()
        model.moveSelectionLater()
        model.setViewingPassword("secret")

        #expect(!model.isModified)
        #expect(!model.hasViewingPassword)
        #expect(model.append(appendedURL) == .failed)
        #expect(model.errorMessage != nil)
        #expect(throws: PDFEditorError.self) {
            try model.exportDocument()
        }
    }

    @Test("Rotation is normalized to a positive full-circle value", arguments: [
        (input: -90, expected: 270),
        (input: 0, expected: 0),
        (input: 450, expected: 90),
        (input: -450, expected: 270)
    ])
    @MainActor
    func normalizedRotation(input: Int, expected: Int) {
        #expect(PDFEditorModel.normalizedRotation(input) == expected)
    }

    @Test("Rotating pages changes only the selection")
    @MainActor
    func rotateSelectedPages() throws {
        let url = try makePDF(sizes: [
            CGSize(width: 100, height: 200),
            CGSize(width: 200, height: 300),
            CGSize(width: 300, height: 400)
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)
        model.selection = [model.pages[0].id, model.pages[2].id]

        model.rotateSelection(by: -90)

        #expect(model.pages.map(\.page.rotation) == [270, 0, 270])
        #expect(model.isModified)
    }

    @Test("A no-op rotation does not modify the document")
    @MainActor
    func noOpRotation() throws {
        let url = try makePDF(sizes: [CGSize(width: 100, height: 200)])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)

        model.rotateSelection(by: 90)
        #expect(!model.isModified)

        model.selection = [model.pages[0].id]
        model.rotateSelection(by: 360)
        #expect(model.pages[0].page.rotation == 0)
        #expect(!model.isModified)
    }

    @Test("A successful export clears the modified state until the next edit")
    @MainActor
    func exportStateTransitions() throws {
        let url = try makePDF(sizes: [CGSize(width: 100, height: 200)])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)
        model.selection = [model.pages[0].id]
        model.rotateSelection(by: 90)
        #expect(model.isModified)

        _ = try model.exportDocument()
        #expect(model.isModified)

        let exportedURL = FileManager.default.temporaryDirectory
            .appending(path: "Renamed Document")
            .appendingPathExtension("pdf")
        model.didExport(to: exportedURL)
        #expect(!model.isModified)
        #expect(model.sourceURL == exportedURL)
        #expect(model.displayName == "Renamed Document")

        model.rotateSelection(by: 90)
        #expect(model.isModified)
    }

    @Test("Appending a PDF adds all of its pages")
    @MainActor
    func appendPDF() throws {
        let originalURL = try makePDF(sizes: [CGSize(width: 20, height: 20)])
        let appendedURL = try makePDF(sizes: [
            CGSize(width: 20, height: 20),
            CGSize(width: 30, height: 20)
        ])
        defer {
            try? FileManager.default.removeItem(at: originalURL)
            try? FileManager.default.removeItem(at: appendedURL)
        }

        let model = PDFEditorModel()
        model.open(originalURL)
        model.append(appendedURL)

        #expect(model.pages.count == 3)
        #expect(model.isModified)
        #expect(model.errorMessage == nil)
    }

    @Test("Opening an invalid PDF preserves the current document")
    @MainActor
    func invalidPDFPreservesCurrentDocument() throws {
        let originalURL = try makePDF(sizes: [
            CGSize(width: 100, height: 200),
            CGSize(width: 300, height: 400)
        ])
        let invalidURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("pdf")
        try Data("Not a PDF".utf8).write(to: invalidURL)
        defer {
            try? FileManager.default.removeItem(at: originalURL)
            try? FileManager.default.removeItem(at: invalidURL)
        }

        let model = PDFEditorModel()
        #expect(model.open(originalURL) == .opened)
        let originalPageIDs = model.pages.map(\.id)

        #expect(model.open(invalidURL) == .failed)
        #expect(model.sourceURL == originalURL)
        #expect(model.pages.map(\.id) == originalPageIDs)
        #expect(pageWidths(in: model) == [100, 300])
        #expect(model.errorMessage != nil)
    }

    @Test("Opening an empty PDF preserves the current document")
    @MainActor
    func emptyPDFPreservesCurrentDocument() throws {
        let originalURL = try makePDF(sizes: [CGSize(width: 100, height: 200)])
        let emptyURL = try makeEmptyPDF()
        defer {
            try? FileManager.default.removeItem(at: originalURL)
            try? FileManager.default.removeItem(at: emptyURL)
        }

        let model = PDFEditorModel()
        model.open(originalURL)
        let originalPageID = model.pages[0].id

        #expect(model.open(emptyURL) == .failed)
        #expect(model.sourceURL == originalURL)
        #expect(model.pages.map(\.id) == [originalPageID])
        #expect(model.errorMessage != nil)
    }

    @Test("Appending an invalid PDF preserves the current document")
    @MainActor
    func invalidPDFAppendPreservesCurrentDocument() throws {
        let originalURL = try makePDF(sizes: [
            CGSize(width: 100, height: 200),
            CGSize(width: 300, height: 400)
        ])
        let invalidURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("pdf")
        try Data("Not a PDF".utf8).write(to: invalidURL)
        defer {
            try? FileManager.default.removeItem(at: originalURL)
            try? FileManager.default.removeItem(at: invalidURL)
        }

        let model = PDFEditorModel()
        model.open(originalURL)
        let selectedID = model.pages[1].id
        model.selection = [selectedID]

        #expect(model.append(invalidURL) == .failed)
        #expect(model.sourceURL == originalURL)
        #expect(pageWidths(in: model) == [100, 300])
        #expect(model.selection == [selectedID])
        #expect(!model.isModified)
        #expect(model.errorMessage != nil)
    }

    @Test("A successful append clears an earlier append error")
    @MainActor
    func successfulAppendClearsError() throws {
        let originalURL = try makePDF(sizes: [CGSize(width: 100, height: 200)])
        let appendedURL = try makePDF(sizes: [CGSize(width: 300, height: 400)])
        let invalidURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("pdf")
        try Data("Not a PDF".utf8).write(to: invalidURL)
        defer {
            try? FileManager.default.removeItem(at: originalURL)
            try? FileManager.default.removeItem(at: appendedURL)
            try? FileManager.default.removeItem(at: invalidURL)
        }

        let model = PDFEditorModel()
        model.open(originalURL)
        #expect(model.append(invalidURL) == .failed)
        #expect(model.errorMessage != nil)

        #expect(model.append(appendedURL) == .opened)
        #expect(model.errorMessage == nil)
        #expect(pageWidths(in: model) == [100, 300])
    }

    @Test("Requesting a password clears an earlier file error")
    @MainActor
    func passwordRequestClearsError() throws {
        let originalURL = try makePDF(sizes: [CGSize(width: 100, height: 200)])
        let protectedURL = try makeProtectedPDF(
            sizes: [CGSize(width: 300, height: 400)],
            password: "secret"
        )
        let invalidURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("pdf")
        try Data("Not a PDF".utf8).write(to: invalidURL)
        defer {
            try? FileManager.default.removeItem(at: originalURL)
            try? FileManager.default.removeItem(at: protectedURL)
            try? FileManager.default.removeItem(at: invalidURL)
        }

        let model = PDFEditorModel()
        model.open(originalURL)
        #expect(model.append(invalidURL) == .failed)
        #expect(model.errorMessage != nil)

        #expect(model.append(protectedURL) == .passwordRequired)
        #expect(model.errorMessage == nil)
        #expect(model.unlockPendingDocument(with: "secret"))
        #expect(pageWidths(in: model) == [100, 300])
    }

    @Test("Opening another PDF resets document-specific state")
    @MainActor
    func openingAnotherPDFResetsState() throws {
        let firstURL = try makePDF(sizes: [
            CGSize(width: 100, height: 200),
            CGSize(width: 200, height: 300)
        ])
        let secondURL = try makePDF(sizes: [CGSize(width: 400, height: 500)])
        defer {
            try? FileManager.default.removeItem(at: firstURL)
            try? FileManager.default.removeItem(at: secondURL)
        }

        let model = PDFEditorModel()
        model.open(firstURL)
        model.selection = [model.pages[0].id]
        model.setViewingPassword("secret")
        model.errorMessage = "Previous error"
        #expect(model.isModified)

        #expect(model.open(secondURL) == .opened)

        #expect(model.sourceURL == secondURL)
        #expect(pageWidths(in: model) == [400])
        #expect(model.selection.isEmpty)
        #expect(!model.hasViewingPassword)
        #expect(!model.isModified)
        #expect(model.errorMessage == nil)
    }

    @Test("Blank pages match each selected page and become selected")
    @MainActor
    func insertBlankPages() throws {
        let url = try makePDF(sizes: [
            CGSize(width: 200, height: 300),
            CGSize(width: 400, height: 250),
            CGSize(width: 612, height: 792)
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)
        model.pages[0].page.rotation = 90
        model.pages[2].page.rotation = 270
        model.selection = [model.pages[0].id, model.pages[2].id]
        model.insertBlankPagesAfterSelection()

        #expect(model.pages.count == 5)
        #expect(model.selection.count == 2)
        #expect(model.selection == [model.pages[1].id, model.pages[4].id])
        #expect(model.pages[1].page.bounds(for: .cropBox).size == model.pages[0].page.bounds(for: .cropBox).size)
        #expect(model.pages[4].page.bounds(for: .cropBox).size == model.pages[3].page.bounds(for: .cropBox).size)
        #expect(model.pages[1].page.rotation == 90)
        #expect(model.pages[4].page.rotation == 270)
        #expect(model.isModified)
    }

    @Test("Deleting pages selects the nearest remaining page")
    @MainActor
    func deletePagesSelectsNearestPage() throws {
        let url = try makePDF(sizes: [
            CGSize(width: 100, height: 500),
            CGSize(width: 200, height: 500),
            CGSize(width: 300, height: 500),
            CGSize(width: 400, height: 500)
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)
        model.selection = [model.pages[1].id, model.pages[3].id]
        model.deleteSelection()

        #expect(model.pages.count == 2)
        #expect(model.selection == [model.pages[1].id])
        #expect(model.pages[0].page.bounds(for: .cropBox).width == 100)
        #expect(model.pages[1].page.bounds(for: .cropBox).width == 300)
        #expect(model.isModified)
    }

    @Test("Deleting every page is prevented")
    @MainActor
    func preventDeletingEveryPage() throws {
        let url = try makePDF(sizes: [
            CGSize(width: 100, height: 200),
            CGSize(width: 300, height: 400)
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)
        model.selectAllPages()

        #expect(!model.canDelete)
        model.deleteSelection()

        #expect(pageWidths(in: model) == [100, 300])
        #expect(model.selection == Set(model.pages.map(\.id)))
        #expect(!model.isModified)
    }

    @Test("Moving multiple pages preserves their relative order")
    @MainActor
    func moveSelectedPages() throws {
        let url = try makePDF(sizes: [
            CGSize(width: 100, height: 500),
            CGSize(width: 200, height: 500),
            CGSize(width: 300, height: 500),
            CGSize(width: 400, height: 500)
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)
        model.selection = [model.pages[1].id, model.pages[3].id]

        #expect(model.canMoveEarlier)
        #expect(model.canMoveLater)
        model.moveSelectionEarlier()
        #expect(pageWidths(in: model) == [200, 100, 400, 300])
        #expect(model.canMoveEarlier)
        #expect(model.canMoveLater)

        model.moveSelectionLater()
        #expect(pageWidths(in: model) == [100, 200, 300, 400])
        #expect(model.isModified)

        model.selection = [model.pages[0].id, model.pages[1].id]
        #expect(!model.canMoveEarlier)
        model.selection = [model.pages[2].id, model.pages[3].id]
        #expect(!model.canMoveLater)
    }

    @Test("Dragging pages preserves their selection and updates the document order")
    @MainActor
    func dragPages() throws {
        let url = try makePDF(sizes: [
            CGSize(width: 100, height: 500),
            CGSize(width: 200, height: 500),
            CGSize(width: 300, height: 500),
            CGSize(width: 400, height: 500)
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)
        let movedIDs = Set([model.pages[1].id, model.pages[2].id])
        model.selection = movedIDs

        model.movePages(fromOffsets: IndexSet(integersIn: 1...2), toOffset: 4)

        #expect(pageWidths(in: model) == [100, 400, 200, 300])
        #expect(model.selection == movedIDs)
        #expect(model.isModified)

        let exported = try model.exportDocument()
        let reopened = try #require(PDFDocument(data: exported.data))
        let exportedWidths = (0..<reopened.pageCount).compactMap {
            reopened.page(at: $0)?.bounds(for: .cropBox).width
        }
        #expect(exportedWidths == [100, 400, 200, 300])
    }

    @Test("Dragging a page to the same position is not a modification")
    @MainActor
    func noOpPageDrag() throws {
        let url = try makePDF(sizes: [
            CGSize(width: 100, height: 500),
            CGSize(width: 200, height: 500),
            CGSize(width: 300, height: 500)
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)

        model.movePages(fromOffsets: IndexSet(integer: 1), toOffset: 2)

        #expect(pageWidths(in: model) == [100, 200, 300])
        #expect(!model.isModified)
    }

    @Test("Invalid page moves are safely ignored")
    @MainActor
    func invalidPageMoves() throws {
        let url = try makePDF(sizes: [
            CGSize(width: 100, height: 500),
            CGSize(width: 200, height: 500),
            CGSize(width: 300, height: 500)
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)

        model.movePages(fromOffsets: IndexSet(integer: 3), toOffset: 0)
        model.movePages(fromOffsets: IndexSet(integer: 1), toOffset: -1)
        model.movePages(fromOffsets: IndexSet(integer: 1), toOffset: 4)

        #expect(pageWidths(in: model) == [100, 200, 300])
        #expect(!model.isModified)
    }

    @Test("A password-protected PDF opens after the correct password")
    @MainActor
    func openPasswordProtectedPDF() throws {
        let sourceURL = try makePDF(sizes: [CGSize(width: 200, height: 300)])
        let protectedURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("pdf")
        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            try? FileManager.default.removeItem(at: protectedURL)
        }

        let document = try #require(PDFDocument(url: sourceURL))
        let wroteDocument = document.write(to: protectedURL, withOptions: [
            .userPasswordOption: "secret",
            .ownerPasswordOption: "owner"
        ])
        #expect(wroteDocument)

        let model = PDFEditorModel()
        let result = model.open(protectedURL)
        if case .passwordRequired = result {
            // Expected path.
        } else {
            Issue.record("The protected document did not request a password")
        }
        #expect(model.pages.isEmpty)
        #expect(!model.unlockPendingDocument(with: "wrong"))
        #expect(model.unlockPendingDocument(with: "secret"))
        #expect(model.pages.count == 1)
        #expect(model.sourceURL == protectedURL)
        #expect(model.hasViewingPassword)

        let protectedExport = try model.exportDocument()
        let protectedReopened = try #require(PDFDocument(data: protectedExport.data))
        #expect(protectedReopened.isLocked)
        #expect(protectedReopened.unlock(withPassword: "secret"))

        model.setViewingPassword(nil)
        #expect(!model.hasViewingPassword)
        let unprotectedExport = try model.exportDocument()
        let unprotectedReopened = try #require(PDFDocument(data: unprotectedExport.data))
        #expect(unprotectedReopened.isLocked == false)
    }

    @Test("Cancelling a protected PDF open preserves the current document")
    @MainActor
    func cancelProtectedPDFOpen() throws {
        let originalURL = try makePDF(sizes: [CGSize(width: 100, height: 200)])
        let protectedURL = try makeProtectedPDF(
            sizes: [CGSize(width: 300, height: 400)],
            password: "secret"
        )
        defer {
            try? FileManager.default.removeItem(at: originalURL)
            try? FileManager.default.removeItem(at: protectedURL)
        }

        let model = PDFEditorModel()
        model.open(originalURL)
        let originalPageID = model.pages[0].id
        #expect(model.open(protectedURL) == .passwordRequired)

        model.cancelPendingUnlock()

        #expect(!model.unlockPendingDocument(with: "secret"))
        #expect(model.sourceURL == originalURL)
        #expect(model.pages.map(\.id) == [originalPageID])
        #expect(pageWidths(in: model) == [100])
        #expect(!model.hasViewingPassword)
        #expect(!model.isModified)
    }

    @Test("A viewing password protects exported PDF data")
    @MainActor
    func setViewingPassword() throws {
        let url = try makePDF(sizes: [CGSize(width: 200, height: 300)])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)
        model.setViewingPassword("secret")

        #expect(model.hasViewingPassword)
        #expect(model.isModified)

        let exported = try model.exportDocument()
        let protectedDocument = try #require(PDFDocument(data: exported.data))
        #expect(protectedDocument.isLocked)
        #expect(!protectedDocument.unlock(withPassword: "wrong"))
        #expect(protectedDocument.unlock(withPassword: "secret"))
        #expect(protectedDocument.pageCount == 1)
    }

    @Test("Applying an equivalent viewing password is not a modification")
    @MainActor
    func equivalentViewingPasswordIsNotAModification() throws {
        let url = try makePDF(sizes: [CGSize(width: 200, height: 300)])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)

        model.setViewingPassword("")
        #expect(!model.isModified)

        model.setViewingPassword("secret")
        #expect(model.isModified)
        model.didExport(to: url)

        model.setViewingPassword("secret")
        #expect(!model.isModified)

        model.setViewingPassword(nil)
        #expect(model.isModified)
    }

    @Test("Document metadata is included in exported PDF data")
    @MainActor
    func updateDocumentMetadata() throws {
        let url = try makePDF(sizes: [CGSize(width: 200, height: 300)])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)
        model.updateMetadata(PDFMetadata(
            title: "Sample Title",
            author: "Sample Author",
            subject: "Sample Subject",
            keywords: "one, two, three"
        ))

        #expect(model.metadata.title == "Sample Title")
        #expect(model.metadata.keywords == "one, two, three")
        #expect(model.isModified)

        let exported = try model.exportDocument()
        let reopened = try #require(PDFDocument(data: exported.data))
        let attributes = reopened.documentAttributes ?? [:]
        #expect(attributes[PDFDocumentAttribute.titleAttribute] as? String == "Sample Title")
        #expect(attributes[PDFDocumentAttribute.authorAttribute] as? String == "Sample Author")
        #expect(attributes[PDFDocumentAttribute.subjectAttribute] as? String == "Sample Subject")
        #expect(attributes[PDFDocumentAttribute.keywordsAttribute] as? [String] == ["one", "two", "three"])
    }

    @Test("Applying equivalent metadata does not mark the document as modified")
    @MainActor
    func equivalentMetadataIsNotAModification() throws {
        let url = try makePDF(sizes: [CGSize(width: 200, height: 300)])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)
        model.updateMetadata(PDFMetadata(
            title: "Sample Title",
            author: "Sample Author",
            subject: "Sample Subject",
            keywords: "one, two"
        ))
        model.didExport(to: url)

        model.updateMetadata(PDFMetadata(
            title: "  Sample Title\n",
            author: "Sample Author",
            subject: "Sample Subject",
            keywords: "one,  two, "
        ))

        #expect(!model.isModified)
        #expect(model.metadata.keywords == "one, two")
    }

    @Test("Clearing document metadata removes it from exported PDF data")
    @MainActor
    func clearDocumentMetadata() throws {
        let url = try makePDF(sizes: [CGSize(width: 200, height: 300)])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)
        model.updateMetadata(PDFMetadata(
            title: "Sample Title",
            author: "Sample Author",
            subject: "Sample Subject",
            keywords: "one, two"
        ))
        model.updateMetadata(PDFMetadata(
            title: "  ",
            author: "\n",
            subject: "",
            keywords: " ,  "
        ))

        #expect(model.metadata == PDFMetadata())

        let exported = try model.exportDocument()
        let reopened = try #require(PDFDocument(data: exported.data))
        let attributes = reopened.documentAttributes ?? [:]
        #expect(attributes[PDFDocumentAttribute.titleAttribute] == nil)
        #expect(attributes[PDFDocumentAttribute.authorAttribute] == nil)
        #expect(attributes[PDFDocumentAttribute.subjectAttribute] == nil)
        #expect(attributes[PDFDocumentAttribute.keywordsAttribute] == nil)
    }

    @Test("Password-protected PDF pages can be appended after unlocking")
    @MainActor
    func appendPasswordProtectedPDF() throws {
        let originalURL = try makePDF(sizes: [CGSize(width: 100, height: 200)])
        let protectedURL = try makeProtectedPDF(
            sizes: [CGSize(width: 300, height: 400), CGSize(width: 500, height: 600)],
            password: "secret"
        )
        defer {
            try? FileManager.default.removeItem(at: originalURL)
            try? FileManager.default.removeItem(at: protectedURL)
        }

        let model = PDFEditorModel()
        model.open(originalURL)
        let result = model.append(protectedURL)
        if case .passwordRequired = result {
            // Expected path.
        } else {
            Issue.record("The protected document did not request a password")
        }

        #expect(model.pages.count == 1)
        #expect(!model.unlockPendingDocument(with: "wrong"))
        #expect(model.unlockPendingDocument(with: "secret"))
        #expect(model.pages.count == 3)
        #expect(model.isModified)
        #expect(!model.hasViewingPassword)
    }

    @Test("Cancelling a protected PDF append clears the pending unlock")
    @MainActor
    func cancelProtectedPDFAppend() throws {
        let originalURL = try makePDF(sizes: [CGSize(width: 100, height: 200)])
        let protectedURL = try makeProtectedPDF(
            sizes: [CGSize(width: 300, height: 400)],
            password: "secret"
        )
        defer {
            try? FileManager.default.removeItem(at: originalURL)
            try? FileManager.default.removeItem(at: protectedURL)
        }

        let model = PDFEditorModel()
        model.open(originalURL)
        #expect(model.append(protectedURL) == .passwordRequired)

        model.cancelPendingUnlock()

        #expect(!model.unlockPendingDocument(with: "secret"))
        #expect(pageWidths(in: model) == [100])
        #expect(!model.isModified)
        #expect(model.errorMessage == nil)
    }

    @Test("All pages can be selected and deselected")
    @MainActor
    func selectAndDeselectAllPages() throws {
        let url = try makePDF(sizes: [
            CGSize(width: 100, height: 200),
            CGSize(width: 200, height: 300),
            CGSize(width: 300, height: 400)
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)
        #expect(model.canSelectAll)

        model.selectAllPages()
        #expect(model.selection == Set(model.pages.map(\.id)))
        #expect(!model.canSelectAll)
        #expect(!model.canDelete)

        model.clearSelection()
        #expect(model.selection.isEmpty)
        #expect(model.canSelectAll)
    }

    @Test("Stale selection identifiers do not enable page editing")
    @MainActor
    func staleSelection() throws {
        let url = try makePDF(sizes: [
            CGSize(width: 100, height: 200),
            CGSize(width: 200, height: 300)
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let model = PDFEditorModel()
        model.open(url)
        model.selection = [UUID()]

        #expect(!model.canEdit)
        #expect(!model.canDelete)
        #expect(model.canSelectAll)
        #expect(!model.canMoveEarlier)
        #expect(!model.canMoveLater)

        model.rotateSelection(by: 90)
        model.deleteSelection()
        #expect(pageWidths(in: model) == [100, 200])
        #expect(!model.isModified)
    }

    @MainActor
    private func pageWidths(in model: PDFEditorModel) -> [CGFloat] {
        model.pages.map { $0.page.bounds(for: .cropBox).width }
    }

    private func makePDF(sizes: [CGSize]) throws -> URL {
        let document = PDFDocument()
        for (index, size) in sizes.enumerated() {
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
            let page = try #require(PDFPage(image: image))
            document.insert(page, at: index)
        }

        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("pdf")
        let data = try #require(document.dataRepresentation())
        try data.write(to: url)
        return url
    }

    private func makeEmptyPDF() throws -> URL {
        let objects = [
            "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n",
            "2 0 obj\n<< /Type /Pages /Kids [] /Count 0 >>\nendobj\n"
        ]
        var contents = "%PDF-1.4\n"
        var offsets: [Int] = []
        for object in objects {
            offsets.append(contents.utf8.count)
            contents += object
        }

        let crossReferenceOffset = contents.utf8.count
        contents += "xref\n0 3\n0000000000 65535 f \n"
        for offset in offsets {
            contents += String(format: "%010d 00000 n \n", offset)
        }
        contents += "trailer\n<< /Size 3 /Root 1 0 R >>\n"
        contents += "startxref\n\(crossReferenceOffset)\n%%EOF\n"

        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("pdf")
        try Data(contents.utf8).write(to: url)
        return url
    }

    private func makeProtectedPDF(sizes: [CGSize], password: String) throws -> URL {
        let sourceURL = try makePDF(sizes: sizes)
        defer { try? FileManager.default.removeItem(at: sourceURL) }
        let document = try #require(PDFDocument(url: sourceURL))
        let protectedURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("pdf")
        let didWrite = document.write(to: protectedURL, withOptions: [
            .userPasswordOption: password,
            .ownerPasswordOption: password
        ])
        try #require(didWrite)
        return protectedURL
    }
}

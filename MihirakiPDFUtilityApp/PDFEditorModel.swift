import Foundation
import Observation
import PDFKit
import SwiftUI
import UIKit

struct PDFPageItem: Identifiable {
    let id = UUID()
    let page: PDFPage
}

enum PDFOpenResult {
    case opened
    case passwordRequired
    case failed
}

private enum PendingUnlockAction {
    case open(URL)
    case append
}

struct PDFMetadata: Equatable {
    var title = ""
    var author = ""
    var subject = ""
    var keywords = ""
}

@MainActor
@Observable
final class PDFEditorModel {
    private var lockedDocument: PDFDocument?
    private var pendingUnlockAction: PendingUnlockAction?
    private var exportPassword: String?
    private(set) var document: PDFDocument?
    private(set) var pages: [PDFPageItem] = []
    private(set) var sourceURL: URL?
    private(set) var isModified = false

    var selection: Set<PDFPageItem.ID> = []
    var errorMessage: String?

    var displayName: String {
        sourceURL?.deletingPathExtension().lastPathComponent ?? String(localized: "Untitled")
    }

    var metadata: PDFMetadata {
        let attributes = document?.documentAttributes ?? [:]
        let keywords = attributes[PDFDocumentAttribute.keywordsAttribute] as? [String] ?? []
        return PDFMetadata(
            title: attributes[PDFDocumentAttribute.titleAttribute] as? String ?? "",
            author: attributes[PDFDocumentAttribute.authorAttribute] as? String ?? "",
            subject: attributes[PDFDocumentAttribute.subjectAttribute] as? String ?? "",
            keywords: keywords.joined(separator: ", ")
        )
    }

    var canEdit: Bool {
        document != nil && !selectedItems.isEmpty
    }

    var canDelete: Bool {
        let selectedCount = selectedItems.count
        return selectedCount > 0 && selectedCount < pages.count
    }

    var canSelectAll: Bool {
        !pages.isEmpty && selectedItems.count < pages.count
    }

    var hasViewingPassword: Bool {
        exportPassword != nil
    }

    var canMoveEarlier: Bool {
        pages.indices.contains { index in
            index > 0
                && selection.contains(pages[index].id)
                && !selection.contains(pages[index - 1].id)
        }
    }

    var canMoveLater: Bool {
        pages.indices.contains { index in
            index < pages.count - 1
                && selection.contains(pages[index].id)
                && !selection.contains(pages[index + 1].id)
        }
    }

    var canReverseSelection: Bool {
        selectedItems.count > 1
    }

    @discardableResult
    func open(_ url: URL) -> PDFOpenResult {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            guard let loadedDocument = PDFDocument(data: data) else {
                throw PDFEditorError.invalidDocument
            }
            if loadedDocument.isLocked {
                lockedDocument = loadedDocument
                pendingUnlockAction = .open(url)
                errorMessage = nil
                return .passwordRequired
            }
            guard loadedDocument.pageCount > 0 else {
                throw PDFEditorError.emptyDocument
            }

            adopt(loadedDocument, from: url)
            return .opened
        } catch {
            errorMessage = error.localizedDescription
            return .failed
        }
    }

    func unlockPendingDocument(with password: String) -> Bool {
        guard let lockedDocument, let pendingUnlockAction,
              lockedDocument.unlock(withPassword: password) else { return false }

        switch pendingUnlockAction {
        case .open(let url):
            guard lockedDocument.pageCount > 0 else {
                errorMessage = PDFEditorError.emptyDocument.localizedDescription
                cancelPendingUnlock()
                return false
            }
            adopt(lockedDocument, from: url)
            exportPassword = password
        case .append:
            do {
                try appendPages(from: lockedDocument)
            } catch {
                errorMessage = error.localizedDescription
                cancelPendingUnlock()
                return false
            }
        }
        cancelPendingUnlock()
        return true
    }

    func cancelPendingUnlock() {
        lockedDocument = nil
        pendingUnlockAction = nil
    }

    @discardableResult
    func append(_ url: URL) -> PDFOpenResult {
        guard document != nil else {
            errorMessage = PDFEditorError.noDocument.localizedDescription
            return .failed
        }

        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            guard let appendedDocument = PDFDocument(data: data) else {
                throw PDFEditorError.invalidDocument
            }
            if appendedDocument.isLocked {
                lockedDocument = appendedDocument
                pendingUnlockAction = .append
                errorMessage = nil
                return .passwordRequired
            }
            try appendPages(from: appendedDocument)
            return .opened
        } catch {
            errorMessage = error.localizedDescription
            return .failed
        }
    }

    func rotateSelection(by degrees: Int) {
        let items = selectedItems
        guard !items.isEmpty, Self.normalizedRotation(degrees) != 0 else { return }
        for item in items {
            item.page.rotation = Self.normalizedRotation(item.page.rotation + degrees)
        }
        markModified()
    }

    func duplicateSelection() {
        guard let document else { return }

        let selectedIndexes = pages.indices.filter { selection.contains(pages[$0].id) }
        guard !selectedIndexes.isEmpty else { return }

        var duplicatedIndexes: [Int] = []
        for (offset, sourceIndex) in selectedIndexes.enumerated() {
            let adjustedSourceIndex = sourceIndex + offset
            guard let sourcePage = document.page(at: adjustedSourceIndex),
                  let duplicatedPage = sourcePage.copy() as? PDFPage else { continue }

            let insertionIndex = adjustedSourceIndex + 1
            document.insert(duplicatedPage, at: insertionIndex)
            duplicatedIndexes.append(insertionIndex)
        }

        guard !duplicatedIndexes.isEmpty else { return }
        reloadPages()
        selection = Set(duplicatedIndexes.map { pages[$0].id })
        markModified()
    }

    func insertBlankPagesBeforeSelection() {
        insertBlankPages(relativeToSelectionBy: 0)
    }

    func insertBlankPagesAfterSelection() {
        insertBlankPages(relativeToSelectionBy: 1)
    }

    private func insertBlankPages(relativeToSelectionBy insertionOffset: Int) {
        guard let document else { return }

        let selectedIndexes = pages.indices.filter { selection.contains(pages[$0].id) }
        guard !selectedIndexes.isEmpty else { return }

        var insertedIndexes: [Int] = []
        for (offset, sourceIndex) in selectedIndexes.enumerated() {
            let adjustedSourceIndex = sourceIndex + offset
            guard let sourcePage = document.page(at: adjustedSourceIndex) else { continue }

            let cropBounds = sourcePage.bounds(for: .cropBox)
            let pageBounds = cropBounds.width > 0 && cropBounds.height > 0
                ? cropBounds
                : sourcePage.bounds(for: .mediaBox)
            guard pageBounds.width > 0, pageBounds.height > 0 else { continue }
            let renderer = UIGraphicsPDFRenderer(
                bounds: CGRect(origin: .zero, size: pageBounds.size)
            )
            let data = renderer.pdfData { context in
                context.beginPage()
            }
            guard let blankPage = PDFDocument(data: data)?.page(at: 0) else { continue }
            blankPage.rotation = sourcePage.rotation

            let insertionIndex = adjustedSourceIndex + insertionOffset
            document.insert(blankPage, at: insertionIndex)
            insertedIndexes.append(insertionIndex)
        }

        guard !insertedIndexes.isEmpty else { return }
        reloadPages()
        selection = Set(insertedIndexes.map { pages[$0].id })
        markModified()
    }

    func deleteSelection() {
        guard canDelete, let document else { return }

        let indexes = pages.indices.filter { selection.contains(pages[$0].id) }
        guard let firstDeletedIndex = indexes.first else { return }
        for index in indexes.reversed() {
            document.removePage(at: index)
        }
        reloadPages()
        let nearestIndex = min(firstDeletedIndex, pages.count - 1)
        selection = [pages[nearestIndex].id]
        markModified()
    }

    func selectAllPages() {
        selection = Set(pages.map(\.id))
    }

    func clearSelection() {
        selection.removeAll()
    }

    func moveSelectionEarlier() {
        var moved = false
        for index in pages.indices where index > 0 {
            guard selection.contains(pages[index].id),
                  !selection.contains(pages[index - 1].id) else { continue }
            pages.swapAt(index, index - 1)
            moved = true
        }
        finishSelectionMoveIfNeeded(moved)
    }

    func moveSelectionToBeginning() {
        guard canMoveEarlier else { return }
        pages = selectedItems + pages.filter { !selection.contains($0.id) }
        rebuildDocumentFromPages()
        markModified()
    }

    func moveSelectionLater() {
        var moved = false
        for index in pages.indices.reversed() where index < pages.count - 1 {
            guard selection.contains(pages[index].id),
                  !selection.contains(pages[index + 1].id) else { continue }
            pages.swapAt(index, index + 1)
            moved = true
        }
        finishSelectionMoveIfNeeded(moved)
    }

    func moveSelectionToEnd() {
        guard canMoveLater else { return }
        pages = pages.filter { !selection.contains($0.id) } + selectedItems
        rebuildDocumentFromPages()
        markModified()
    }

    func reverseSelectionOrder() {
        let indexes = pages.indices.filter { selection.contains(pages[$0].id) }
        guard indexes.count > 1 else { return }

        let reversedItems = indexes.map { pages[$0] }.reversed()
        for (index, item) in zip(indexes, reversedItems) {
            pages[index] = item
        }
        rebuildDocumentFromPages()
        markModified()
    }

    func movePages(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        guard !offsets.isEmpty,
              offsets.allSatisfy(pages.indices.contains),
              (0...pages.count).contains(destination) else { return }
        let originalOrder = pages.map(\.id)
        pages.move(fromOffsets: offsets, toOffset: destination)
        guard pages.map(\.id) != originalOrder else { return }

        rebuildDocumentFromPages()
        markModified()
    }

    func exportDocument() throws -> PDFExportDocument {
        guard let document else {
            throw PDFEditorError.noDocument
        }
        return try exportDocument(from: document)
    }

    func exportSelectionDocument() throws -> PDFExportDocument {
        guard document != nil else {
            throw PDFEditorError.noDocument
        }
        let items = selectedItems
        guard !items.isEmpty else {
            throw PDFEditorError.noSelection
        }

        let selectedDocument = PDFDocument()
        selectedDocument.documentAttributes = document?.documentAttributes
        for (index, item) in items.enumerated() {
            guard let page = item.page.copy() as? PDFPage else {
                throw PDFEditorError.invalidDocument
            }
            selectedDocument.insert(page, at: index)
        }
        return try exportDocument(from: selectedDocument)
    }

    private func exportDocument(from document: PDFDocument) throws -> PDFExportDocument {
        let data: Data?
        if let exportPassword {
            data = document.dataRepresentation(options: [
                PDFDocumentWriteOption.userPasswordOption: exportPassword,
                PDFDocumentWriteOption.ownerPasswordOption: exportPassword
            ])
        } else if document.isEncrypted {
            data = unencryptedDocumentCopy()?.dataRepresentation()
        } else {
            data = document.dataRepresentation()
        }
        guard let data else {
            throw PDFEditorError.noDocument
        }
        return PDFExportDocument(data: data)
    }

    func didExport(to url: URL) {
        sourceURL = url
        isModified = false
    }

    func updateMetadata(_ metadata: PDFMetadata) {
        guard let document else { return }
        let normalizedMetadata = PDFMetadata(
            title: metadata.title.trimmingCharacters(in: .whitespacesAndNewlines),
            author: metadata.author.trimmingCharacters(in: .whitespacesAndNewlines),
            subject: metadata.subject.trimmingCharacters(in: .whitespacesAndNewlines),
            keywords: metadata.keywords
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
        )
        guard normalizedMetadata != self.metadata else { return }

        var attributes = document.documentAttributes ?? [:]
        setMetadataValue(normalizedMetadata.title, for: .titleAttribute, in: &attributes)
        setMetadataValue(normalizedMetadata.author, for: .authorAttribute, in: &attributes)
        setMetadataValue(normalizedMetadata.subject, for: .subjectAttribute, in: &attributes)

        let keywords = normalizedMetadata.keywords.isEmpty
            ? []
            : normalizedMetadata.keywords.components(separatedBy: ", ")
        if keywords.isEmpty {
            attributes.removeValue(forKey: PDFDocumentAttribute.keywordsAttribute)
        } else {
            attributes[PDFDocumentAttribute.keywordsAttribute] = keywords
        }
        document.documentAttributes = attributes
        markModified()
    }

    func setViewingPassword(_ password: String?) {
        guard document != nil else { return }
        let newPassword = password?.isEmpty == false ? password : nil
        guard newPassword != exportPassword else { return }
        exportPassword = newPassword
        markModified()
    }

    static func normalizedRotation(_ rotation: Int) -> Int {
        let value = rotation % 360
        return value >= 0 ? value : value + 360
    }

    private var selectedItems: [PDFPageItem] {
        pages.filter { selection.contains($0.id) }
    }

    private func reloadPages() {
        guard let document else {
            pages = []
            return
        }
        pages = (0..<document.pageCount).compactMap { index in
            document.page(at: index).map(PDFPageItem.init(page:))
        }
    }

    private func adopt(_ loadedDocument: PDFDocument, from url: URL) {
        document = loadedDocument
        exportPassword = nil
        sourceURL = url
        selection.removeAll()
        isModified = false
        errorMessage = nil
        reloadPages()
    }

    private func appendPages(from appendedDocument: PDFDocument) throws {
        guard let document else { throw PDFEditorError.noDocument }
        guard appendedDocument.pageCount > 0 else { throw PDFEditorError.emptyDocument }

        for index in 0..<appendedDocument.pageCount {
            if let page = appendedDocument.page(at: index) {
                document.insert(page, at: document.pageCount)
            }
        }
        selection.removeAll()
        reloadPages()
        errorMessage = nil
        markModified()
    }

    private func markModified() {
        guard document != nil else { return }
        isModified = true
    }

    private func finishSelectionMoveIfNeeded(_ moved: Bool) {
        guard moved else { return }
        rebuildDocumentFromPages()
        markModified()
    }

    private func rebuildDocumentFromPages() {
        let reorderedDocument = PDFDocument()
        reorderedDocument.documentAttributes = document?.documentAttributes
        for (index, item) in pages.enumerated() {
            reorderedDocument.insert(item.page, at: index)
        }
        document = reorderedDocument
    }

    private func unencryptedDocumentCopy() -> PDFDocument? {
        guard let document else { return nil }
        let copy = PDFDocument()
        copy.documentAttributes = document.documentAttributes
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index)?.copy() as? PDFPage else { return nil }
            copy.insert(page, at: index)
        }
        return copy
    }

    private func setMetadataValue(
        _ value: String,
        for key: PDFDocumentAttribute,
        in attributes: inout [AnyHashable: Any]
    ) {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty {
            attributes.removeValue(forKey: key)
        } else {
            attributes[key] = trimmedValue
        }
    }
}

enum PDFEditorError: LocalizedError {
    case emptyDocument
    case invalidDocument
    case noDocument
    case noSelection
    case passwordRequired

    var errorDescription: String? {
        switch self {
        case .emptyDocument:
            String(localized: "The selected PDF does not contain any pages.")
        case .invalidDocument:
            String(localized: "The selected file is not a valid PDF document.")
        case .noDocument:
            String(localized: "There is no PDF document to save.")
        case .noSelection:
            String(localized: "Select at least one page to save.")
        case .passwordRequired:
            String(localized: "The PDF must be unlocked before its pages can be added.")
        }
    }
}

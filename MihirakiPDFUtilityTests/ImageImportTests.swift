import CoreGraphics
import Foundation
import ImageIO
import PDFKit
import Testing
import UniformTypeIdentifiers
@testable import MihirakiPDFUtility

@Suite("Image folder import")
struct ImageImportTests {
    @Test("All six sort modes use the requested order", arguments: ImageSortKey.allCases, ImageSortDirection.allCases)
    func sortModes(key: ImageSortKey, direction: ImageSortDirection) {
        let files = [
            file("10.png", created: 1, modified: 2),
            file("2.png", created: 3, modified: 1),
            file("1.png", created: 2, modified: 3)
        ]
        let expected: [String]
        switch key {
        case .name: expected = ["1.png", "2.png", "10.png"]
        case .creationDate: expected = ["10.png", "1.png", "2.png"]
        case .modificationDate: expected = ["2.png", "10.png", "1.png"]
        }
        let names = ImageImportOrdering.sorted(files, by: key, direction: direction).map(\.name)
        #expect(names == (direction == .ascending ? expected : expected.reversed()))
    }

    @Test("Date ties use natural names and unknown dates stay last", arguments: [ImageSortKey.creationDate, .modificationDate], ImageSortDirection.allCases)
    func dateTies(key: ImageSortKey, direction: ImageSortDirection) {
        let files = [file("10.png", created: 1, modified: 1),
                     file("0.png", created: nil, modified: nil),
                     file("2.png", created: 1, modified: 1)]
        #expect(ImageImportOrdering.sorted(files, by: key, direction: direction).map(\.name)
                == ["2.png", "10.png", "0.png"])
    }

    @Test("Folder enumeration uses metadata only and excludes nested and hidden files")
    func enumeration() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        for name in ["2.png", "1.JPG", ".hidden.png", "notes.txt"] {
            try Data("not decoded during listing".utf8).write(to: folder.appendingPathComponent(name))
        }
        let nested = folder.appendingPathComponent("nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try Data().write(to: nested.appendingPathComponent("3.png"))
        let service = ImageImportService()
        let files = try await service.files(in: folder)
        #expect(Set(files.map(\.name)) == ["1.JPG", "2.png"])
        #expect(files.allSatisfy { $0.creationDate != nil && $0.modificationDate != nil })
    }

    @Test("Images preserve order, dimensions, orientation, and survive editing and export")
    @MainActor
    func conversionAndEditing() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        try makeImage(folder.appendingPathComponent("2.tiff"), width: 30, height: 50, orientation: 6)
        try makeImage(folder.appendingPathComponent("1.tiff"), width: 20, height: 40)
        let service = ImageImportService()
        let files = try await service.files(in: folder)
        let ordered = ImageImportOrdering.sorted(files, by: .name, direction: .ascending)
        let data = try await service.makePDF(from: ordered, in: folder) { _ in }
        let pdf = try #require(PDFDocument(data: data))
        #expect(pdf.pageCount == 2)
        #expect(pdf.page(at: 0)?.bounds(for: .mediaBox).size == CGSize(width: 20, height: 40))
        #expect(pdf.page(at: 1)?.bounds(for: .mediaBox).size == CGSize(width: 50, height: 30))

        let model = PDFEditorModel()
        try model.openImagePDF(data, name: "Images")
        #expect(model.sourceURL == nil)
        #expect(model.displayName == "Images")
        #expect(model.isModified)
        model.selectAllPages()
        model.rotateSelection(by: 90)
        model.setViewingPassword("secret")
        #expect(model.canUndo)
        try model.openImagePDF(data, name: "New Images")
        #expect(!model.canUndo && !model.canRedo && !model.hasViewingPassword)
        #expect(model.selection.isEmpty)
        model.selectAllPages()
        model.reverseSelectionOrder()
        let exported = try model.exportDocument()
        let reopened = try #require(PDFDocument(data: exported.data))
        #expect(reopened.pageCount == 2)
        #expect(reopened.page(at: 0)?.bounds(for: .mediaBox).size == CGSize(width: 50, height: 30))
        let saved = folder.appendingPathComponent("Saved.pdf")
        try exported.data.write(to: saved)
        model.didExport(to: saved)
        #expect(!model.isModified && model.displayName == "Saved")
        #expect(model.open(saved) == .opened)
        #expect(model.pages.count == 2)
    }

    @Test("Invalid images fail with the filename and do not replace the editor document")
    @MainActor
    func invalidImage() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("broken.png")
        try Data("broken".utf8).write(to: url)
        let service = ImageImportService()
        let files = try await service.files(in: folder)
        do {
            _ = try await service.makePDF(from: files, in: folder) { _ in }
            Issue.record("Expected invalid image failure")
        } catch ImageImportError.unreadable(let name) {
            #expect(name == "broken.png")
        }

        try makeImage(folder.appendingPathComponent("good.tiff"), width: 20, height: 40)
        let good = try await service.files(in: folder).filter { $0.name == "good.tiff" }
        let data = try await service.makePDF(from: good, in: folder) { _ in }
        let model = PDFEditorModel()
        try model.openImagePDF(data, name: "Keep")
        model.selectAllPages()
        model.rotateSelection(by: 90)
        let id = model.pages.first?.id
        #expect(throws: ImageImportError.self) {
            try model.openImagePDF(Data(), name: "Invalid")
        }
        #expect(model.pages.first?.id == id)
        #expect(model.displayName == "Keep" && model.isModified && model.canUndo)
    }

    @Test("Cancellation stops conversion without returning a partial PDF")
    func cancellation() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        try makeImage(folder.appendingPathComponent("one.tiff"), width: 20, height: 40)
        let service = ImageImportService()
        let files = try await service.files(in: folder)
        let task = Task {
            try await service.makePDF(from: files, in: folder) { _ in
                withUnsafeCurrentTask { $0?.cancel() }
            }
        }
        do {
            _ = try await task.value
            Issue.record("Expected cancellation")
        } catch is CancellationError {
            // The completed image is discarded instead of returning a partial document.
        }
    }

    @Test("Empty folders remain empty and cannot produce a PDF")
    @MainActor
    func emptyFolderAndDefaults() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let model = ImageImportModel()
        #expect(model.sortKey == .name && model.direction == .ascending)
        await model.scan(folder)
        #expect(model.orderedFiles.isEmpty && !model.isScanning)
        #expect(await model.convert(folder) == nil)
    }

    @Test("A large image batch produces every page in order")
    func largeBatch() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        try makeImage(folder.appendingPathComponent("page.tiff"), width: 100, height: 140)
        let service = ImageImportService()
        let first = try #require(try await service.files(in: folder).first)
        let data = try await service.makePDF(
            from: Array(repeating: first, count: 250), in: folder
        ) { _ in }
        let pdf = try #require(PDFDocument(data: data))
        #expect(pdf.pageCount == 250)
        #expect(pdf.page(at: 249)?.bounds(for: .mediaBox).size == CGSize(width: 100, height: 140))
    }

    private func file(_ name: String, created: Double?, modified: Double?) -> ImageImportFile {
        ImageImportFile(
            url: URL(fileURLWithPath: "/images/\(name)"),
            creationDate: created.map { Date(timeIntervalSince1970: $0) },
            modificationDate: modified.map { Date(timeIntervalSince1970: $0) }
        )
    }

    private func temporaryFolder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeImage(_ url: URL, width: Int, height: Int, orientation: Int = 1) throws {
        let context = try #require(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try #require(context.makeImage())
        let destination = try #require(CGImageDestinationCreateWithURL(
            url as CFURL, UTType.tiff.identifier as CFString, 1, nil
        ))
        CGImageDestinationAddImage(destination, image, [
            kCGImagePropertyOrientation: orientation
        ] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
    }
}

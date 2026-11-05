import CoreGraphics
import Foundation
import PDFKit
import Testing
@testable import MihirakiPDFUtility

@Suite("PDF Page Geometry Tests")
struct PDFPageGeometryTests {
    @Test("splitBoxes vertical cut with 0 degree rotation creates equal left and right halves")
    func splitBoxesVertical0Deg() {
        let bounds = CGRect(x: 0, y: 0, width: 200, height: 100)
        let (left, right) = PDFPageGeometry.splitBoxes(for: bounds, rotation: 0, direction: .vertical)

        #expect(left.origin.x == 0)
        #expect(left.origin.y == 0)
        #expect(left.width == 100)
        #expect(left.height == 100)

        #expect(right.origin.x == 100)
        #expect(right.origin.y == 0)
        #expect(right.width == 100)
        #expect(right.height == 100)
    }

    @Test("splitBoxes horizontal cut with 0 degree rotation creates equal top and bottom halves")
    func splitBoxesHorizontal0Deg() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 200)
        let (top, bottom) = PDFPageGeometry.splitBoxes(for: bounds, rotation: 0, direction: .horizontal)

        #expect(top.origin.y == 100)
        #expect(top.height == 100)

        #expect(bottom.origin.y == 0)
        #expect(bottom.height == 100)
    }

    @Test("cropBox applies margin correctly and clamps to 40%")
    func cropBoxClamping() {
        let base = CGRect(x: 0, y: 0, width: 100, height: 200)
        let cropped10 = PDFPageGeometry.cropBox(for: base, margin: 0.10)
        #expect(cropped10.origin.x == 10)
        #expect(cropped10.origin.y == 20)
        #expect(cropped10.width == 80)
        #expect(cropped10.height == 160)

        let croppedOver = PDFPageGeometry.cropBox(for: base, margin: 0.60)
        // Clamped to 40%
        #expect(croppedOver.origin.x == 40)
        #expect(croppedOver.origin.y == 80)
        #expect(croppedOver.width == 20)
        #expect(croppedOver.height == 40)

        let croppedZero = PDFPageGeometry.cropBox(for: base, margin: 0.0)
        #expect(croppedZero == base)
    }

    @Test("split page creates two pages and doubles count")
    @MainActor
    func splitPageDoublesCount() throws {
        let model = PDFEditorModel(recordsDiagnostics: false)
        let pdfData = createSamplePDFData(pageCount: 2)
        try model.openImagePDF(pdfData, name: "Sample")

        #expect(model.pages.count == 2)

        // Select the first page
        model.selection = [model.pages[0].id]
        model.splitSelection(direction: .vertical)

        #expect(model.pages.count == 3)
        #expect(model.isModified)

        // Undo restores original 2 pages
        model.undo()
        #expect(model.pages.count == 2)

        // Redo restores split 3 pages
        model.redo()
        #expect(model.pages.count == 3)
    }

    @Test("crop page updates cropBox and is undoable")
    @MainActor
    func cropPageUpdatesCropBox() throws {
        let model = PDFEditorModel(recordsDiagnostics: false)
        let pdfData = createSamplePDFData(pageCount: 1)
        try model.openImagePDF(pdfData, name: "Sample")

        let originalCropBox = model.pages[0].page.bounds(for: .cropBox)
        model.selection = [model.pages[0].id]
        model.cropSelection(margin: 0.10)

        let croppedCropBox = model.pages[0].page.bounds(for: .cropBox)
        #expect(croppedCropBox.width < originalCropBox.width)
        #expect(croppedCropBox.height < originalCropBox.height)
        #expect(model.isModified)

        model.undo()
        let restoredCropBox = model.pages[0].page.bounds(for: .cropBox)
        #expect(restoredCropBox.width == originalCropBox.width)
    }

    private func createSamplePDFData(pageCount: Int) -> Data {
        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: 200, height: 300)
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        for _ in 0..<pageCount {
            context.beginPDFPage(nil)
            context.endPDFPage()
        }
        context.closePDF()
        return pdfData as Data
    }
}

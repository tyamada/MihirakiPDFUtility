import Foundation
import CoreGraphics
import ImageIO
import PDFKit
import UniformTypeIdentifiers

actor DiagnosticImageImportTest {
    private struct CapacitySkip: DiagnosticSkipReason {
        let detail = String(localized: "Image conversion test skipped or stopped because sufficient available storage could not be confirmed.")
    }

    static func testCase(capacity: DiagnosticStorageCapacity = .live) -> DiagnosticTestCase {
        DiagnosticTestCase(id: "images.folderConversion", title: "Generated Image Folder Conversion") { directory in
            let fixture = directory.appending(path: "image-import", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: fixture, withIntermediateDirectories: false)
            defer { DiagnosticCaseCleanup.remove(fixture) }
            return try await Self().run(in: fixture, capacity: capacity)
        }
    }

    private func run(in directory: URL, capacity: DiagnosticStorageCapacity) async throws -> DiagnosticCaseOutcome {
        let policy = DiagnosticStorageBudget()
        let plan = policy.plan(availableBytes: capacity.read(directory))
        guard plan.pageCounts.contains(12) else { throw CapacitySkip() }
        let check: @Sendable () throws -> Void = {
            try DiagnosticResourceGuard.check()
            // All three tiny TIFFs and the PDF are bounded below 1 MiB each.
            guard policy.canContinue(initialBudgetBytes: plan.budgetBytes, usedBytes: 4 * 1_048_576,
                                     additionalEstimatedBytes: 2 * 1_048_576,
                                     availableBytes: capacity.read(directory)) else { throw CapacitySkip() }
            try DiagnosticResourceGuard.check()
        }
        let start = ContinuousClock.now
        try check()
        try makeImage(directory.appending(path: "10.tiff"), width: 60, height: 80, gray: 1)
        try check()
        try makeImage(directory.appending(path: "2.tiff"), width: 30, height: 50, gray: 0.5, orientation: 6)
        try check()
        try makeImage(directory.appending(path: "1.tiff"), width: 20, height: 40, gray: 0)
        try check()
        let service = ImageImportService()
        let files = try await service.files(in: directory)
        let ascending = ImageImportOrdering.sorted(files, by: .name, direction: .ascending)
        let descending = ImageImportOrdering.sorted(files, by: .name, direction: .descending)
        guard ascending.map(\.name) == ["1.tiff", "2.tiff", "10.tiff"],
              descending.map(\.name) == ["10.tiff", "2.tiff", "1.tiff"] else {
            throw CocoaError(.fileReadCorruptFile)
        }
        for reversed in [false, true] {
            try check()
            let data = try await service.makePDF(from: reversed ? descending : ascending,
                                                 in: directory, checkpoint: check) { _ in }
            guard !data.isEmpty, data.count < 1_048_576 else { throw CocoaError(.fileWriteOutOfSpace) }
            try check()
            let output = directory.appending(path: "converted.pdf")
            try data.write(to: output, options: .atomic)
            guard let document = PDFDocument(url: output), document.pageCount == 3 else {
                throw CocoaError(.fileReadCorruptFile)
            }
            let sizes = [CGSize(width: 20, height: 40), CGSize(width: 50, height: 30), CGSize(width: 60, height: 80)]
            // Non-overlapping bands allow color-profile conversion without accepting swapped or blank pages.
            let grayRanges = [0...16, 96...160, 239...255]
            for pageIndex in 0..<3 {
                try check()
                let source = reversed ? 2 - pageIndex : pageIndex
                guard let page = document.page(at: pageIndex),
                      page.bounds(for: .mediaBox).size == sizes[source],
                      let reference = page.pageRef else { throw CocoaError(.fileReadCorruptFile) }
                var pixels = [UInt8](repeating: 255, count: 32 * 32)
                try pixels.withUnsafeMutableBytes { bytes in
                    guard let context = CGContext(data: bytes.baseAddress, width: 32, height: 32,
                                                  bitsPerComponent: 8, bytesPerRow: 32,
                                                  space: CGColorSpaceCreateDeviceGray(),
                                                  bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                        throw CocoaError(.fileReadUnknown)
                    }
                    context.scaleBy(x: 32 / sizes[source].width, y: 32 / sizes[source].height)
                    context.drawPDFPage(reference)
                }
                guard grayRanges[source].contains(Int(pixels[16 * 32 + 16])) else {
                    throw CocoaError(.fileReadCorruptFile)
                }
            }
        }
        return DiagnosticCaseOutcome(status: .passed, duration: start.duration(to: .now),
            detail: String(localized: "Generated three TIFF images and converted them with the image import service. Verified natural ascending and descending order, EXIF-rotated page dimensions, and rendered brightness after saving and reopening both PDFs."))
    }

    private func makeImage(_ url: URL, width: Int, height: Int, gray: CGFloat, orientation: Int = 1) throws {
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else { throw CocoaError(.fileWriteUnknown) }
        context.setFillColor(CGColor(gray: gray, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.tiff.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation] as CFDictionary)
        guard CGImageDestinationFinalize(destination),
              let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              size < 1_048_576 else { throw CocoaError(.fileWriteUnknown) }
    }
}

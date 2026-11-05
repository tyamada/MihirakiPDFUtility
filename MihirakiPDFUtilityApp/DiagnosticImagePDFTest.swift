import Foundation
import CoreGraphics
import PDFKit

/// Bounded bitmap workload. PDFKit and Core Graphics objects stay on this actor.
actor DiagnosticImagePDFTest {
    static let pageCount = 8
    static let imageSide = 1024
    private let capacity: DiagnosticStorageCapacity
    private let policy = DiagnosticStorageBudget()
    private let fileLimit: Int64 = 64 * DiagnosticStorageBudget.mebibyte

    init(capacity: DiagnosticStorageCapacity = .live) {
        self.capacity = capacity
    }

    static func testCase(capacity: DiagnosticStorageCapacity = .live) -> DiagnosticTestCase {
        DiagnosticTestCase(id: "pdf.stress.images", title: "PDF Image Load Test") { directory in
            let fixture = directory.appending(path: "image-load", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: fixture, withIntermediateDirectories: false)
            defer { DiagnosticCaseCleanup.remove(fixture) }
            let measurement = try await Self(capacity: capacity).measure(in: fixture)
            return DiagnosticCaseOutcome(
                status: .passed, duration: measurement.total,
                detail: measurement.detail + "\n" + String(localized: "Generated eight 1024 × 1024 grayscale images on this device. Rendered every page before and after saving and verified 16 brightness samples per page.")
            )
        }
    }

    func measure(in directory: URL) throws -> DiagnosticPDFMeasurement {
        try DiagnosticResourceGuard.check()
        let plan = policy.plan(availableBytes: capacity.read(directory))
        guard plan.availableBytes != nil else { throw DiagnosticPDFSkip.capacityUnknown }
        guard plan.includesImageStress else { throw DiagnosticPDFSkip.insufficientCapacity }
        let input = directory.appending(path: "images.pdf")
        let output = directory.appending(path: "images-rewritten.pdf")
        let start = ContinuousClock.now
        try generate(input, directory: directory, budget: plan.budgetBytes)
        let generated = ContinuousClock.now
        let inputBytes = try size(input)
        try check(directory, budget: plan.budgetBytes, used: inputBytes)
        guard let document = PDFDocument(url: input) else { throw CocoaError(.fileReadCorruptFile) }
        try validate(document, directory: directory, budget: plan.budgetBytes, used: inputBytes)
        let loaded = ContinuousClock.now
        try check(directory, budget: plan.budgetBytes, used: inputBytes)
        guard document.write(to: output) else { throw CocoaError(.fileWriteUnknown) }
        let written = ContinuousClock.now
        let outputBytes = try size(output)
        try check(directory, budget: plan.budgetBytes, used: inputBytes + outputBytes)
        guard let reopened = PDFDocument(url: output) else { throw CocoaError(.fileReadCorruptFile) }
        try validate(reopened, directory: directory, budget: plan.budgetBytes, used: inputBytes + outputBytes)
        return DiagnosticPDFMeasurement(
            pageCount: Self.pageCount, inputBytes: inputBytes, outputBytes: outputBytes,
            generation: start.duration(to: generated), loading: generated.duration(to: loaded),
            writing: loaded.duration(to: written), reopeningAndValidation: written.duration(to: .now),
            total: start.duration(to: .now))
    }

    private func check(_ directory: URL, budget: Int64, used: Int64) throws {
        try DiagnosticResourceGuard.check()
        let available = capacity.read(directory)
        try DiagnosticResourceGuard.check()
        guard policy.canContinue(initialBudgetBytes: budget, usedBytes: used,
                                 additionalEstimatedBytes: fileLimit, availableBytes: available) else {
            throw DiagnosticPDFSkip.capacityChanged
        }
    }

    private func size(_ url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let bytes = attributes[.size] as? NSNumber,
              bytes.int64Value >= 0, bytes.int64Value < fileLimit else { throw CocoaError(.fileWriteOutOfSpace) }
        return bytes.int64Value
    }

    private func generate(_ url: URL, directory: URL, budget: Int64) throws {
        try check(directory, budget: budget, used: 0)
        var box = CGRect(x: 0, y: 0, width: 512, height: 512)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let pdf = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        defer { pdf.closePDF() }
        for index in 0..<Self.pageCount {
            try check(directory, budget: budget, used: size(url))
            try autoreleasepool {
                let side = Self.imageSide
                var pixels = [UInt8](repeating: 0, count: side * side)
                for y in 0..<side {
                    if y.isMultiple(of: 64) { try DiagnosticResourceGuard.check() }
                    for x in 0..<side {
                        // Known vertical bands plus deterministic texture; no bundled image data.
                        let level = ((x / 64 + index) % 16) * 16 + 4
                        pixels[y * side + x] = UInt8(level + ((x * 17 + y * 31 + index) % 7))
                    }
                }
                let data = Data(pixels)
                guard let provider = CGDataProvider(data: data as CFData),
                      let image = CGImage(width: side, height: side, bitsPerComponent: 8,
                                          bitsPerPixel: 8, bytesPerRow: side,
                                          space: CGColorSpaceCreateDeviceGray(), bitmapInfo: [],
                                          provider: provider, decode: nil, shouldInterpolate: false,
                                          intent: .defaultIntent) else { throw CocoaError(.fileWriteUnknown) }
                pdf.beginPDFPage(nil)
                pdf.draw(image, in: box)
                pdf.endPDFPage()
            }
        }
    }

    private func validate(_ document: PDFDocument, directory: URL, budget: Int64, used: Int64) throws {
        guard document.pageCount == Self.pageCount else { throw CocoaError(.fileReadCorruptFile) }
        for index in 0..<Self.pageCount {
            try check(directory, budget: budget, used: used)
            try autoreleasepool {
                guard let page = document.page(at: index), let reference = page.pageRef,
                      page.bounds(for: .mediaBox) == CGRect(x: 0, y: 0, width: 512, height: 512) else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                var pixels = [UInt8](repeating: 255, count: 128 * 128)
                try pixels.withUnsafeMutableBytes { buffer in
                    guard let context = CGContext(data: buffer.baseAddress, width: 128, height: 128,
                                                  bitsPerComponent: 8, bytesPerRow: 128,
                                                  space: CGColorSpaceCreateDeviceGray(),
                                                  bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                        throw CocoaError(.fileReadUnknown)
                    }
                    context.scaleBy(x: 0.25, y: 0.25)
                    context.drawPDFPage(reference)
                }
                // Samples are well inside each band, away from interpolation boundaries.
                for band in 0..<16 {
                    let expected = ((band + index) % 16) * 16 + 7
                    guard abs(Int(pixels[64 * 128 + band * 8 + 4]) - expected) <= 8 else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                }
            }
        }
    }
}

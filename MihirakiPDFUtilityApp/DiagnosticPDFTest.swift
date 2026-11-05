import Foundation
import CoreGraphics
import PDFKit

protocol DiagnosticSkipReason: Error {
    var detail: String { get }
}

enum DiagnosticPDFSkip: DiagnosticSkipReason {
    case capacityUnknown, insufficientCapacity, capacityChanged

    var detail: String {
        switch self {
        case .capacityUnknown:
            String(localized: "PDF test skipped because available storage could not be determined.")
        case .insufficientCapacity:
            String(localized: "PDF test skipped because there is not enough available storage.")
        case .capacityChanged:
            String(localized: "PDF test stopped because available storage changed during the test.")
        }
    }
}

/// PDFKit objects remain on this actor. The runner owns the enclosing directory.
actor DiagnosticPDFTest {
    private enum Failure: Error {
        case create, reopen, validation, save, sizeLimit
    }

    static let pageCount = 12
    private let capacity: DiagnosticStorageCapacity
    private let numberOfPages: Int
    private let policy = DiagnosticStorageBudget()
    private let estimatedPeakBytes: Int64

    init(capacity: DiagnosticStorageCapacity = .live, pageCount: Int = 12) {
        self.capacity = capacity
        numberOfPages = pageCount
        estimatedPeakBytes = Int64(pageCount <= 12 ? 4 : (pageCount <= 100 ? 32 : 128))
            * DiagnosticStorageBudget.mebibyte
    }

    func run(in directory: URL) throws -> String {
        let measurement = try measure(in: directory)
        if numberOfPages == 12 {
            return String(localized: "Generated, saved and reopened a 12-page PDF. Page count and page sizes matched.")
        }
        return measurement.detail
    }

    func measure(in directory: URL) throws -> DiagnosticPDFMeasurement {
        try DiagnosticResourceGuard.check()
        let plan = policy.plan(availableBytes: capacity.read(directory))
        guard plan.availableBytes != nil else { throw DiagnosticPDFSkip.capacityUnknown }
        guard plan.pageCounts.contains(numberOfPages) else { throw DiagnosticPDFSkip.insufficientCapacity }

        // Retain the existing names for the 12-page fixture used by editing tests.
        let input = directory.appendingPathComponent("basic-12.pdf")
        let output = directory.appendingPathComponent("basic-12-rewritten.pdf")
        let start = ContinuousClock.now
        try generate(at: input, directory: directory, budget: plan.budgetBytes)
        let generatedAt = ContinuousClock.now
        try DiagnosticResourceGuard.check()
        let inputBytes = try byteCount(input)
        guard inputBytes > 0, inputBytes < estimatedPeakBytes / 2 else { throw Failure.sizeLimit }
        let loadStart = ContinuousClock.now
        guard let document = PDFDocument(url: input) else { throw Failure.reopen }
        try validate(document)
        let loadedAt = ContinuousClock.now
        try checkCapacity(in: directory, budget: plan.budgetBytes, usedBytes: inputBytes)
        let writeStart = ContinuousClock.now
        guard document.write(to: output) else { throw Failure.save }
        let writtenAt = ContinuousClock.now
        try DiagnosticResourceGuard.check()
        let reopenStart = ContinuousClock.now
        guard let reopened = PDFDocument(url: output) else { throw Failure.reopen }
        try validate(reopened)
        let outputBytes = try byteCount(output)
        guard outputBytes > 0, outputBytes < estimatedPeakBytes / 2 else { throw Failure.sizeLimit }
        return DiagnosticPDFMeasurement(
            pageCount: numberOfPages, inputBytes: inputBytes, outputBytes: outputBytes,
            generation: start.duration(to: generatedAt), loading: loadStart.duration(to: loadedAt),
            writing: writeStart.duration(to: writtenAt), reopeningAndValidation: reopenStart.duration(to: .now),
            total: start.duration(to: .now)
        )
    }

    private func generate(at url: URL, directory: URL, budget: Int64) throws {
        try checkCapacity(in: directory, budget: budget, usedBytes: 0)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else { throw Failure.create }
        defer { context.closePDF() }
        for index in 0..<numberOfPages {
            try DiagnosticResourceGuard.check()
            let used = try byteCount(url)
            guard used < estimatedPeakBytes / 2 else { throw Failure.sizeLimit }
            try checkCapacity(in: directory, budget: budget, usedBytes: used)
            var box = Self.pageBounds(index)
            let data = Data(bytes: &box, count: MemoryLayout<CGRect>.size)
            context.beginPDFPage([kCGPDFContextMediaBox as String: data] as CFDictionary)
            context.setFillColor(CGColor(gray: 1, alpha: 1))
            context.fill(box)
            context.setFillColor(CGColor(gray: 0, alpha: 1))
            context.fill(CGRect(x: 24, y: 24, width: 20 + (index % 12) * 8, height: 32))
            context.endPDFPage()
        }
    }

    private func validate(_ document: PDFDocument) throws {
        guard document.pageCount == numberOfPages else { throw Failure.validation }
        for index in 0..<numberOfPages {
            try DiagnosticResourceGuard.check()
            guard let page = document.page(at: index),
                  page.bounds(for: .mediaBox) == Self.pageBounds(index) else { throw Failure.validation }
        }
    }

    private static func pageBounds(_ index: Int) -> CGRect {
        CGRect(x: 0, y: 0, width: 420 + (index % 12) * 10, height: index.isMultiple(of: 2) ? 595 : 300)
    }

    private func checkCapacity(in directory: URL, budget: Int64, usedBytes: Int64) throws {
        guard policy.canContinue(
            initialBudgetBytes: budget, usedBytes: usedBytes,
            additionalEstimatedBytes: estimatedPeakBytes / 2,
            availableBytes: capacity.read(directory)
        ) else { throw DiagnosticPDFSkip.capacityChanged }
    }

    private func byteCount(_ url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let size = attributes[.size] as? NSNumber else { throw Failure.sizeLimit }
        return size.int64Value
    }
}

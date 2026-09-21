import CoreGraphics
import Foundation

enum PDFPageLayout: String, CaseIterable, Identifiable, Equatable, Sendable {
    case singlePage = "SinglePage"
    case oneColumn = "OneColumn"
    case twoColumnLeft = "TwoColumnLeft"
    case twoColumnRight = "TwoColumnRight"
    case twoPageLeft = "TwoPageLeft"
    case twoPageRight = "TwoPageRight"

    var id: Self { self }

    var requiresPDFVersion15: Bool {
        self == .twoPageLeft || self == .twoPageRight
    }
}

enum PDFReadingDirection: String, CaseIterable, Identifiable, Equatable, Sendable {
    case leftToRight = "L2R"
    case rightToLeft = "R2L"

    var id: Self { self }
}

struct PDFViewerPreferences: Equatable, Sendable {
    var pageLayout: PDFPageLayout = .singlePage
    var readingDirection: PDFReadingDirection = .leftToRight

    var canDisplayCover: Bool {
        switch pageLayout {
        case .twoColumnLeft, .twoColumnRight, .twoPageLeft, .twoPageRight:
            true
        case .singlePage, .oneColumn:
            false
        }
    }

    var displaysCover: Bool {
        guard canDisplayCover else { return false }
        switch (readingDirection, pageLayout) {
        case (.leftToRight, .twoColumnRight), (.leftToRight, .twoPageRight),
             (.rightToLeft, .twoColumnLeft), (.rightToLeft, .twoPageLeft):
            return true
        default:
            return false
        }
    }

    mutating func setDisplaysCover(_ displaysCover: Bool) {
        guard canDisplayCover, displaysCover != self.displaysCover else { return }
        switch pageLayout {
        case .twoColumnLeft, .twoColumnRight:
            pageLayout = sideLayout(
                displaysCover: displaysCover,
                left: .twoColumnLeft,
                right: .twoColumnRight
            )
        case .twoPageLeft, .twoPageRight:
            pageLayout = sideLayout(
                displaysCover: displaysCover,
                left: .twoPageLeft,
                right: .twoPageRight
            )
        case .singlePage, .oneColumn:
            break
        }
    }

    mutating func setReadingDirection(_ direction: PDFReadingDirection) {
        let preservedCoverSetting = displaysCover
        readingDirection = direction
        setDisplaysCover(preservedCoverSetting)
    }

    private func sideLayout(
        displaysCover: Bool,
        left: PDFPageLayout,
        right: PDFPageLayout
    ) -> PDFPageLayout {
        let coverIsOnRight = readingDirection == .leftToRight
            ? displaysCover
            : !displaysCover
        return coverIsOnRight ? right : left
    }
}

struct PDFVersion: Comparable, Equatable, Sendable {
    let major: Int
    let minor: Int

    var displayName: String { "PDF \(major).\(minor)" }

    static func < (left: Self, right: Self) -> Bool {
        (left.major, left.minor) < (right.major, right.minor)
    }
}

struct PDFDocumentDetails: Equatable, Sendable {
    var pdfVersion: PDFVersion? = nil
    var viewerPreferences = PDFViewerPreferences()

    var version: String { pdfVersion?.displayName ?? "-" }

    mutating func ensureCompatibleVersion() {
        guard viewerPreferences.pageLayout.requiresPDFVersion15,
              let pdfVersion,
              pdfVersion < PDFVersion(major: 1, minor: 5) else { return }
        self.pdfVersion = PDFVersion(major: 1, minor: 5)
    }
}

enum PDFDocumentPropertiesReader {
    static func read(from data: Data) -> PDFDocumentDetails {
        guard let provider = CGDataProvider(data: data as CFData),
              let document = CGPDFDocument(provider) else {
            return PDFDocumentDetails()
        }

        var majorVersion: Int32 = 0
        var minorVersion: Int32 = 0
        document.getVersion(majorVersion: &majorVersion, minorVersion: &minorVersion)

        guard let catalog = document.catalog else {
            return PDFDocumentDetails(
                pdfVersion: PDFVersion(major: Int(majorVersion), minor: Int(minorVersion))
            )
        }
        let pageLayout = name(for: "PageLayout", in: catalog)
            .flatMap(PDFPageLayout.init(rawValue:)) ?? .singlePage

        var viewerPreferencesDictionary: CGPDFDictionaryRef?
        let direction: PDFReadingDirection
        if CGPDFDictionaryGetDictionary(catalog, "ViewerPreferences", &viewerPreferencesDictionary),
           let viewerPreferencesDictionary,
           let directionName = name(for: "Direction", in: viewerPreferencesDictionary),
           let parsedDirection = PDFReadingDirection(rawValue: directionName) {
            direction = parsedDirection
        } else {
            direction = .leftToRight
        }

        return PDFDocumentDetails(
            pdfVersion: PDFVersion(major: Int(majorVersion), minor: Int(minorVersion)),
            viewerPreferences: PDFViewerPreferences(
                pageLayout: pageLayout,
                readingDirection: direction
            )
        )
    }

    private static func name(
        for key: String,
        in dictionary: CGPDFDictionaryRef
    ) -> String? {
        var namePointer: UnsafePointer<CChar>?
        guard CGPDFDictionaryGetName(dictionary, key, &namePointer),
              let namePointer else { return nil }
        return String(cString: namePointer)
    }
}

enum PDFDocumentPropertiesWriter {
    static func applying(
        _ preferences: PDFViewerPreferences,
        to data: Data
    ) -> Data {
        guard var pdf = String(data: data, encoding: .isoLatin1) else { return data }
        upgradeVersionIfNeeded(in: &pdf, for: preferences.pageLayout)

        guard let startXrefRange = pdf.range(
                of: #"startxref\s+(\d+)\s+%%EOF\s*$"#,
                options: .regularExpression
              ),
              let previousXref = firstCapture(
                in: String(pdf[startXrefRange]),
                pattern: #"startxref\s+(\d+)"#
              ).flatMap(Int.init),
              let rootReference = lastCapturePair(
                in: pdf,
                pattern: #"/Root\s+(\d+)\s+(\d+)\s+R"#
              ),
              let catalogDictionary = catalogDictionary(
                in: pdf,
                objectNumber: rootReference.0,
                generation: rootReference.1,
                before: startXrefRange.lowerBound
              ) else {
            return data
        }

        var updatedCatalog = catalogDictionary
        let additions = " /PageLayout /\(preferences.pageLayout.rawValue)"
            + " /ViewerPreferences << /Direction /\(preferences.readingDirection.rawValue) >> "
        let closingDictionaryIndex = updatedCatalog.index(updatedCatalog.endIndex, offsetBy: -2)
        updatedCatalog.insert(contentsOf: additions, at: closingDictionaryIndex)

        if !pdf.hasSuffix("\n") {
            pdf.append("\n")
        }
        let objectOffset = byteCount(of: pdf)
        pdf += "\(rootReference.0) \(rootReference.1) obj\n"
        pdf += updatedCatalog
        pdf += "\nendobj\n"
        let xrefOffset = byteCount(of: pdf)
        let size = max(
            (lastCapture(in: pdf, pattern: #"/Size\s+(\d+)"#).flatMap(Int.init) ?? 0),
            rootReference.0 + 1
        )
        let infoReference = lastCapturePair(in: pdf, pattern: #"/Info\s+(\d+)\s+(\d+)\s+R"#)
        let encryptReference = lastCapturePair(
            in: pdf,
            pattern: #"/Encrypt\s+(\d+)\s+(\d+)\s+R"#
        )
        let documentIdentifier = lastCapture(
            in: pdf,
            pattern: #"(?s)/ID\s*(\[\s*<[^>]+>\s*<[^>]+>\s*\])"#
        )
        pdf += "xref\n\(rootReference.0) 1\n"
        pdf += String(format: "%010d %05d n \n", objectOffset, rootReference.1)
        pdf += "trailer\n<< /Size \(size) /Root \(rootReference.0) \(rootReference.1) R"
        if let infoReference {
            pdf += " /Info \(infoReference.0) \(infoReference.1) R"
        }
        if let encryptReference {
            pdf += " /Encrypt \(encryptReference.0) \(encryptReference.1) R"
        }
        if let documentIdentifier {
            pdf += " /ID \(documentIdentifier)"
        }
        pdf += " /Prev \(previousXref) >>\nstartxref\n\(xrefOffset)\n%%EOF\n"

        return pdf.data(using: .isoLatin1) ?? data
    }

    private static func upgradeVersionIfNeeded(
        in pdf: inout String,
        for pageLayout: PDFPageLayout
    ) {
        guard pageLayout.requiresPDFVersion15,
              let expression = try? NSRegularExpression(pattern: #"^%PDF-(\d+)\.(\d+)"#),
              let match = expression.firstMatch(
                in: pdf,
                range: NSRange(pdf.startIndex..., in: pdf)
              ),
              let majorRange = Range(match.range(at: 1), in: pdf),
              let minorRange = Range(match.range(at: 2), in: pdf),
              let major = Int(pdf[majorRange]),
              let minor = Int(pdf[minorRange]),
              PDFVersion(major: major, minor: minor) < PDFVersion(major: 1, minor: 5),
              let headerRange = Range(match.range(at: 0), in: pdf) else { return }
        pdf.replaceSubrange(headerRange, with: "%PDF-1.5")
    }

    private static func byteCount(of value: String) -> Int {
        value.data(using: .isoLatin1)?.count ?? value.utf8.count
    }

    private static func catalogDictionary(
        in pdf: String,
        objectNumber: Int,
        generation: Int,
        before endIndex: String.Index
    ) -> String? {
        let prefix = String(pdf[..<endIndex])
        let escapedHeader = #"(?m)^\s*"# + String(objectNumber) + #"\s+"#
            + String(generation) + #"\s+obj\b"#
        guard let objectHeader = prefix.range(
            of: escapedHeader,
            options: [.regularExpression, .backwards]
        ), let dictionaryStart = prefix.range(
            of: "<<",
            range: objectHeader.upperBound..<prefix.endIndex
        )?.lowerBound else { return nil }

        var cursor = dictionaryStart
        var depth = 0
        while cursor < prefix.endIndex {
            let next = prefix.index(after: cursor)
            guard next < prefix.endIndex else { break }
            let token = prefix[cursor...next]
            if token == "<<" {
                depth += 1
                cursor = prefix.index(cursor, offsetBy: 2)
            } else if token == ">>" {
                depth -= 1
                cursor = prefix.index(cursor, offsetBy: 2)
                if depth == 0 {
                    return String(prefix[dictionaryStart..<cursor])
                }
            } else {
                cursor = next
            }
        }
        return nil
    }

    private static func firstCapture(in value: String, pattern: String) -> String? {
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(
                in: value,
                range: NSRange(value.startIndex..., in: value)
              ),
              let range = Range(match.range(at: 1), in: value) else { return nil }
        return String(value[range])
    }

    private static func lastCapture(in value: String, pattern: String) -> String? {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return nil }
        let matches = expression.matches(
            in: value,
            range: NSRange(value.startIndex..., in: value)
        )
        guard let match = matches.last,
              let range = Range(match.range(at: 1), in: value) else { return nil }
        return String(value[range])
    }

    private static func lastCapturePair(
        in value: String,
        pattern: String
    ) -> (Int, Int)? {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return nil }
        let matches = expression.matches(
            in: value,
            range: NSRange(value.startIndex..., in: value)
        )
        guard let match = matches.last,
              let firstRange = Range(match.range(at: 1), in: value),
              let secondRange = Range(match.range(at: 2), in: value),
              let first = Int(value[firstRange]),
              let second = Int(value[secondRange]) else { return nil }
        return (first, second)
    }
}

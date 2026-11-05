import Foundation
import Testing
@testable import MihirakiPDFUtility

@Suite("PDF Options and Settings Tests")
struct PDFOptionsTests {
    @Test("ThumbnailSize cases and dimension bounds")
    func thumbnailSizeDimensions() {
        #expect(ThumbnailSize.allCases.count == 3)

        let s = ThumbnailSize.s.gridDimensions
        let m = ThumbnailSize.m.gridDimensions
        let l = ThumbnailSize.l.gridDimensions

        #expect(s.min < m.min)
        #expect(m.min < l.min)
        #expect(s.max < m.max)
        #expect(m.max < l.max)
    }

    @Test("ButtonDisplayType cases")
    func buttonDisplayTypeCases() {
        #expect(ButtonDisplayType.allCases.count == 3)
        #expect(ButtonDisplayType.allCases.contains(.iconAndText))
        #expect(ButtonDisplayType.allCases.contains(.iconOnly))
        #expect(ButtonDisplayType.allCases.contains(.textOnly))
    }
}

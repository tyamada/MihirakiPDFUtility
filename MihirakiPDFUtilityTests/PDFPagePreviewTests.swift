import CoreGraphics
import Foundation
import Testing
@testable import MihirakiPDFUtility

@Suite("PDF Page Preview Tests")
struct PDFPagePreviewTests {
    @Test("next and previous index navigation bounds")
    func indexNavigationBounds() {
        // Page 0 of 5
        #expect(PDFPreviewNavigation.previousIndex(currentIndex: 0, totalPages: 5) == nil)
        #expect(PDFPreviewNavigation.nextIndex(currentIndex: 0, totalPages: 5) == 1)

        // Middle page 2 of 5
        #expect(PDFPreviewNavigation.previousIndex(currentIndex: 2, totalPages: 5) == 1)
        #expect(PDFPreviewNavigation.nextIndex(currentIndex: 2, totalPages: 5) == 3)

        // Last page 4 of 5
        #expect(PDFPreviewNavigation.previousIndex(currentIndex: 4, totalPages: 5) == 3)
        #expect(PDFPreviewNavigation.nextIndex(currentIndex: 4, totalPages: 5) == nil)
    }

    @Test("swipe navigation in LTR vs RTL")
    func swipeNavigationDirections() {
        // LTR: swipe right (positive width) goes to previous page
        let ltrPrev = PDFPreviewNavigation.swipeIndex(
            currentIndex: 2,
            totalPages: 5,
            isRTL: false,
            translationWidth: 60.0
        )
        #expect(ltrPrev == 1)

        // LTR: swipe left (negative width) goes to next page
        let ltrNext = PDFPreviewNavigation.swipeIndex(
            currentIndex: 2,
            totalPages: 5,
            isRTL: false,
            translationWidth: -60.0
        )
        #expect(ltrNext == 3)

        // RTL: swipe right (positive width) turns to next page (manga reading order)
        let rtlNext = PDFPreviewNavigation.swipeIndex(
            currentIndex: 2,
            totalPages: 5,
            isRTL: true,
            translationWidth: 60.0
        )
        #expect(rtlNext == 3)

        // RTL: swipe left (negative width) returns to previous page
        let rtlPrev = PDFPreviewNavigation.swipeIndex(
            currentIndex: 2,
            totalPages: 5,
            isRTL: true,
            translationWidth: -60.0
        )
        #expect(rtlPrev == 1)

        // Under threshold: nil
        let underThreshold = PDFPreviewNavigation.swipeIndex(
            currentIndex: 2,
            totalPages: 5,
            isRTL: false,
            translationWidth: 30.0
        )
        #expect(underThreshold == nil)
    }

    @Test("clamped scale bounds to 1.0 ... 5.0")
    func clampedScaleBounds() {
        #expect(PDFPreviewNavigation.clampedScale(0.5) == 1.0)
        #expect(PDFPreviewNavigation.clampedScale(1.0) == 1.0)
        #expect(PDFPreviewNavigation.clampedScale(3.2) == 3.2)
        #expect(PDFPreviewNavigation.clampedScale(5.0) == 5.0)
        #expect(PDFPreviewNavigation.clampedScale(8.5) == 5.0)
    }
}

import Testing
import Foundation
import CoreGraphics
import PDFKit
@testable import MihirakiPDFUtility

@Suite("PDF Page Views and Accessibility Models")
struct PDFPageViewsTests {

    @Test("ThumbnailAction has complete titles and system images")
    func thumbnailActionProperties() {
        for action in ThumbnailAction.allCases {
            #expect(!action.systemImage.isEmpty)
            #expect(action.id == action)
        }
    }

    @Test("SpreadDisplayPage and SpreadDisplayRow initialize correctly")
    func spreadDisplayModels() {
        let pageItem0 = PDFPageItem(page: PDFPage())
        let pageItem1 = PDFPageItem(page: PDFPage())

        let leftPage = SpreadDisplayPage(index: 0, item: pageItem0)
        let rightPage = SpreadDisplayPage(index: 1, item: pageItem1)

        let row = SpreadDisplayRow(id: pageItem0.id, leftPage: leftPage, rightPage: rightPage)
        #expect(row.id == pageItem0.id)
        #expect(row.leftPage?.index == 0)
        #expect(row.rightPage?.index == 1)
        #expect(row.leftPage?.id == pageItem0.id)
    }

    @Test("PDFPreviewNavigation scale clamping")
    func previewScaleClamping() {
        #expect(PDFPreviewNavigation.clampedScale(0.5) == 1.0)
        #expect(PDFPreviewNavigation.clampedScale(2.5) == 2.5)
        #expect(PDFPreviewNavigation.clampedScale(10.0) == 5.0)
    }

    @Test("PDFPreviewNavigation previous and next indices")
    func previewNavigationIndices() {
        #expect(PDFPreviewNavigation.previousIndex(currentIndex: 0, totalPages: 5) == nil)
        #expect(PDFPreviewNavigation.previousIndex(currentIndex: 2, totalPages: 5) == 1)
        #expect(PDFPreviewNavigation.nextIndex(currentIndex: 4, totalPages: 5) == nil)
        #expect(PDFPreviewNavigation.nextIndex(currentIndex: 2, totalPages: 5) == 3)
    }

    @Test("PDFPreviewNavigation swipe logic with RTL and LTR")
    func previewSwipeNavigation() {
        // LTR: swipe right (positive translation) -> previous page
        let ltrPrev = PDFPreviewNavigation.swipeIndex(
            currentIndex: 2,
            totalPages: 5,
            isRTL: false,
            translationWidth: 100
        )
        #expect(ltrPrev == 1)

        // LTR: swipe left (negative translation) -> next page
        let ltrNext = PDFPreviewNavigation.swipeIndex(
            currentIndex: 2,
            totalPages: 5,
            isRTL: false,
            translationWidth: -100
        )
        #expect(ltrNext == 3)

        // RTL: swipe right (positive translation) -> next page
        let rtlNext = PDFPreviewNavigation.swipeIndex(
            currentIndex: 2,
            totalPages: 5,
            isRTL: true,
            translationWidth: 100
        )
        #expect(rtlNext == 3)

        // RTL: swipe left (negative translation) -> previous page
        let rtlPrev = PDFPreviewNavigation.swipeIndex(
            currentIndex: 2,
            totalPages: 5,
            isRTL: true,
            translationWidth: -100
        )
        #expect(rtlPrev == 1)

        // Below threshold -> nil
        let ignored = PDFPreviewNavigation.swipeIndex(
            currentIndex: 2,
            totalPages: 5,
            isRTL: false,
            translationWidth: 30
        )
        #expect(ignored == nil)
    }
}

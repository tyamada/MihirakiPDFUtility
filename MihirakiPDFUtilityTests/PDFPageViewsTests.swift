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

    @Test("MainViewMode all cases, identifiers, and symbols")
    func mainViewModeCases() {
        #expect(MainViewMode.allCases.count == 4)
        #expect(MainViewMode.allCases.contains(.auto))
        #expect(MainViewMode.allCases.contains(.list))
        #expect(MainViewMode.allCases.contains(.thumbnails))
        #expect(MainViewMode.allCases.contains(.spread))
        for mode in MainViewMode.allCases {
            #expect(mode.id == mode)
            #expect(!mode.systemImage.isEmpty)
        }
    }

    @Test("MainViewMode resolution for Mac and iPad always selects thumbnails")
    @MainActor
    func mainViewModeResolvedPadOrMac() {
        let portrait = CGSize(width: 400, height: 800)
        let landscape = CGSize(width: 800, height: 400)

        #expect(MainViewMode.auto.resolved(for: portrait, isPadOrMac: true) == .thumbnails)
        #expect(MainViewMode.auto.resolved(for: landscape, isPadOrMac: true) == .thumbnails)
    }

    @Test("MainViewMode resolution for iPhone and iPhone Duo adapts by orientation and size")
    @MainActor
    func mainViewModeResolvedPhoneAndDuo() {
        let portrait = CGSize(width: 393, height: 852)
        let landscape = CGSize(width: 852, height: 393)
        let square = CGSize(width: 600, height: 600)
        let unmeasured = CGSize.zero

        // Vertical / portrait -> list
        #expect(MainViewMode.auto.resolved(for: portrait, isPadOrMac: false) == .list)
        // Horizontal / landscape -> thumbnails
        #expect(MainViewMode.auto.resolved(for: landscape, isPadOrMac: false) == .thumbnails)
        // Square / width >= height -> thumbnails
        #expect(MainViewMode.auto.resolved(for: square, isPadOrMac: false) == .thumbnails)
        // Zero size fallback -> list
        #expect(MainViewMode.auto.resolved(for: unmeasured, isPadOrMac: false) == .list)
    }

    @Test("Explicit MainViewMode selection is preserved regardless of size or device")
    @MainActor
    func mainViewModeExplicitPreserved() {
        let portrait = CGSize(width: 393, height: 852)
        let landscape = CGSize(width: 852, height: 393)

        #expect(MainViewMode.list.resolved(for: landscape, isPadOrMac: true) == .list)
        #expect(MainViewMode.list.resolved(for: landscape, isPadOrMac: false) == .list)
        #expect(MainViewMode.thumbnails.resolved(for: portrait, isPadOrMac: false) == .thumbnails)
        #expect(MainViewMode.spread.resolved(for: portrait, isPadOrMac: false) == .spread)
    }
}

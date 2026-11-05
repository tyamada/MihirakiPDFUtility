import CoreGraphics
import Foundation
import PDFKit

public enum SplitDirection: String, CaseIterable, Identifiable, Sendable {
    case vertical = "vertical"      // 左右2分割（縦に切る）
    case horizontal = "horizontal"  // 上下2分割（横に切る）

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .vertical:
            return String(localized: "Split Left / Right (Vertical)")
        case .horizontal:
            return String(localized: "Split Top / Bottom (Horizontal)")
        }
    }
}

public enum PDFPageGeometry {
    /// Computes the two cropped bounding boxes in PDF coordinate space for a page,
    /// matching the visually perceived left/right or top/bottom halves based on rotation.
    public static func splitBoxes(
        for bounds: CGRect,
        rotation: Int,
        direction: SplitDirection
    ) -> (first: CGRect, second: CGRect) {
        let normalizedRotation = ((rotation % 360) + 360) % 360
        let x0 = bounds.origin.x
        let y0 = bounds.origin.y
        let w = bounds.width
        let h = bounds.height

        switch direction {
        case .vertical:
            // Visually split into Left and Right
            switch normalizedRotation {
            case 0:
                let left = CGRect(x: x0, y: y0, width: w / 2, height: h)
                let right = CGRect(x: x0 + w / 2, y: y0, width: w / 2, height: h)
                return (left, right)
            case 90:
                // Rotated 90 deg clockwise: visual left is bottom half in PDF coords, visual right is top half
                let visualLeft = CGRect(x: x0, y: y0, width: w, height: h / 2)
                let visualRight = CGRect(x: x0, y: y0 + h / 2, width: w, height: h / 2)
                return (visualLeft, visualRight)
            case 180:
                // Rotated 180 deg: visual left is right half, visual right is left half
                let visualLeft = CGRect(x: x0 + w / 2, y: y0, width: w / 2, height: h)
                let visualRight = CGRect(x: x0, y: y0, width: w / 2, height: h)
                return (visualLeft, visualRight)
            case 270:
                // Rotated 270 deg clockwise: visual left is top half, visual right is bottom half
                let visualLeft = CGRect(x: x0, y: y0 + h / 2, width: w, height: h / 2)
                let visualRight = CGRect(x: x0, y: y0, width: w, height: h / 2)
                return (visualLeft, visualRight)
            default:
                let left = CGRect(x: x0, y: y0, width: w / 2, height: h)
                let right = CGRect(x: x0 + w / 2, y: y0, width: w / 2, height: h)
                return (left, right)
            }

        case .horizontal:
            // Visually split into Top and Bottom
            switch normalizedRotation {
            case 0:
                let visualTop = CGRect(x: x0, y: y0 + h / 2, width: w, height: h / 2)
                let visualBottom = CGRect(x: x0, y: y0, width: w, height: h / 2)
                return (visualTop, visualBottom)
            case 90:
                // Rotated 90 deg clockwise: visual top is left half in PDF coords, visual bottom is right half
                let visualTop = CGRect(x: x0, y: y0, width: w / 2, height: h)
                let visualBottom = CGRect(x: x0 + w / 2, y: y0, width: w / 2, height: h)
                return (visualTop, visualBottom)
            case 180:
                // Rotated 180 deg: visual top is bottom half, visual bottom is top half
                let visualTop = CGRect(x: x0, y: y0, width: w, height: h / 2)
                let visualBottom = CGRect(x: x0, y: y0 + h / 2, width: w, height: h / 2)
                return (visualTop, visualBottom)
            case 270:
                // Rotated 270 deg: visual top is right half, visual bottom is left half
                let visualTop = CGRect(x: x0 + w / 2, y: y0, width: w / 2, height: h)
                let visualBottom = CGRect(x: x0, y: y0, width: w / 2, height: h)
                return (visualTop, visualBottom)
            default:
                let visualTop = CGRect(x: x0, y: y0 + h / 2, width: w, height: h / 2)
                let visualBottom = CGRect(x: x0, y: y0, width: w, height: h / 2)
                return (visualTop, visualBottom)
            }
        }
    }

    /// Splits a PDFPage into two new PDFPage instances.
    /// Order of returned tuple: (page1, page2)
    /// - For vertical split: if isRTL is true, page1 is Right half, page2 is Left half; otherwise page1 is Left, page2 is Right.
    /// - For horizontal split: page1 is Top half, page2 is Bottom half regardless of isRTL.
    public static func split(
        page: PDFPage,
        direction: SplitDirection,
        isRTL: Bool
    ) -> (PDFPage, PDFPage)? {
        let cropBounds = page.bounds(for: .cropBox)
        let bounds = cropBounds.width > 0 && cropBounds.height > 0
            ? cropBounds
            : page.bounds(for: .mediaBox)

        guard bounds.width > 0, bounds.height > 0 else { return nil }

        guard let copy1 = page.copy() as? PDFPage,
              let copy2 = page.copy() as? PDFPage else {
            return nil
        }

        let (boxA, boxB) = splitBoxes(for: bounds, rotation: page.rotation, direction: direction)

        switch direction {
        case .vertical:
            if isRTL {
                // RTL: 1st page is visual right (boxB), 2nd page is visual left (boxA)
                copy1.setBounds(boxB, for: .cropBox)
                copy2.setBounds(boxA, for: .cropBox)
            } else {
                // LTR: 1st page is visual left (boxA), 2nd page is visual right (boxB)
                copy1.setBounds(boxA, for: .cropBox)
                copy2.setBounds(boxB, for: .cropBox)
            }
        case .horizontal:
            // Top to bottom
            copy1.setBounds(boxA, for: .cropBox)
            copy2.setBounds(boxB, for: .cropBox)
        }

        return (copy1, copy2)
    }

    /// Calculates a new cropped bounding box with uniform margins (0.0 ... 0.40).
    public static func cropBox(
        for baseBounds: CGRect,
        margin: CGFloat
    ) -> CGRect {
        let clampedMargin = max(0.0, min(0.40, margin))
        guard clampedMargin > 0 else { return baseBounds }

        let mx = baseBounds.width * clampedMargin
        let my = baseBounds.height * clampedMargin

        return CGRect(
            x: baseBounds.origin.x + mx,
            y: baseBounds.origin.y + my,
            width: baseBounds.width - 2 * mx,
            height: baseBounds.height - 2 * my
        )
    }

    /// Applies uniform margin crop (0% to 40%) to the given page.
    public static func applyCrop(
        margin: CGFloat,
        to page: PDFPage
    ) {
        let mediaBox = page.bounds(for: .mediaBox)
        guard mediaBox.width > 0, mediaBox.height > 0 else { return }

        let newCropBox = cropBox(for: mediaBox, margin: margin)
        page.setBounds(newCropBox, for: .cropBox)
    }
}

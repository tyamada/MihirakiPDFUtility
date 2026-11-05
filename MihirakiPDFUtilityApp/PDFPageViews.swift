import PDFKit
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#endif

// MARK: - Wrapping Layout

struct WrappingHStack: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    init(horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 8) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let result = layoutSubviews(subviews, availableWidth: proposal.width ?? .infinity)
        return CGSize(
            width: proposal.width ?? result.width,
            height: result.height
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = layoutSubviews(subviews, availableWidth: bounds.width)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                anchor: .topLeading,
                proposal: .unspecified
            )
        }
    }

    private func layoutSubviews(
        _ subviews: Subviews,
        availableWidth: CGFloat
    ) -> (positions: [CGPoint], width: CGFloat, height: CGFloat) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > 0, currentX + size.width > availableWidth {
                currentX = 0
                currentY += rowHeight + verticalSpacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            usedWidth = max(usedWidth, currentX + size.width)
            currentX += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        return (
            positions,
            usedWidth,
            subviews.isEmpty ? 0 : currentY + rowHeight
        )
    }
}

// MARK: - Drag & Drop Delegate

struct ThumbnailPageDropDelegate: DropDelegate {
    let destinationID: PDFPageItem.ID?
    @Binding var draggedPageID: PDFPageItem.ID?
    let move: ([PDFPageItem.ID], PDFPageItem.ID?) -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedPageID else { return false }
        move([draggedPageID], destinationID)
        self.draggedPageID = nil
        return true
    }
}

// MARK: - Spread Display Models

struct SpreadDisplayPage: Identifiable {
    let index: Int
    let item: PDFPageItem

    var id: PDFPageItem.ID { item.id }
}

struct SpreadDisplayRow: Identifiable {
    let id: PDFPageItem.ID
    let leftPage: SpreadDisplayPage?
    let rightPage: SpreadDisplayPage?
}

// MARK: - Thumbnail Action Types

enum ThumbnailAction: String, CaseIterable, Identifiable, Sendable {
    case open
    case save
    case undo
    case redo
    case insertPDF
    case insertBlankPage
    case delete
    case moveEarlier
    case moveLater
    case rotateLeft
    case rotateRight
    case properties
    case rightBinding
    case rightBindingWithCover
    case splitPages
    case cropPages

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .open: "Open"
        case .save: "Save"
        case .undo: "Undo"
        case .redo: "Redo"
        case .insertPDF: "Insert PDF"
        case .insertBlankPage: "Insert Same-Size Blank Page After"
        case .delete: "Delete"
        case .moveEarlier: "Move Earlier"
        case .moveLater: "Move Later"
        case .rotateLeft: "Rotate Left"
        case .rotateRight: "Rotate Right"
        case .properties: "Properties"
        case .rightBinding: "Right Binding"
        case .rightBindingWithCover: "Right Binding with Cover"
        case .splitPages: "Split Pages"
        case .cropPages: "Crop Pages"
        }
    }

    var systemImage: String {
        switch self {
        case .open: "folder"
        case .save: "square.and.arrow.down"
        case .undo: "arrow.uturn.backward"
        case .redo: "arrow.uturn.forward"
        case .insertPDF, .insertBlankPage: "doc.badge.plus"
        case .delete: "trash"
        case .moveEarlier: "arrow.left"
        case .moveLater: "arrow.right"
        case .rotateLeft: "rotate.left"
        case .rotateRight: "rotate.right"
        case .properties: "doc.text.magnifyingglass"
        case .rightBinding: "book.closed"
        case .rightBindingWithCover: "book.closed.fill"
        case .splitPages: "rectangle.split.2x1"
        case .cropPages: "crop"
        }
    }
}

// MARK: - Thumbnail Cell

struct PDFPageThumbnail: View {
    let pageNumber: Int
    let page: PDFPage
    let isSelected: Bool
    var onToggleSelection: (() -> Void)? = nil
    var onPreview: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            thumbnailImage
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .aspectRatio(0.72, contentMode: .fit)
                .background(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isSelected ? Color.accentColor : Color.secondary.opacity(0.25),
                            lineWidth: isSelected ? 4 : 1
                        )
                }
                .clipShape(.rect(cornerRadius: 6))
                .shadow(color: .black.opacity(0.16), radius: 4, y: 2)

            Text("Page \(pageNumber)")
                .font(.callout.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Page \(pageNumber)"))
        .accessibilityValue(isSelected ? String(localized: "Selected") : String(localized: "Not Selected"))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
        .accessibilityHint(String(localized: "Double-tap to select. Double-tap twice or use actions to preview."))
        .accessibilityAction(named: Text("Toggle Selection")) {
            onToggleSelection?()
        }
        .accessibilityAction(named: Text("Preview")) {
            onPreview?()
        }
    }

    private var thumbnailImage: Image {
#if os(macOS)
        Image(nsImage: page.thumbnail(of: CGSize(width: 360, height: 500), for: .cropBox))
#else
        Image(uiImage: page.thumbnail(of: CGSize(width: 360, height: 500), for: .cropBox))
#endif
    }
}

// MARK: - Row Cell

struct PDFPageRow: View {
    let pageNumber: Int
    let page: PDFPage
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            thumbnailImage
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 96)
                .background(.white)
                .shadow(radius: 2)
                .accessibilityHidden(true)

            Text("Page \(pageNumber)")
                .font(.headline)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Page \(pageNumber)"))
        .accessibilityValue(isSelected ? String(localized: "Selected") : "")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var thumbnailImage: Image {
#if os(macOS)
        Image(nsImage: page.thumbnail(of: CGSize(width: 120, height: 160), for: .cropBox))
#else
        Image(uiImage: page.thumbnail(of: CGSize(width: 120, height: 160), for: .cropBox))
#endif
    }
}

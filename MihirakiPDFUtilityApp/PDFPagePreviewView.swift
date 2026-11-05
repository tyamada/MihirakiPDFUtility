import Foundation
import PDFKit
import SwiftUI

struct PDFPagePreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let pages: [PDFPageItem]
    @Binding var selectedPageID: PDFPageItem.ID?
    var isRTL: Bool = false

    @State private var currentIndex: Int = 0
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureOffset: CGSize = .zero

    init(
        pages: [PDFPageItem],
        selectedPageID: Binding<PDFPageItem.ID?>,
        isRTL: Bool = false
    ) {
        self.pages = pages
        self._selectedPageID = selectedPageID
        self.isRTL = isRTL
        let initialIndex = pages.firstIndex { $0.id == selectedPageID.wrappedValue } ?? 0
        self._currentIndex = State(initialValue: initialIndex)
    }

    private var currentPage: PDFPageItem? {
        guard pages.indices.contains(currentIndex) else { return nil }
        return pages[currentIndex]
    }

    private var currentScale: CGFloat {
        PDFPreviewNavigation.clampedScale(scale * gestureScale)
    }

    private var currentOffset: CGSize {
        if currentScale <= 1.0 {
            return .zero
        }
        return CGSize(
            width: offset.width + gestureOffset.width,
            height: offset.height + gestureOffset.height
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let item = currentPage {
                    previewImageView(for: item.page)
                        .scaleEffect(currentScale)
                        .offset(currentOffset)
                        .gesture(zoomAndPanGesture)
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    offset = .zero
                                } else {
                                    scale = 2.5
                                }
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(String(localized: "Page \(currentIndex + 1) of \(pages.count)"))
                        .accessibilityValue(String(format: String(localized: "Zoom %.1fx"), currentScale))
                        .accessibilityHint(String(localized: "Double-tap to zoom. Swipe left or right to change pages."))
                        .accessibilityAdjustableAction { direction in
                            switch direction {
                            case .increment:
                                scale = min(5.0, scale + 0.5)
                            case .decrement:
                                scale = max(1.0, scale - 0.5)
                                if scale <= 1.0 {
                                    offset = .zero
                                }
                            @unknown default:
                                break
                            }
                        }
                } else {
                    ContentUnavailableView(
                        "No Page Selected",
                        systemImage: "doc",
                        description: Text("Select a page from the document to preview.")
                    )
                    .foregroundStyle(.white)
                }

                // Floating navigation bar at bottom
                VStack {
                    Spacer()
                    bottomNavigationControls
                }
            }
            .navigationTitle(pageCounterText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Close")
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    if currentScale > 1.0 {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                scale = 1.0
                                offset = .zero
                            }
                        } label: {
                            Label("Reset Zoom", systemImage: "arrow.down.right.and.arrow.up.left")
                        }
                        .accessibilityLabel("Reset Zoom")
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onChange(of: currentIndex) { _, newIndex in
            if pages.indices.contains(newIndex) {
                selectedPageID = pages[newIndex].id
            }
            withAnimation {
                scale = 1.0
                offset = .zero
            }
        }
    }

    private var pageCounterText: String {
        guard !pages.isEmpty else { return "" }
        let current = currentIndex + 1
        let total = pages.count
        return String(localized: "Page \(current) / \(total)")
    }

    private var bottomNavigationControls: some View {
        HStack(spacing: 24) {
            Button {
                goToPreviousPage()
            } label: {
                Image(systemName: isRTL ? "chevron.right" : "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Previous Page")
            .disabled(!canGoToPreviousPage)
            .opacity(canGoToPreviousPage ? 1.0 : 0.3)

            Text("\(currentIndex + 1) / \(pages.count)")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
                .accessibilityLabel(String(localized: "Page \(currentIndex + 1) of \(pages.count)"))

            Button {
                goToNextPage()
            } label: {
                Image(systemName: isRTL ? "chevron.left" : "chevron.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Next Page")
            .disabled(!canGoToNextPage)
            .opacity(canGoToNextPage ? 1.0 : 0.3)
        }
        .padding(.bottom, 20)
    }

    private var canGoToPreviousPage: Bool {
        PDFPreviewNavigation.previousIndex(currentIndex: currentIndex, totalPages: pages.count) != nil
    }

    private var canGoToNextPage: Bool {
        PDFPreviewNavigation.nextIndex(currentIndex: currentIndex, totalPages: pages.count) != nil
    }

    private func goToPreviousPage() {
        guard let prev = PDFPreviewNavigation.previousIndex(currentIndex: currentIndex, totalPages: pages.count) else { return }
        withAnimation {
            currentIndex = prev
        }
    }

    private func goToNextPage() {
        guard let next = PDFPreviewNavigation.nextIndex(currentIndex: currentIndex, totalPages: pages.count) else { return }
        withAnimation {
            currentIndex = next
        }
    }

    private var zoomAndPanGesture: some Gesture {
        let magnification = MagnificationGesture()
            .updating($gestureScale) { current, state, _ in
                state = current
            }
            .onEnded { finalScale in
                let newScale = PDFPreviewNavigation.clampedScale(scale * finalScale)
                scale = newScale
                if scale <= 1.0 {
                    offset = .zero
                }
            }

        let drag = DragGesture()
            .updating($gestureOffset) { current, state, _ in
                if scale > 1.0 {
                    state = current.translation
                }
            }
            .onEnded { value in
                if scale > 1.0 {
                    offset = CGSize(
                        width: offset.width + value.translation.width,
                        height: offset.height + value.translation.height
                    )
                } else {
                    // Swipe page navigation when not zoomed
                    if let target = PDFPreviewNavigation.swipeIndex(
                        currentIndex: currentIndex,
                        totalPages: pages.count,
                        isRTL: isRTL,
                        translationWidth: value.translation.width
                    ) {
                        withAnimation {
                            currentIndex = target
                        }
                    }
                }
            }

        return SimultaneousGesture(magnification, drag)
    }

    @ViewBuilder
    private func previewImageView(for page: PDFPage) -> some View {
        let bounds = page.bounds(for: .cropBox)
        let scaleFactor = min(3.0, 2400.0 / max(max(bounds.width, bounds.height), 1.0))
        let targetSize = CGSize(
            width: max(bounds.width * scaleFactor, 100),
            height: max(bounds.height * scaleFactor, 100)
        )

#if os(macOS)
        let image = page.thumbnail(of: targetSize, for: .cropBox)
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
            .padding(16)
#else
        let image = page.thumbnail(of: targetSize, for: .cropBox)
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
            .padding(16)
#endif
    }
}

enum PDFPreviewNavigation {
    static func nextIndex(currentIndex: Int, totalPages: Int) -> Int? {
        guard currentIndex < totalPages - 1 else { return nil }
        return currentIndex + 1
    }

    static func previousIndex(currentIndex: Int, totalPages: Int) -> Int? {
        guard currentIndex > 0 else { return nil }
        return currentIndex - 1
    }

    static func swipeIndex(
        currentIndex: Int,
        totalPages: Int,
        isRTL: Bool,
        translationWidth: CGFloat,
        threshold: CGFloat = 50.0
    ) -> Int? {
        if translationWidth > threshold {
            return isRTL ? nextIndex(currentIndex: currentIndex, totalPages: totalPages)
                         : previousIndex(currentIndex: currentIndex, totalPages: totalPages)
        } else if translationWidth < -threshold {
            return isRTL ? previousIndex(currentIndex: currentIndex, totalPages: totalPages)
                         : nextIndex(currentIndex: currentIndex, totalPages: totalPages)
        }
        return nil
    }

    static func clampedScale(_ targetScale: CGFloat) -> CGFloat {
        max(1.0, min(5.0, targetScale))
    }
}

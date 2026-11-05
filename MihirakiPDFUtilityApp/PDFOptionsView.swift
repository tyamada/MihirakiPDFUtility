import SwiftUI

enum ThumbnailSize: String, CaseIterable, Identifiable, Sendable {
    case s = "S"
    case m = "M"
    case l = "L"

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .s: "Small (S)"
        case .m: "Medium (M)"
        case .l: "Large (L)"
        }
    }

    var gridDimensions: (min: CGFloat, max: CGFloat) {
        switch self {
        case .s: (90, 130)
        case .m: (140, 220)
        case .l: (220, 320)
        }
    }
}

enum ButtonDisplayType: String, CaseIterable, Identifiable, Sendable {
    case iconAndText = "iconAndText"
    case iconOnly = "iconOnly"
    case textOnly = "textOnly"

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .iconAndText: "Icon and Text"
        case .iconOnly: "Icon Only"
        case .textOnly: "Text Only"
        }
    }
}

struct PDFOptionsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("thumbnailSize") private var thumbnailSize: ThumbnailSize = .m
    @AppStorage("buttonDisplayType") private var buttonDisplayType: ButtonDisplayType = .iconAndText

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Thumbnail Size")) {
                    Picker("Size", selection: $thumbnailSize) {
                        ForEach(ThumbnailSize.allCases) { size in
                            Text(size.title).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Button Display")) {
                    Picker("Style", selection: $buttonDisplayType) {
                        ForEach(ButtonDisplayType.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Options")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 380, minHeight: 320)
    }
}

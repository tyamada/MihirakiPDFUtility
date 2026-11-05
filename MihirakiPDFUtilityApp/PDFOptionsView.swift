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
    @AppStorage("buttonDisplayType") private var buttonDisplayType: ButtonDisplayType = .iconOnly
    @State private var iconManager = AppIconManager.shared

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

#if os(iOS)
                if iconManager.supportsAlternateIcons {
                    Section(header: Text("App Icon")) {
                        ForEach(AppIconOption.allCases) { option in
                            Button {
                                Task {
                                    await iconManager.selectIcon(option)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(option.previewAssetName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 44, height: 44)
                                        .clipShape(.rect(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                        )

                                    Text(option.displayName)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if iconManager.currentIcon == option {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
#endif
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

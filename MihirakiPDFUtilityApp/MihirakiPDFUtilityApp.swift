import SwiftUI

@main
struct MihirakiPDFUtilityApp: App {
    @State private var model = PDFEditorModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
#if os(macOS)
        .defaultSize(width: 1100, height: 760)
#endif
    }
}

import SwiftUI

@main
struct MihirakiPDFUtilityApp: App {
    @State private var model = PDFEditorModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
}

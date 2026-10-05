import SwiftUI

@main
struct MihirakiPDFUtilityApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = PDFEditorModel()

    init() {
        Task {
            await DiagnosticLogStore.shared.startSession()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
        .onChange(of: scenePhase) { _, newPhase in
            Task {
                await DiagnosticLogStore.shared.handleScenePhase(newPhase)
            }
        }
#if os(macOS)
        .defaultSize(width: 1100, height: 760)
#endif
    }
}

import SwiftUI

@main
struct MihirakiPDFUtilityApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = PDFEditorModel()
    @State private var diagnostics = DiagnosticsRunner(store: .live)

    init() {
        PDFCacheCleanup.migrateLegacyLogsIfNeeded()
        PDFCacheCleanup.cleanupStalePdfCopies()

        Task {
            await DiagnosticLogStore.shared.startSession()
            do {
                try await DiagnosticWorkspace.shared.recoverAbandonedRuns()
            } catch {
                await DiagnosticLogStore.shared.record(
                    .diagnosticCleanupFailed, category: .performance, outcome: .failure
                )
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .environment(diagnostics)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background { diagnostics.cancel() }
            Task {
                await DiagnosticLogStore.shared.handleScenePhase(newPhase)
            }
        }
#if os(macOS)
        .defaultSize(width: 1100, height: 760)
#endif
    }
}

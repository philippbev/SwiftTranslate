import SwiftUI
import Translation

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 0) {
            // MARK: - Language Bar
            LanguageBarView()
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            Divider()

            // MARK: - Translation Panels
            HStack(spacing: 0) {
                // Source
                TranslationPanelView(
                    text: $appState.sourceText,
                    placeholder: "Text eingeben…",
                    isEditable: true,
                    language: appState.detectedLanguage
                )

                Divider()

                // Target
                TranslationPanelView(
                    text: $appState.translatedText,
                    placeholder: appState.isTranslating ? "Übersetze…" : "Übersetzung",
                    isEditable: false,
                    language: appState.targetLanguage
                )
                .overlay {
                    if appState.isTranslating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            Divider()

            // MARK: - Bottom Bar
            BottomBarView()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        // Apple Translation API hook — must be on a View
        .translationTask(appState.translationService.configuration) { session in
            await appState.translationService.performTranslation(session: session)
        }
        .alert("Fehler", isPresented: Binding(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK") { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .frame(width: 700, height: 420)
}

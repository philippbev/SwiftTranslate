import SwiftUI
import Translation

/// Compact popover shown when clicking the Menu Bar icon.
struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 0) {
            // Input
            TextEditor(text: $appState.sourceText)
                .font(.body)
                .frame(height: 80)
                .padding(8)
                .scrollContentBackground(.hidden)
                .overlay(alignment: .topLeading) {
                    if appState.sourceText.isEmpty {
                        Text("Text eingeben…")
                            .foregroundStyle(.tertiary)
                            .font(.body)
                            .padding(12)
                            .allowsHitTesting(false)
                    }
                }

            Divider()

            // Output
            ScrollView {
                Text(appState.translatedText.isEmpty
                     ? (appState.isTranslating ? "Übersetze…" : "Übersetzung erscheint hier")
                     : appState.translatedText)
                    .foregroundStyle(appState.translatedText.isEmpty ? .tertiary : .primary)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .textSelection(.enabled)
            }
            .frame(height: 80)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            Divider()

            // Actions
            HStack {
                Button("Öffnen") {
                    openWindow(id: "main")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)

                Spacer()

                if appState.isTranslating {
                    ProgressView().scaleEffect(0.7)
                }

                Button("Übersetzen") {
                    appState.triggerTranslation()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(appState.sourceText.isEmpty || appState.isTranslating)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 320)
        // Translation task must also be attached here for menu bar usage
        .translationTask(appState.translationService.configuration) { session in
            await appState.translationService.performTranslation(session: session)
        }
    }
}

#Preview {
    MenuBarView()
        .environment(AppState())
}

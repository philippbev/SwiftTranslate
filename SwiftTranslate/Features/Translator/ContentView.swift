import SwiftUI
import Translation

@available(macOS 15.0, *)
struct ContentView: View {
    @Environment(AppState.self) private var state

    // Persist split position across launches
    @SceneStorage("window.splitFraction") private var splitFraction: Double = 0.5
    @State private var showHistory = false

    var body: some View {
        @Bindable var state = state
        GeometryReader { geo in
            HSplitView {
                // Source pane
                VStack(spacing: 0) {
                    paneHeader(lang: state.sourceLang, detected: state.detectedLang, isSource: true)
                    Divider()
                    MultilineTextField(
                        text: $state.sourceText,
                        placeholder: L("input.placeholder"),
                        isEditable: true,
                        onPaste: {
                            if state.autoTranslateOnPaste && !state.sourceText.isEmpty {
                                state.translate()
                            }
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Divider()
                    sourceFooter(state: state)
                }
                .frame(minWidth: 200, idealWidth: geo.size.width * splitFraction)

                // Target pane
                VStack(spacing: 0) {
                    if showHistory {
                        paneHeader(lang: state.targetLang, detected: nil, isSource: false)
                        Divider()
                        HistoryView(onSelect: { entry in
                            state.sourceText = entry.source
                            state.translatedText = entry.translation
                            state.sourceLang = entry.from
                            state.targetLang = entry.to
                            showHistory = false
                        })
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        paneHeader(lang: state.targetLang, detected: nil, isSource: false)
                        Divider()
                        ZStack {
                            MultilineTextField(
                                text: $state.translatedText,
                                placeholder: L("output.placeholder"),
                                isEditable: false
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                            if state.isTranslating { ProgressView() }
                        }
                        Divider()
                        targetFooter(state: state)
                    }
                }
                .frame(minWidth: 200)
            }
        }
        .toolbar {
            // Language pair display
            ToolbarItem(placement: .navigation) {
                Text("\(state.sourceLang.flag) \(state.sourceLang.displayName)  →  \(state.targetLang.flag) \(state.targetLang.displayName)")
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            ToolbarItem(placement: .automatic) {
                Button { state.swap() } label: {
                    Image(systemName: "arrow.left.arrow.right")
                    Text(L("swap.languages"))
                }
                .help(L("swap.languages"))
                .accessibilityLabel(L("swap.languages"))
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showHistory.toggle() }
                } label: {
                    Image(systemName: showHistory ? "xmark" : "clock")
                    Text(showHistory ? L("close") : L("history"))
                }
                .help(showHistory ? L("close") : L("history"))
                .accessibilityLabel(showHistory ? L("close") : L("history"))
            }
            ToolbarItem(placement: .primaryAction) {
                Button { state.translate() } label: {
                    Image(systemName: "arrow.trianglehead.turn.up.right.circle.fill")
                    Text(L("translate"))
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(state.sourceText.isEmpty || state.isTranslating)
                .accessibilityLabel(L("translate"))
                .accessibilityHint(L("a11y.translate.hint"))
            }
        }
        .translationTask(state.translationConfig) { session in
            do {
                let r = try await session.translate(state.sourceText)
                state.translationDidFinish(r.targetText)
            } catch {
                state.translationDidFail(error)
            }
        }
        .onChange(of: state.sourceText) { _, _ in
            state.updateDetectedLang()
        }
        .alert(L("error.title"), isPresented: Binding(
            get: { state.errorMessage != nil },
            set: { if !$0 { state.errorMessage = nil } }
        )) {
            Button(L("ok")) { state.errorMessage = nil }
        } message: {
            Text(state.errorMessage ?? "")
        }
        .frame(minWidth: 500, minHeight: 320)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func paneHeader(lang: SupportedLanguage, detected: SupportedLanguage?, isSource: Bool) -> some View {
        let display = detected ?? lang
        HStack {
            Text("\(display.flag) \(display.displayName)")
                .font(.subheadline).fontWeight(.semibold)
            if isSource, detected != nil {
                Text(L("detected"))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isSource
            ? String(format: L("a11y.sourcelang"), display.displayName)
            : String(format: L("a11y.targetlang"), display.displayName))
    }

    @ViewBuilder
    private func sourceFooter(state: AppState) -> some View {
        HStack {
            if !state.sourceText.isEmpty {
                let count = state.sourceText.count
                Text("\(count) / 500")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(count > 500 ? .red : count > 400 ? .orange : Color.secondary.opacity(0.5))
                    .accessibilityLabel(String(format: L("a11y.charcount"), count))
            }
            Spacer()
            Button { state.clear() } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(L("clear"))
            .accessibilityLabel(L("clear"))
            .disabled(state.sourceText.isEmpty && state.translatedText.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func targetFooter(state: AppState) -> some View {
        HStack {
            if !state.translatedText.isEmpty && !state.isTranslating {
                Label(L("copied"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                    .transition(.opacity)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

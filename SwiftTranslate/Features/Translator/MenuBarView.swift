import SwiftUI
import Translation

@available(macOS 15.0, *)
struct MenuBarView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Group {
            if state.onboardingCompleted {
                TranslatorView()
                    .translationTask(state.translationConfig) { session in
                        do {
                            let r = try await session.translate(state.sourceText)
                            state.translationDidFinish(r.targetText)
                        } catch {
                            state.translationDidFail(error)
                        }
                    }
            } else {
                OnboardingView()
            }
        }
        .frame(width: 340)
    }
}

@available(macOS 15.0, *)
struct TranslatorView: View {
    @Environment(AppState.self) private var state
    @Environment(\.openWindow) private var openWindow
    @State private var showHistory = false

    var body: some View {
        @Bindable var state = state

        VStack(spacing: 0) {
            // Top bar
            HStack {
                let displaySource = state.detectedLang ?? state.sourceLang
                Group {
                    Text("\(displaySource.flag) \(displaySource.displayName)")
                        .font(.subheadline).fontWeight(.semibold)
                    if state.detectedLang != nil && !state.isTranslating {
                        Text(L("detected"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(format: L("a11y.sourcelang"), displaySource.displayName))
                Spacer()
                Button { state.swap() } label: {
                    Image(systemName: "arrow.left.arrow.right")
                }
                .buttonStyle(.plain)
                .help(Text(L("swap.languages")))
                .accessibilityLabel(L("swap.languages"))
                .accessibilityHint(L("a11y.swap.hint"))
                Spacer()
                Text("\(state.targetLang.flag) \(state.targetLang.displayName)")
                    .font(.subheadline).fontWeight(.semibold)
                    .accessibilityLabel(String(format: L("a11y.targetlang"), state.targetLang.displayName))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Main content — translator or history
            if showHistory {
                HistoryView(onSelect: { entry in
                    state.sourceText = entry.source
                    state.translatedText = entry.translation
                    state.sourceLang = entry.from
                    state.targetLang = entry.to
                    showHistory = false
                })
                .frame(width: 340, height: 280)
                .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: 0) {
                    // Input
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
                    .frame(width: 340, height: 110)

                    // Character counter
                    if !state.sourceText.isEmpty {
                        let count = state.sourceText.count
                        HStack {
                            Spacer()
                            Text("\(count) / 500")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(count > 500 ? Color.red : count > 400 ? Color.orange : Color.secondary.opacity(0.5))
                                .padding(.trailing, 10)
                                .padding(.bottom, 4)
                                .accessibilityLabel(String(format: L("a11y.charcount"), count))
                        }
                        .frame(width: 340)
                        .background(Color(nsColor: .textBackgroundColor))
                    }

                    Divider()

                    // Output
                    ZStack {
                        MultilineTextField(
                            text: $state.translatedText,
                            placeholder: L("output.placeholder"),
                            isEditable: false
                        )
                        .frame(width: 340, height: 110)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

                        if state.isTranslating {
                            ProgressView()
                        }
                    }
                }
                .transition(.move(edge: .leading))
            }

            Divider()

            // Bottom bar
            HStack(spacing: 8) {
                // Open window
                Button {
                    openWindow(id: "translator")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Image(systemName: "macwindow")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help(Text(L("window.open")))

                // Open settings
                SettingsLink {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Divider()
                    .frame(height: 14)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showHistory.toggle() }
                } label: {
                    Image(systemName: showHistory ? "xmark" : "clock")
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .help(showHistory ? Text(L("close")) : Text(L("history")))
                .foregroundStyle(showHistory ? .primary : .secondary)
                .accessibilityLabel(showHistory ? L("close") : L("history"))

                if !showHistory {
                    Spacer()

                    if !state.translatedText.isEmpty && !state.isTranslating {
                        Label(L("copied"), systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                            .transition(.opacity)
                    }

                    Spacer()

                    Button { state.clear() } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help(Text(L("clear")))
                    .accessibilityLabel(L("clear"))
                    .disabled(state.sourceText.isEmpty && state.translatedText.isEmpty)

                    Button(L("translate")) { state.translate() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .keyboardShortcut(.return, modifiers: .command)
                        .accessibilityHint(L("a11y.translate.hint"))
                        .disabled(state.sourceText.isEmpty || state.isTranslating)
                } else {
                    Spacer()
                    Text(String(format: L("history.entries %lld"), state.history.entries.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !state.history.entries.isEmpty {
                        Button { state.history.clear() } label: {
                            Text(L("history.clear.all"))
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .alert(L("error.title"), isPresented: Binding(
            get: { state.errorMessage != nil },
            set: { if !$0 { state.errorMessage = nil } }
        )) {
            Button(L("ok")) { state.errorMessage = nil }
        } message: {
            Text(state.errorMessage ?? "")
        }
        .onChange(of: state.sourceText) { _, _ in
            state.updateDetectedLang()
        }
    }
}

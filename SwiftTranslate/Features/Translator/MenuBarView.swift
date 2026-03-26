import SwiftUI
import Translation

@available(macOS 15.0, *)
struct MenuBarView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Group {
            if state.onboardingCompleted {
                TranslatorView()
                    // Single active session, driven by state.activeSessionConfig.
                    // AppState swaps the config on language change; the framework
                    // reuses the cached session for already-installed pairs.
                    .translationTask(state.activeSessionConfig) { @MainActor session in
                        do {
                            let text = state.pendingTranslationText
                            guard !text.isEmpty else { return }
                            let r = try await session.translate(text)
                            state.translationDidFinish(r.targetText)
                        } catch is CancellationError {
                            state.isTranslating = false
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
    @State private var showHistory = false

    var body: some View {
        @Bindable var state = state

        VStack(spacing: 0) {
            LanguageBar()
            Divider()

            if showHistory {
                HistoryView(onSelect: { entry in
                    state.sourceText = entry.source
                    state.translatedText = entry.translation
                    state.sourceLang = entry.from
                    state.targetLang = entry.to
                    showHistory = false
                })
                .frame(height: 280)
                .transition(.move(edge: .trailing))
            } else {
                InputOutputArea()
                    .transition(.move(edge: .leading))
            }

            Divider()
            BottomBar(showHistory: $showHistory)
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

// MARK: - Language Bar

@available(macOS 15.0, *)
private struct LanguageBar: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state

        HStack(spacing: 6) {
            // Source language picker
            Menu {
                let validSources = SupportedLanguage.all.filter { lang in
                    !SupportedLanguage.validTargets(for: lang).isEmpty
                }
                ForEach(validSources) { lang in
                    Button {
                        state.sourceLang = lang
                        state.sourceLangLocked = true
                        state.manualLanguageSwap = true
                    } label: {
                        Label("\(lang.flag) \(lang.displayName)",
                              systemImage: lang == state.sourceLang ? "checkmark" : "")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    let displaySource = state.detectedLang ?? state.sourceLang
                    Text("\(displaySource.flag) \(displaySource.displayName)")
                        .font(.callout).fontWeight(.medium)
                    if state.detectedLang != nil && !state.isTranslating && !state.sourceLangLocked {
                        Text(L("detected"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .accessibilityLabel(String(format: L("a11y.sourcelang"), (state.detectedLang ?? state.sourceLang).displayName))

            Button {
                state.sourceLangLocked.toggle()
            } label: {
                Image(systemName: state.sourceLangLocked ? "lock.fill" : "lock.open")
                    .font(.caption)
                    .foregroundStyle(state.sourceLangLocked ? Color.accentColor : Color.secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help(Text(state.sourceLangLocked ? L("lang.lock.on") : L("lang.lock.off")))

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.15)) { state.swap() }
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.footnote.weight(.medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(Text(L("swap.languages")))
            .accessibilityLabel(L("swap.languages"))
            .accessibilityHint(L("a11y.swap.hint"))
            .disabled(!SupportedLanguage.supportedPairs.contains(
                LangPair(state.targetLang.id, state.sourceLang.id)))

            Spacer()

            // Target language picker
            Menu {
                let validTargets = SupportedLanguage.validTargets(for: state.sourceLang)
                ForEach(validTargets) { lang in
                    Button {
                        state.targetLang = lang
                    } label: {
                        Label("\(lang.flag) \(lang.displayName)",
                              systemImage: lang == state.targetLang ? "checkmark" : "")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("\(state.targetLang.flag) \(state.targetLang.displayName)")
                        .font(.callout).fontWeight(.medium)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .accessibilityLabel(String(format: L("a11y.targetlang"), state.targetLang.displayName))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }
}

// MARK: - Input / Output Area

@available(macOS 15.0, *)
private struct InputOutputArea: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state

        VStack(spacing: 0) {
            // Input field
            ZStack(alignment: .bottomTrailing) {
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
                .frame(height: 120)

                if !state.sourceText.isEmpty {
                    let count = state.sourceText.count
                    let limit = AppState.maxInputLength
                    Text("\(count) / \(limit)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(
                            count > limit - 200 ? Color.red :
                            count > limit - 1000 ? Color.orange :
                            Color.secondary.opacity(0.5)
                        )
                        .padding(.trailing, 10)
                        .padding(.bottom, 6)
                        .accessibilityLabel(String(format: L("a11y.charcount"), count))
                }
            }
            .background(Color(nsColor: .textBackgroundColor))

            Divider()

            // Output field
            ZStack {
                MultilineTextField(
                    text: $state.translatedText,
                    placeholder: L("output.placeholder"),
                    isEditable: false
                )
                .frame(height: 120)
                .background(Color(nsColor: .windowBackgroundColor))

                if state.isTranslating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
}

// MARK: - Bottom Bar

@available(macOS 15.0, *)
private struct BottomBar: View {
    @Environment(AppState.self) private var state
    @Binding var showHistory: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Settings
            SettingsLink {
                Image(systemName: "gear")
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(Text(L("settings")))

            // Quit
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(Text(L("quit")))

            Divider()
                .frame(height: 14)

            // History toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showHistory.toggle() }
            } label: {
                Image(systemName: showHistory ? "xmark" : "clock")
                    .font(.callout)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .foregroundStyle(showHistory ? .primary : .secondary)
            .help(showHistory ? Text(L("close")) : Text(L("history")))
            .accessibilityLabel(showHistory ? L("close") : L("history"))

            Spacer()

            if showHistory {
                Text(String(format: L("history.entries %lld"), state.history.entries.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if !state.history.entries.isEmpty {
                    Button {
                        state.history.clear()
                    } label: {
                        Text(L("history.clear.all"))
                            .font(.callout)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                }
            } else {
                if state.showCopied {
                    Label(L("copied"), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                Spacer()

                Button {
                    state.clear()
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help(Text(L("clear")))
                .accessibilityLabel(L("clear"))
                .disabled(state.sourceText.isEmpty && state.translatedText.isEmpty)

                Button(L("translate")) {
                    state.translate()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .keyboardShortcut(.return, modifiers: .command)
                .accessibilityHint(L("a11y.translate.hint"))
                .disabled(state.sourceText.isEmpty || state.isTranslating)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

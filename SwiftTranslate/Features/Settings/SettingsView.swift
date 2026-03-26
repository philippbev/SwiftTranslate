import SwiftUI
import KeyboardShortcuts
import Translation

@available(macOS 15.0, *)
struct SettingsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state
        Form {
            Section(L("settings.shortcuts")) {
                KeyboardShortcuts.Recorder(L("settings.shortcut.open"), name: .openTranslator)
                Button(role: .destructive) {
                    KeyboardShortcuts.reset(.openTranslator)
                } label: {
                    Text(L("settings.reset.shortcut"))
                }
            }

            Section(L("settings.languages")) {
                Picker(L("settings.sourcelang"), selection: Binding(
                    get: { state.sourceLang },
                    set: { state.sourceLang = $0; state.manualLanguageSwap = true }
                )) {
                    ForEach(SupportedLanguage.all.filter {
                        !SupportedLanguage.validTargets(for: $0).isEmpty
                    }) { lang in
                        Text("\(lang.flag) \(lang.displayName)").tag(lang)
                    }
                }
                Picker(L("settings.targetlang"), selection: Binding(
                    get: { state.targetLang },
                    set: { state.targetLang = $0; state.manualLanguageSwap = true }
                )) {
                    ForEach(SupportedLanguage.validTargets(for: state.sourceLang)) { lang in
                        Text("\(lang.flag) \(lang.displayName)").tag(lang)
                    }
                }
            }

            Section(L("settings.behavior")) {
                Toggle(isOn: Binding(
                    get: { state.autoTranslateOnPaste },
                    set: { state.autoTranslateOnPaste = $0 }
                )) {
                    Text(L("settings.autopaste"))
                }
                Toggle(isOn: Binding(
                    get: { state.autoTranslateWhileTyping },
                    set: { state.autoTranslateWhileTyping = $0 }
                )) {
                    Text(L("settings.autotyping"))
                }
                Toggle(isOn: Binding(
                    get: { state.copyResultToClipboard },
                    set: { state.copyResultToClipboard = $0 }
                )) {
                    Text(L("settings.copyclipboard"))
                }
            }

            Section(L("settings.languagepacks")) {
                LanguagePacksSection()
            }

            Section(L("settings.history")) {
                LabeledContent {
                    Text(String(format: L("settings.history.count %lld"), state.history.entries.count))
                        .foregroundStyle(.secondary)
                } label: {
                    Text(L("settings.history.entries"))
                }
                Button(role: .destructive) {
                    state.history.clear()
                } label: {
                    Text(L("settings.history.clear"))
                }
            }

            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            Section(L("settings.credits")) {
                LabeledContent(L("settings.credits.author")) {
                    Text("Philipp Bevier").foregroundStyle(.secondary)
                }
                LabeledContent(L("settings.credits.version")) {
                    Text("v\(version)").foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 580)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            Task { await state.verifyLanguagePacks() }
        }
    }
}

// MARK: - Language Packs Section

@available(macOS 15.0, *)
private struct LanguagePacksSection: View {
    @Environment(AppState.self) private var state

    // Canonical pairs to display (one per direction group, source-alphabetical)
    private let displayPairs: [(source: SupportedLanguage, target: SupportedLanguage)] = {
        SupportedLanguage.all
            .compactMap { lang -> (SupportedLanguage, SupportedLanguage)? in
                guard lang != .english else { return nil }
                return (.english, lang)
            }
    }()

    var body: some View {
        ForEach(displayPairs, id: \.target.id) { (_, target) in
            LangPackRow(target: target)
        }
    }
}

@available(macOS 15.0, *)
private struct LangPackRow: View {
    @Environment(AppState.self) private var state
    let target: SupportedLanguage

    private var forwardPair: LangPair { LangPair("en", target.id) }
    private var reversePair: LangPair { LangPair(target.id, "en") }

    private var combinedStatus: PackStatus {
        let fwd = state.packStatus[forwardPair] ?? .unknown
        let rev = state.packStatus[reversePair] ?? .unknown
        if fwd == .downloading || rev == .downloading { return .downloading }
        if fwd == .installed && rev == .installed { return .installed }
        if fwd == .failed || rev == .failed { return .failed }
        return .notInstalled
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(target.flag).font(.title3)
            Text("English ↔ \(target.displayName)")
                .font(.callout)
            Spacer()
            statusView
        }
        // Inline download using translationTask — attaches when prepareConfig is set for this pair
        .translationTask(state.prepareConfig) { session in
            do {
                try await session.prepareTranslation()
                if case .downloading(let pair) = state.downloadStatus,
                   (pair == forwardPair || pair == reversePair) {
                    state.pairReady(pair)
                }
            } catch {
                state.downloadFailed(error)
            }
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch combinedStatus {
        case .installed:
            Label(L("pack.installed"), systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        case .downloading:
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.7).frame(width: 14, height: 14)
                Text(L("pack.downloading")).font(.caption).foregroundStyle(.secondary)
            }
        case .notInstalled, .unknown:
            Button(L("pack.download")) {
                Task { await downloadPair() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        case .failed:
            Button(L("pack.retry")) {
                Task { await downloadPair() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.orange)
        }
    }

    private func downloadPair() async {
        // Trigger download for just this pair's forward direction;
        // the reverse will be queued automatically via startDownload
        state.packStatus[forwardPair] = .downloading
        state.packStatus[reversePair] = .downloading
        state.downloadStatus = .downloading(pair: forwardPair)
        state.prepareConfig = TranslationSession.Configuration(
            source: Locale.Language(identifier: forwardPair.source),
            target: Locale.Language(identifier: forwardPair.target)
        )
    }
}

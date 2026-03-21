import SwiftUI
import KeyboardShortcuts

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
                    ForEach([SupportedLanguage.english, .german]) { lang in
                        Text("\(lang.flag) \(lang.displayName)").tag(lang)
                    }
                }
                Picker(L("settings.targetlang"), selection: Binding(
                    get: { state.targetLang },
                    set: { state.targetLang = $0; state.manualLanguageSwap = true }
                )) {
                    ForEach([SupportedLanguage.english, .german]) { lang in
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
            Section {
                Text("SwiftTranslate v\(version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 480)
        .onAppear {
            // Activate the app so the settings window becomes key —
            // required for KeyboardShortcuts.Recorder to receive input.
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

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
            }

            Section(L("settings.behavior")) {
                Toggle(isOn: Binding(
                    get: { state.autoTranslateOnPaste },
                    set: { state.autoTranslateOnPaste = $0 }
                )) {
                    Text(L("settings.autopaste"))
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
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 300)
    }
}

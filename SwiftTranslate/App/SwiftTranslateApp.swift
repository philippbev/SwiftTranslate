import SwiftUI
import KeyboardShortcuts
import AppKit

@available(macOS 15.0, *)
@main
struct SwiftTranslateApp: App {
    @State private var state = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("SwiftTranslate", systemImage: "character.bubble.fill") {
            MenuBarView()
                .environment(state)
                .task {
                    HotkeyManager.shared.setup {
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    appDelegate.appState = state
                }
        }
        .menuBarExtraStyle(.window)

        Window(L("window.title"), id: "translator") {
            ContentView()
                .environment(state)
        }
        .defaultSize(width: 700, height: 420)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .appInfo) {
                EmptyView()
            }
        }

        Settings {
            SettingsView()
                .environment(state)
        }
    }
}

// MARK: - AppDelegate

@available(macOS 15.0, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    weak var appState: AppState?
}

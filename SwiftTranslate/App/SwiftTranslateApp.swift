import SwiftUI
import KeyboardShortcuts
import AppKit

@available(macOS 15.0, *)
@main
struct SwiftTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            if let state = appDelegate.appState_ {
                SettingsView()
                    .environment(state)
            }
        }
    }
}

// MARK: - AppDelegate

@available(macOS 15.0, *)
@Observable
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private(set) var appState_: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.accessory)

        let state = AppState()
        self.appState_ = state

        // Verify language packs are still installed; re-trigger onboarding if not
        Task { await state.verifyLanguagePacks() }

        // Build popover
        let pop = NSPopover()
        pop.contentSize = NSSize(width: 340, height: 400)
        pop.behavior = .transient
        pop.animates = true
        pop.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environment(state)
                .task {
                    HotkeyManager.shared.setup {
                        AppDelegate.shared?.togglePopover()
                    }
                }
        )
        popover = pop

        // Build status item
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "character.bubble.fill",
                                   accessibilityDescription: "SwiftTranslate")
            button.action = #selector(togglePopover)
            button.target = self
        }
        statusItem = item
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    // MARK: - Activation policy

    func applicationDidBecomeActive(_ notification: Notification) {
        let hasSettingsWindow = NSApp.windows.contains {
            $0.isVisible && $0.canBecomeKey && !($0 is NSPanel)
        }
        if hasSettingsWindow {
            NSApp.setActivationPolicy(.regular)
            NSApp.windows.first { $0.isVisible && $0.canBecomeKey }?
                .makeKeyAndOrderFront(nil)
        }
    }

    func applicationDidResignActive(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

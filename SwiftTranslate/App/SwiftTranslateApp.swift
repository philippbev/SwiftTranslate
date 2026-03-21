import SwiftUI
import KeyboardShortcuts
import AppKit

@available(macOS 15.0, *)
@main
struct SwiftTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(appDelegate.appState_ ?? AppState())
        }
    }
}

// MARK: - AppDelegate

@available(macOS 15.0, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    weak var appState: AppState?
    static var shared: AppDelegate!

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private(set) var appState_: AppState!

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.accessory)

        let state = AppState()
        self.appState_ = state
        self.appState = state

        // Build popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 400)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environment(state)
                .task {
                    HotkeyManager.shared.setup {
                        AppDelegate.shared?.togglePopover()
                    }
                }
        )

        // Build status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "character.bubble.fill",
                                   accessibilityDescription: "SwiftTranslate")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
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

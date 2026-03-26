import SwiftUI
import KeyboardShortcuts
import AppKit

@available(macOS 26.0, *)
@main
struct SwiftTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty scene — Settings window is managed manually by AppDelegate
        // to avoid SettingsLink/Bundle-identifier issues in SPM builds.
        Settings { EmptyView() }
    }
}

// MARK: - AppDelegate

@available(macOS 26.0, *)
@Observable
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static var shared: AppDelegate?

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private(set) var appState_: AppState?
    private var settingsWindow: NSWindow?

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
            button.action = #selector(handleStatusItemClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
    }

    @objc func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit SwiftTranslate", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc func openSettings() {
        if popover?.isShown == true { popover?.performClose(nil) }

        if let win = settingsWindow, win.isVisible {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        guard let state = appState_ else { return }
        let hc = NSHostingController(rootView: SettingsView().environment(state))
        let win = NSWindow(contentViewController: hc)
        win.title = "Settings"
        win.styleMask = [.titled, .closable]
        win.setContentSize(NSSize(width: 420, height: 580))
        win.center()
        win.isReleasedWhenClosed = false
        win.delegate = self
        settingsWindow = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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

    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) === settingsWindow {
            settingsWindow = nil
        }
    }

    // MARK: - Activation policy

    func applicationDidBecomeActive(_ notification: Notification) {
        let hasSettingsWindow = settingsWindow?.isVisible == true
        if hasSettingsWindow {
            NSApp.setActivationPolicy(.regular)
            settingsWindow?.makeKeyAndOrderFront(nil)
        }
    }

    func applicationDidResignActive(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

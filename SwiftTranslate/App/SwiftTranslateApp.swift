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

// MARK: - AppDelegate for right-click menu

@available(macOS 15.0, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    weak var appState: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Inject right-click menu into the NSStatusItem after a short delay
        // (MenuBarExtra creates its NSStatusItem asynchronously)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.installRightClickMenu()
        }
    }

    private func installRightClickMenu() {
        guard let statusItem = NSApp.windows
            .compactMap({ $0.value(forKey: "statusItem") as? NSStatusItem })
            .first ?? Self.findStatusItem() else { return }

        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        let target = RightClickTarget(statusItem: statusItem)
        statusItem.button?.target = target
        statusItem.button?.action = #selector(RightClickTarget.handleClick(_:))
        objc_setAssociatedObject(statusItem, &AssociatedKeys.target, target, .OBJC_ASSOCIATION_RETAIN)
    }

    private static func findStatusItem() -> NSStatusItem? {
        // Walk NSStatusBar items via private API as fallback
        let statusBar = NSStatusBar.system
        return (statusBar.value(forKey: "statusItems") as? [NSStatusItem])?.first
    }
}

private enum AssociatedKeys {
    static var target: UInt8 = 0
}

// MARK: - Right-click handler

private class RightClickTarget: NSObject {
    weak var statusItem: NSStatusItem?
    // Store MenuBarExtra's original action so left-click still works
    private weak var originalTarget: AnyObject?
    private var originalAction: Selector?

    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        self.originalTarget = statusItem.button?.target
        self.originalAction = statusItem.button?.action
    }

    @objc func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            let windowItem = NSMenuItem(title: L("window.open"), action: #selector(openWindow), keyEquivalent: "n")
            windowItem.target = self
            let settingsItem = NSMenuItem(title: "Einstellungen…", action: #selector(openSettings), keyEquivalent: ",")
            settingsItem.target = self
            let quitItem = NSMenuItem(title: "SwiftTranslate beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            quitItem.target = NSApp
            menu.addItem(windowItem)
            menu.addItem(settingsItem)
            menu.addItem(.separator())
            menu.addItem(quitItem)
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            // Forward to MenuBarExtra's original handler
            if let action = originalAction {
                _ = originalTarget?.perform(action, with: sender)
            }
        }
    }

    @objc private func openWindow() {
        NSApp.sendAction(#selector(NSWindow.makeKeyAndOrderFront), to: nil, from: nil)
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "translator" }) {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettings() {
        NSApp.sendAction(#selector(NSApplication.showSettingsWindow), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Private API stubs for #selector compatibility

private extension NSApplication {
    @objc func showSettingsWindow() {}
}

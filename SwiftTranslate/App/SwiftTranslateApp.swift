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
class AppDelegate: NSObject, NSApplicationDelegate, RightClickMenuDelegate {
    weak var appState: AppState?
    private var statusItem: NSStatusItem?
    private var clickHandler: StatusItemClickHandler?

    func applicationDidFinishLaunching(_ notification: Notification) {
        retrySetup(attempts: 10)
    }

    private func retrySetup(attempts: Int) {
        guard attempts > 0 else {
            print("[AppDelegate] Gave up finding NSStatusItem after all attempts")
            return
        }
        if Self.findStatusItem() != nil {
            setupRightClickMenu()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.retrySetup(attempts: attempts - 1)
            }
        }
    }

    func setupRightClickMenu() {
        guard let item = Self.findStatusItem() else {
            print("[AppDelegate] NSStatusItem not found")
            return
        }
        print("[AppDelegate] NSStatusItem found, setting up click handler")
        self.statusItem = item

        let handler = StatusItemClickHandler(statusItem: item, delegate: self)
        self.clickHandler = handler

        item.button?.target = handler
        item.button?.action = #selector(StatusItemClickHandler.handleClick(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private static func findStatusItem() -> NSStatusItem? {
        // Method 1: via window's statusItem key
        if let item = NSApp.windows
            .compactMap({ $0.value(forKey: "statusItem") as? NSStatusItem })
            .first {
            return item
        }
        // Method 2: via NSStatusBar private API
        if let items = NSStatusBar.system.value(forKey: "statusItems") as? [NSStatusItem],
           let item = items.first {
            return item
        }
        return nil
    }

    func showRightClickMenu(relativeTo button: NSStatusBarButton) {
        let menu = NSMenu()

        let windowItem = NSMenuItem(
            title: L("window.open"),
            action: #selector(openTranslatorWindow),
            keyEquivalent: ""
        )
        windowItem.target = self
        menu.addItem(windowItem)

        let settingsItem = NSMenuItem(
            title: "Einstellungen…",
            action: #selector(openSettingsWindow),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "SwiftTranslate beenden",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: ""
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
    }

    @objc private func openTranslatorWindow() {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "translator" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            NSApp.sendAction(NSSelectorFromString("showWindow:"), to: nil, from: nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettingsWindow() {
        NSApp.openSettings()
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Click handler

private protocol RightClickMenuDelegate: AnyObject {
    func showRightClickMenu(relativeTo button: NSStatusBarButton)
}

private class StatusItemClickHandler: NSObject {
    private weak var statusItem: NSStatusItem?
    private weak var delegate: RightClickMenuDelegate?
    private let originalTarget: AnyObject?
    private let originalAction: Selector?

    init(statusItem: NSStatusItem, delegate: RightClickMenuDelegate) {
        self.statusItem = statusItem
        self.delegate = delegate
        self.originalTarget = statusItem.button?.target
        self.originalAction = statusItem.button?.action
    }

    @objc func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            delegate?.showRightClickMenu(relativeTo: sender)
        } else {
            if let action = originalAction, let target = originalTarget {
                _ = target.perform(action, with: sender)
            }
        }
    }
}

// MARK: - Settings helper

extension NSApplication {
    func openSettings() {
        sendAction(NSSelectorFromString("showSettingsWindow:"), to: nil, from: nil)
    }
}

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
    private var eventMonitor: Any?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setup()
        }
    }

    private func setup() {
        guard let item = Self.findStatusItem() else {
            print("[AppDelegate] Could not find NSStatusItem")
            return
        }
        self.statusItem = item

        // Listen for right-clicks globally on the status bar button
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]) { [weak self] event in
            guard let self, let button = self.statusItem?.button else { return event }
            // Check if the click is on our status bar button
            let buttonFrame = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
            if buttonFrame.contains(NSEvent.mouseLocation) {
                self.showRightClickMenu()
                return nil // swallow the event
            }
            return event
        }
    }

    private func showRightClickMenu() {
        guard let button = statusItem?.button else { return }

        let menu = NSMenu()

        let windowItem = NSMenuItem(title: L("window.open"), action: #selector(openTranslatorWindow), keyEquivalent: "")
        windowItem.target = self
        menu.addItem(windowItem)

        let settingsItem = NSMenuItem(title: "Einstellungen…", action: #selector(openSettingsWindow), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "SwiftTranslate beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        quitItem.target = NSApp
        menu.addItem(quitItem)

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
    }

    private static func findStatusItem() -> NSStatusItem? {
        if let item = NSApp.windows
            .compactMap({ $0.value(forKey: "statusItem") as? NSStatusItem })
            .first {
            return item
        }
        return (NSStatusBar.system.value(forKey: "statusItems") as? [NSStatusItem])?.first
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

// MARK: - Settings helper

extension NSApplication {
    func openSettings() {
        sendAction(NSSelectorFromString("showSettingsWindow:"), to: nil, from: nil)
    }
}

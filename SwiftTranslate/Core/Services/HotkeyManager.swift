import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let openTranslator = Self("openTranslator", default: .init(.t, modifiers: [.option, .shift]))
}

@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()
    private init() {}

    func setup(action: @escaping () -> Void) {
        KeyboardShortcuts.onKeyUp(for: .openTranslator) { action() }
    }
}

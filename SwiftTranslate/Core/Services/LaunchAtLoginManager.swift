import ServiceManagement

/// Manages the "Launch at Login" login item via SMAppService.
/// Requires a proper .app bundle with CFBundleIdentifier to function.
/// When running as a plain executable (swift build without bundling),
/// isEnabled returns false and toggle calls are silently ignored.
enum LaunchAtLoginManager {

    static var isSupported: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    static var isEnabled: Bool {
        guard isSupported else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    /// Registers or unregisters the app as a login item.
    /// - Returns: true on success, false if unsupported or the call failed.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        guard isSupported else { return false }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}

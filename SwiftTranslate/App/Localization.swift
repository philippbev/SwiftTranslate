import Foundation

/// Looks up a localized string from the SPM resource bundle (Bundle.module).
/// Use this instead of NSLocalizedString() which only searches the main bundle.
func L(_ key: String) -> String {
    NSLocalizedString(key, bundle: .module, comment: "")
}

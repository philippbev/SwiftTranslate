import Foundation

struct ReleaseConfig {
    static let version = "1.0"
    static let build = "1"
    static let isProduction = true
    
    // Features
    static let enableAnalytics = false // Für den Start deaktiviert
    static let enableCrashReporting = false
    static let maxHistoryItems = 50
    
    // Performance
    static let imageCompressionQuality: CGFloat = 0.8
    static let maxCacheSize = 100
    
    // App Store
    static let appStoreURL = ""
    static let privacyPolicyURL = "https://philippbev.github.io/saarlandmass-privacy-policy/"
    static let supportEmail = "hello@bevier.cloud"
    
    // Social
    static let shareHashtag = "#SaarlandRechner"
    static let shareMessage = "Ich habe gerade %@ mit dem Saarland verglichen! 🏳️ Schau dir die App an:"
}

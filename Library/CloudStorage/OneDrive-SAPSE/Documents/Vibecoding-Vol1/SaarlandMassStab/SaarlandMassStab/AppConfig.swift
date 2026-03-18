import Foundation

struct AppConfig {
    // App Info
    static let version = "1.0.0"
    static let buildNumber = "1"
    static let displayName = "Saarland Rechner"
    
    // Einfache Konfiguration ohne komplexe Dependencies
    static let supportEmail = "hello@bevier.cloud"
    static let shareHashtag = "#SaarlandRechner"
    
    // Features
    static let enableAnalytics = false
    static let maxHistoryItems = 100
    
    // Marketing
    static let marketingFacts = [
        "Das Saarland ist 2.569,69 km² groß",
        "986.887 Einwohner (Stand 2024)",
        "Hauptstadt: Saarbrücken",
        "Haupsach gudd gess! 🥔"
    ]
}

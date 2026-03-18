import SwiftUI

extension Color {
    // Verwende die bestehenden Farben, aber erweitere sie für Release
    static var releaseTheme: ReleaseTheme { ReleaseTheme() }
}

struct ReleaseTheme {
    let primary = Color.saarlandBlue // Nutzt bestehende Definition
    let secondary = Color.saarlandBlueLight // Nutzt bestehende Definition
    let accent = Color(red: 1.0, green: 0.84, blue: 0.0)
    
    // Dark Mode Support
    let adaptiveBackground = Color(uiColor: .systemGroupedBackground)
    let adaptiveSecondary = Color(uiColor: .secondarySystemGroupedBackground)
    let adaptiveTertiary = Color(uiColor: .tertiarySystemGroupedBackground)
    
    // Status Farben
    let success = Color(.systemGreen)
    let error = Color(.systemRed)
    let warning = Color(.systemOrange)
    let info = Color(.systemBlue)
}

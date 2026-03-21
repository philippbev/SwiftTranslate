import Foundation

enum SupportedLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case german = "de"

    var id: String { rawValue }
    var localeIdentifier: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .german: return "Deutsch"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .german: return "🇩🇪"
        }
    }
}

struct HistoryEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    let source: String
    let translation: String
    let from: SupportedLanguage
    let to: SupportedLanguage
    let date: Date

    init(source: String, translation: String, from: SupportedLanguage, to: SupportedLanguage) {
        self.source = source
        self.translation = translation
        self.from = from
        self.to = to
        self.date = .now
    }
}

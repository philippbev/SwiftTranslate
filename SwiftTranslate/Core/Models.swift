import Foundation

struct SupportedLanguage: Identifiable, Codable, Equatable, Hashable {
    let id: String          // BCP-47 locale identifier, e.g. "en", "de"
    let displayName: String
    let flag: String

    var localeIdentifier: String { id }

    // MARK: - Registry

    static let english  = SupportedLanguage(id: "en", displayName: "English",   flag: "🇬🇧")
    static let german   = SupportedLanguage(id: "de", displayName: "Deutsch",   flag: "🇩🇪")
    static let french   = SupportedLanguage(id: "fr", displayName: "Français",  flag: "🇫🇷")
    static let spanish  = SupportedLanguage(id: "es", displayName: "Español",   flag: "🇪🇸")
    static let italian  = SupportedLanguage(id: "it", displayName: "Italiano",  flag: "🇮🇹")

    /// All languages available for translation.
    static let all: [SupportedLanguage] = [.english, .german, .french, .spanish, .italian]

    /// Look up by locale identifier — used for Codable decoding and LanguageDetector mapping.
    static func from(id: String) -> SupportedLanguage? {
        all.first { $0.id == id }
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

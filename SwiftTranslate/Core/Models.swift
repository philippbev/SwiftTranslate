import Foundation

struct SupportedLanguage: Identifiable, Codable, Equatable, Hashable {
    let id: String          // BCP-47 locale identifier, e.g. "en", "de"
    let displayName: String
    let flag: String

    var localeIdentifier: String { id }

    // MARK: - Registry

    static let english    = SupportedLanguage(id: "en", displayName: "English",    flag: "🇬🇧")
    static let german     = SupportedLanguage(id: "de", displayName: "Deutsch",    flag: "🇩🇪")
    static let french     = SupportedLanguage(id: "fr", displayName: "Français",   flag: "🇫🇷")
    static let spanish    = SupportedLanguage(id: "es", displayName: "Español",    flag: "🇪🇸")
    static let italian    = SupportedLanguage(id: "it", displayName: "Italiano",   flag: "🇮🇹")
    static let portuguese = SupportedLanguage(id: "pt", displayName: "Português",  flag: "🇵🇹")
    static let dutch      = SupportedLanguage(id: "nl", displayName: "Nederlands", flag: "🇳🇱")
    static let japanese   = SupportedLanguage(id: "ja", displayName: "日本語",      flag: "🇯🇵")
    static let chinese    = SupportedLanguage(id: "zh", displayName: "中文",        flag: "🇨🇳")

    /// All languages available in the language picker.
    static let all: [SupportedLanguage] = [
        .english, .german, .french, .spanish, .italian, .portuguese, .dutch, .japanese, .chinese
    ]

    /// Direct translation pairs supported by Apple's Translation framework.
    /// All non-English pairs must go through English as a bridge (not currently supported).
    static let supportedPairs: Set<LangPair> = [
        LangPair("en", "de"), LangPair("de", "en"),
        LangPair("en", "fr"), LangPair("fr", "en"),
        LangPair("en", "es"), LangPair("es", "en"),
        LangPair("en", "it"), LangPair("it", "en"),
        LangPair("en", "pt"), LangPair("pt", "en"),
        LangPair("en", "nl"), LangPair("nl", "en"),
        LangPair("en", "ja"), LangPair("ja", "en"),
        LangPair("en", "zh"), LangPair("zh", "en"),
    ]

    /// Returns the valid target languages for a given source language.
    static func validTargets(for source: SupportedLanguage) -> [SupportedLanguage] {
        all.filter { $0 != source && supportedPairs.contains(LangPair(source.id, $0.id)) }
    }

    /// Look up by locale identifier — used for Codable decoding and LanguageDetector mapping.
    static func from(id: String) -> SupportedLanguage? {
        all.first { $0.id == id }
    }
}

// MARK: - LangPair

struct LangPair: Hashable {
    let source: String
    let target: String

    init(_ source: String, _ target: String) {
        self.source = source
        self.target = target
    }

    var key: String { "\(source)>\(target)" }
}

// MARK: - HistoryEntry

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

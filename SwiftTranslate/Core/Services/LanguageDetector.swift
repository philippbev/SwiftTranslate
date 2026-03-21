import Foundation
import NaturalLanguage

protocol LanguageDetecting {
    func detect(_ text: String) -> SupportedLanguage?
}

struct LanguageDetector: LanguageDetecting {
    func detect(_ text: String) -> SupportedLanguage? {
        guard text.count > 3 else { return nil }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        switch recognizer.dominantLanguage {
        case .english: return .english
        case .german: return .german
        default: return nil
        }
    }
}

import Foundation
import NaturalLanguage

protocol LanguageDetecting {
    func detect(_ text: String) -> SupportedLanguage?
}

struct LanguageDetector: LanguageDetecting {
    func detect(_ text: String) -> SupportedLanguage? {
        guard text.count > 3 else { return nil }
        // NLLanguageRecognizer.processString can be slow on long text — run off main thread
        return DispatchQueue.global(qos: .userInitiated).sync {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(text)
            guard let dominant = recognizer.dominantLanguage else { return nil }
            return SupportedLanguage.from(id: dominant.rawValue)
        }
    }
}

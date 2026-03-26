import Foundation
import NaturalLanguage

protocol LanguageDetecting {
    func detect(_ text: String) async -> SupportedLanguage?
}

struct LanguageDetector: LanguageDetecting {
    func detect(_ text: String) async -> SupportedLanguage? {
        guard text.count > 3 else { return nil }
        // NLLanguageRecognizer.processString can be slow on long text — run fully off main thread
        return await Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled else { return nil }
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(text)
            guard !Task.isCancelled else { return nil }
            guard let dominant = recognizer.dominantLanguage else { return nil }
            return SupportedLanguage.from(id: dominant.rawValue)
        }.value
    }
}

import SwiftUI
import Observation

/// Central app state — injected via @Environment throughout the app.
@Observable
@MainActor
final class AppState {
    // MARK: - Services
    let translationService = TranslationService()
    let languageDetector = LanguageDetector()
    let historyStore = HistoryStore()

    // MARK: - Translator State
    var sourceText: String = ""
    var translatedText: String = ""
    var detectedLanguage: SupportedLanguage = .english
    var targetLanguage: SupportedLanguage = .german
    var isTranslating: Bool = false
    var errorMessage: String? = nil

    // MARK: - Private

    /// Tracks the active translation task so we can cancel it when a new request arrives.
    private var activeTranslationTask: Task<Void, Never>?

    // MARK: - Translation trigger (used by menu command & keyboard shortcut)

    func triggerTranslation() {
        guard !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        // Cancel previous task and kick off a new one.
        activeTranslationTask?.cancel()
        activeTranslationTask = Task { await translate() }
    }

    func translate() async {
        guard !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isTranslating = true
        errorMessage = nil

        // Auto-detect language from the full source text.
        if let detected = languageDetector.detect(sourceText) {
            detectedLanguage = detected
            targetLanguage = detected == .english ? .german : .english
        }

        do {
            let result = try await translationService.translate(
                text: sourceText,
                from: detectedLanguage,
                to: targetLanguage
            )
            translatedText = result
            copyToClipboard(result)
            historyStore.add(HistoryEntry(source: sourceText, translation: result,
                                          from: detectedLanguage, to: targetLanguage))
        } catch is CancellationError {
            // A newer request cancelled this one — nothing to do.
        } catch {
            errorMessage = error.localizedDescription
        }

        isTranslating = false
    }

    func swapLanguages() {
        let tmp = sourceText
        sourceText = translatedText
        translatedText = tmp
        let tmpLang = detectedLanguage
        detectedLanguage = targetLanguage
        targetLanguage = tmpLang
    }

    func clear() {
        activeTranslationTask?.cancel()
        activeTranslationTask = nil
        sourceText = ""
        translatedText = ""
        errorMessage = nil
        isTranslating = false
    }

    // MARK: - Private
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

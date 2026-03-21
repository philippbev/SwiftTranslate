import SwiftUI
import Translation
import Observation

// MARK: - Download State

@available(macOS 15.0, *)
enum DownloadStatus: Equatable {
    case idle
    case checkingAvailability
    case downloading(phase: DownloadPhase)
    case ready
    case failed(String)

    enum DownloadPhase: Equatable {
        case enDe   // step 1
        case deDe   // step 2 (DE→EN)
    }
}

// MARK: - AppState

@available(macOS 15.0, *)
@Observable
@MainActor
final class AppState {

    // MARK: Translation state
    var sourceText = ""
    var translatedText = ""
    var sourceLang: SupportedLanguage = SupportedLanguage.from(id: UserDefaults.standard.string(forKey: "sourceLang") ?? "") ?? .german {
        didSet { UserDefaults.standard.set(sourceLang.id, forKey: "sourceLang") }
    }
    var targetLang: SupportedLanguage = SupportedLanguage.from(id: UserDefaults.standard.string(forKey: "targetLang") ?? "") ?? .english {
        didSet { UserDefaults.standard.set(targetLang.id, forKey: "targetLang") }
    }
    var isTranslating = false
    var errorMessage: String? = nil
    var translationConfig: TranslationSession.Configuration? = nil
    var manualLanguageSwap = false
    var detectedLang: SupportedLanguage? = nil
    var sourceLangLocked: Bool = UserDefaults.standard.bool(forKey: "sourceLangLocked") {
        didSet { UserDefaults.standard.set(sourceLangLocked, forKey: "sourceLangLocked") }
    }

    // MARK: Download state
    var downloadStatus: DownloadStatus = .idle
    var prepareConfig: TranslationSession.Configuration? = nil
    var prepareConfigDeEn: TranslationSession.Configuration? = nil
    /// 0.0 – 1.0, updated during download
    var downloadProgress: Double = 0

    // MARK: Services
    let detector: any LanguageDetecting
    let history: any HistoryStoring
    private var detectionDebounceTask: Task<Void, Never>?
    private var autoTranslateDebounceTask: Task<Void, Never>?
    private var translationCache: [String: String] = [:]

    // MARK: Settings
    var autoTranslateOnPaste: Bool = UserDefaults.standard.bool(forKey: "autoTranslateOnPaste") {
        didSet { UserDefaults.standard.set(autoTranslateOnPaste, forKey: "autoTranslateOnPaste") }
    }

    var autoTranslateWhileTyping: Bool = UserDefaults.standard.bool(forKey: "autoTranslateWhileTyping") {
        didSet { UserDefaults.standard.set(autoTranslateWhileTyping, forKey: "autoTranslateWhileTyping") }
    }

    var copyResultToClipboard: Bool = {
        let key = "copyResultToClipboard"
        if UserDefaults.standard.object(forKey: key) == nil { return true }
        return UserDefaults.standard.bool(forKey: key)
    }() {
        didSet { UserDefaults.standard.set(copyResultToClipboard, forKey: "copyResultToClipboard") }
    }

    var onboardingCompleted: Bool = OnboardingStore.shared.hasCompleted {
        didSet { OnboardingStore.shared.hasCompleted = onboardingCompleted }
    }

    init(detector: any LanguageDetecting = LanguageDetector(),
         history: (any HistoryStoring)? = nil) {
        self.detector = detector
        self.history = history ?? HistoryStore()
    }

    // MARK: - Download

    /// Checks availability first, then starts downloading missing packages.
    func startDownload() async {
        downloadStatus = .checkingAvailability
        downloadProgress = 0

        let availability = LanguageAvailability()
        let enStatus = await availability.status(from: Locale.Language(identifier: "en"),
                                                  to: Locale.Language(identifier: "de"))
        let deStatus = await availability.status(from: Locale.Language(identifier: "de"),
                                                  to: Locale.Language(identifier: "en"))

        print("[Download] EN→DE status: \(enStatus), DE→EN status: \(deStatus)")

        if enStatus == .installed && deStatus == .installed {
            finishDownload()
            return
        }

        downloadStatus = .downloading(phase: .enDe)
        prepareConfig = TranslationSession.Configuration(
            source: Locale.Language(identifier: "en"),
            target: Locale.Language(identifier: "de")
        )
    }

    /// Called by OnboardingView after EN→DE package is ready.
    func enDeReady() {
        print("[Download] EN→DE ready, switching to DE→EN")
        downloadProgress = 0.5
        downloadStatus = .downloading(phase: .deDe)
        prepareConfigDeEn = TranslationSession.Configuration(
            source: Locale.Language(identifier: "de"),
            target: Locale.Language(identifier: "en")
        )
    }

    /// Called when all packages are ready.
    func finishDownload() {
        downloadProgress = 1.0
        downloadStatus = .ready
        invalidateDownloadConfigs()
        onboardingCompleted = true
    }

    func downloadFailed(_ error: Error) {
        downloadStatus = .failed(error.localizedDescription)
        invalidateDownloadConfigs()
    }

    // MARK: - Translation

    func translate() {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if !manualLanguageSwap && !sourceLangLocked {
            if let detected = detector.detect(text) {
                sourceLang = detected
                // Pick a sensible default target: prefer DE if source is EN, otherwise EN
                targetLang = detected == .english ? .german : .english
            }
        }
        detectedLang = nil
        manualLanguageSwap = false
        errorMessage = nil

        let cacheKey = "\(sourceLang.id)>\(targetLang.id):\(text)"
        if let cached = translationCache[cacheKey] {
            translatedText = cached
            return
        }

        isTranslating = true
        translationConfig = TranslationSession.Configuration(
            source: Locale.Language(identifier: sourceLang.localeIdentifier),
            target: Locale.Language(identifier: targetLang.localeIdentifier)
        )
    }

    /// Called while user types — debounced 300ms for detection, 800ms for auto-translate.
    func updateDetectedLang() {
        // Clear translation when source text is empty
        if sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            translatedText = ""
            detectedLang = nil
            return
        }

        // Language detection: skip if manually swapped or locked
        if !manualLanguageSwap && !sourceLangLocked {
            detectionDebounceTask?.cancel()
            detectionDebounceTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                detectedLang = detector.detect(sourceText)
            }
        } else {
            detectedLang = nil
        }

        // Auto-translate: always runs if enabled, regardless of lock
        guard autoTranslateWhileTyping, !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        autoTranslateDebounceTask?.cancel()
        autoTranslateDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            translate()
        }
    }

    func translationDidFinish(_ result: String) {
        let cacheKey = "\(sourceLang.id)>\(targetLang.id):\(sourceText.trimmingCharacters(in: .whitespacesAndNewlines))"
        translationCache[cacheKey] = result
        translatedText = result
        isTranslating = false
        if copyResultToClipboard {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result, forType: .string)
        }
        history.add(HistoryEntry(
            source: sourceText, translation: result,
            from: sourceLang, to: targetLang
        ))
        invalidateTranslationConfig()
    }

    func translationDidFail(_ error: Error) {
        errorMessage = error.localizedDescription
        isTranslating = false
        invalidateTranslationConfig()
    }

    func swap() {
        Swift.swap(&sourceText, &translatedText)
        Swift.swap(&sourceLang, &targetLang)
        manualLanguageSwap = true
    }

    func clear() {
        detectionDebounceTask?.cancel()
        autoTranslateDebounceTask?.cancel()
        sourceText = ""
        translatedText = ""
        errorMessage = nil
        isTranslating = false
        translationCache.removeAll()
        invalidateTranslationConfig()
    }

    // MARK: - Private

    private func invalidateDownloadConfigs() {
        prepareConfig?.invalidate()
        prepareConfigDeEn?.invalidate()
    }

    private func invalidateTranslationConfig() {
        translationConfig?.invalidate()
    }
}

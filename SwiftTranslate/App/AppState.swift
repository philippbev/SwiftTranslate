import SwiftUI
import Translation
import Observation
import OSLog

private let logger = Logger(subsystem: "com.philippbev.SwiftTranslate", category: "AppState")

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
    var sourceLang: SupportedLanguage = {
        let stored = UserDefaults.standard.string(forKey: "sourceLang") ?? ""
        guard let lang = SupportedLanguage.from(id: stored),
              lang == .english || lang == .german else { return .english }
        return lang
    }() {
        didSet { UserDefaults.standard.set(sourceLang.id, forKey: "sourceLang") }
    }
    var targetLang: SupportedLanguage = {
        let stored = UserDefaults.standard.string(forKey: "targetLang") ?? ""
        guard let lang = SupportedLanguage.from(id: stored),
              lang == .english || lang == .german else { return .german }
        return lang
    }() {
        didSet {
            UserDefaults.standard.set(targetLang.id, forKey: "targetLang")
            targetLangManuallySet = true
        }
    }
    var isTranslating = false
    var showCopied = false
    var errorMessage: String? = nil
    var translationConfig: TranslationSession.Configuration? = nil  // download-prepare only
    /// Bumped on every translate() call — .task(id:) in MenuBarView uses this as trigger.
    private(set) var translationRequestID = UUID()
    /// Text to translate, set atomically with translationRequestID.
    private(set) var pendingTranslationText = ""
    var manualLanguageSwap = false
    var detectedLang: SupportedLanguage? = nil
    var sourceLangLocked: Bool = UserDefaults.standard.bool(forKey: "sourceLangLocked") {
        didSet { UserDefaults.standard.set(sourceLangLocked, forKey: "sourceLangLocked") }
    }
    var targetLangManuallySet: Bool = UserDefaults.standard.bool(forKey: "targetLangManuallySet") {
        didSet { UserDefaults.standard.set(targetLangManuallySet, forKey: "targetLangManuallySet") }
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
    private static let detectionDebounceMs: Int = 300
    private static let autoTranslateDebounceMs: Int = 800
    private static let retriggerDebounceMs: Int = 300
    private static let copiedHideSeconds: Double = 2
    private static let langEN = "en"
    private static let langDE = "de"

    private var detectionDebounceTask: Task<Void, Never>?
    private var autoTranslateDebounceTask: Task<Void, Never>?
    private var activeTranslateTask: Task<Void, Never>?
    private var copiedHideTask: Task<Void, Never>?
    private var translationCache: [String: String] = [:]
    private var translationCacheOrder: [String] = []   // tracks insertion order for LRU eviction
    private let translationCacheLimit = 50
    static let maxInputLength = 5_000

    // MARK: Settings
    var autoTranslateOnPaste: Bool = {
        let key = "autoTranslateOnPaste"
        if UserDefaults.standard.object(forKey: key) == nil { return true }
        return UserDefaults.standard.bool(forKey: key)
    }() {
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

        let (enStatus, deStatus) = await checkAvailability()

        logger.debug("[Download] EN→DE status: \(String(describing: enStatus)), DE→EN status: \(String(describing: deStatus))")

        if enStatus == .installed && deStatus == .installed {
            finishDownload()
            return
        }

        downloadStatus = .downloading(phase: .enDe)
        prepareConfig = TranslationSession.Configuration(
            source: Locale.Language(identifier: AppState.langEN),
            target: Locale.Language(identifier: AppState.langDE)
        )
    }

    /// Called by OnboardingView after EN→DE package is ready.
    func enDeReady() {
        logger.debug("[Download] EN→DE ready, switching to DE→EN")
        downloadProgress = 0.5
        downloadStatus = .downloading(phase: .deDe)
        prepareConfigDeEn = TranslationSession.Configuration(
            source: Locale.Language(identifier: AppState.langDE),
            target: Locale.Language(identifier: AppState.langEN)
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
        guard !text.isEmpty, text.count <= AppState.maxInputLength else { return }
        // Block overlapping calls — a new request only starts once the current
        // .translationTask session has fully resolved (isTranslating reset to false).
        guard !isTranslating else { return }

        // Mark busy immediately so any further keystrokes / debounce firings are
        // blocked above before we even hit the async suspension point.
        isTranslating = true
        errorMessage = nil

        activeTranslateTask?.cancel()
        activeTranslateTask = Task {
            // Language detection (async — must check cancellation after)
            if !manualLanguageSwap && !sourceLangLocked {
                if let detected = await detector.detect(text) {
                    guard !Task.isCancelled else { isTranslating = false; return }
                    sourceLang = detected
                    if !targetLangManuallySet && targetLang == detected {
                        targetLang = detected == .english ? .german : .english
                        targetLangManuallySet = false
                    }
                }
            }
            guard !Task.isCancelled else { isTranslating = false; return }

            detectedLang = nil
            manualLanguageSwap = false

            // Cache hit — no network/framework call needed
            let cacheKey = "\(sourceLang.id)>\(targetLang.id):\(text)"
            if let cached = translationCache[cacheKey] {
                translatedText = cached
                isTranslating = false
                if copyResultToClipboard {
                    writeToClipboard(cached)
                    showCopied = true
                    copiedHideTask?.cancel()
                    copiedHideTask = Task {
                        try? await Task.sleep(for: .seconds(AppState.copiedHideSeconds))
                        guard !Task.isCancelled else { return }
                        showCopied = false
                    }
                }
                return
            }

            // Store text and bump UUID — .task(id: translationRequestID) in
            // MenuBarView picks this up and runs the translation directly on
            // the cached session, bypassing Apple's Configuration object caching.
            pendingTranslationText = text
            translationRequestID = UUID()
            translationConfig = nil
        }
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
                try? await Task.sleep(for: .milliseconds(AppState.detectionDebounceMs))
                guard !Task.isCancelled else { return }
                detectedLang = await detector.detect(sourceText)
            }
        } else {
            detectedLang = nil
        }

        // Auto-translate: always schedule the debounce; translate() itself
        // blocks overlapping calls via isTranslating.
        guard autoTranslateWhileTyping,
              !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        autoTranslateDebounceTask?.cancel()
        autoTranslateDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(AppState.autoTranslateDebounceMs))
            guard !Task.isCancelled else { return }
            translate()
        }
    }

    func translationDidFinish(_ result: String) {
        let finishedText = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let cacheKey = "\(sourceLang.id)>\(targetLang.id):\(finishedText)"
        if translationCache.count >= translationCacheLimit,
           let oldest = translationCacheOrder.first {
            translationCache.removeValue(forKey: oldest)
            translationCacheOrder.removeFirst()
        }
        translationCache[cacheKey] = result
        translationCacheOrder.append(cacheKey)
        translatedText = result
        isTranslating = false
        if copyResultToClipboard {
            writeToClipboard(result)
            showCopied = true
            copiedHideTask?.cancel()
            copiedHideTask = Task {
                try? await Task.sleep(for: .seconds(AppState.copiedHideSeconds))
                guard !Task.isCancelled else { return }
                showCopied = false
            }
        }
        history.add(HistoryEntry(
            source: sourceText, translation: result,
            from: sourceLang, to: targetLang
        ))
        manualLanguageSwap = false

        // If the user kept typing while we were translating, the debounce fired
        // translate() but it was blocked by isTranslating. Now that we're free,
        // re-trigger so the latest text gets translated.
        if autoTranslateWhileTyping {
            let latestText = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !latestText.isEmpty && latestText != finishedText {
                autoTranslateDebounceTask?.cancel()
                autoTranslateDebounceTask = Task {
                    try? await Task.sleep(for: .milliseconds(AppState.retriggerDebounceMs))
                    guard !Task.isCancelled else { return }
                    translate()
                }
            }
        }
    }

    func translationDidFail(_ error: Error) {
        errorMessage = userFacingMessage(for: error)
        isTranslating = false
    }

    func swap() {
        guard !isTranslating else { return }
        Swift.swap(&sourceText, &translatedText)
        Swift.swap(&sourceLang, &targetLang)
        manualLanguageSwap = true
        targetLangManuallySet = false
    }

    func clear() {
        detectionDebounceTask?.cancel()
        autoTranslateDebounceTask?.cancel()
        activeTranslateTask?.cancel()
        copiedHideTask?.cancel()
        sourceText = ""
        translatedText = ""
        errorMessage = nil
        isTranslating = false
        showCopied = false
        translationCache.removeAll()
        translationCacheOrder.removeAll()
    }

    // MARK: - Private

    private func checkAvailability() async -> (en: LanguageAvailability.Status, de: LanguageAvailability.Status) {
        let availability = LanguageAvailability()
        let enStatus = await availability.status(from: Locale.Language(identifier: AppState.langEN),
                                                  to: Locale.Language(identifier: AppState.langDE))
        let deStatus = await availability.status(from: Locale.Language(identifier: AppState.langDE),
                                                  to: Locale.Language(identifier: AppState.langEN))
        return (en: enStatus, de: deStatus)
    }

    private func writeToClipboard(_ text: String) {
        guard !text.isEmpty, text.count <= AppState.maxInputLength else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func userFacingMessage(for error: Error) -> String {
        return L("error.translation.failed")
    }

    private func invalidateDownloadConfigs() {
        prepareConfig?.invalidate()
        prepareConfigDeEn?.invalidate()
    }

    // MARK: - Language Pack Verification
    func verifyLanguagePacks() async {
        let (enStatus, deStatus) = await checkAvailability()
        if enStatus != .installed && deStatus != .installed {
            onboardingCompleted = false
        }
    }
}

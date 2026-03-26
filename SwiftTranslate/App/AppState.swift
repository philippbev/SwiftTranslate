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
    case downloading(pair: LangPair)
    case ready
    case failed(String)
}

// MARK: - Pack availability per pair

@available(macOS 15.0, *)
enum PackStatus: Equatable {
    case unknown
    case installed
    case notInstalled
    case downloading
    case failed
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
        guard let lang = SupportedLanguage.from(id: stored) else { return .english }
        return lang
    }() {
        didSet {
            UserDefaults.standard.set(sourceLang.id, forKey: "sourceLang")
            // If current target is no longer valid for new source, auto-pick best target
            if !SupportedLanguage.supportedPairs.contains(LangPair(sourceLang.id, targetLang.id)) {
                targetLang = SupportedLanguage.validTargets(for: sourceLang).first ?? .german
                targetLangManuallySet = false
            }
        }
    }
    var targetLang: SupportedLanguage = {
        let stored = UserDefaults.standard.string(forKey: "targetLang") ?? ""
        guard let lang = SupportedLanguage.from(id: stored) else { return .german }
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
    /// Active session config — set by translate(), drives .translationTask in MenuBarView.
    var activeSessionConfig: TranslationSession.Configuration? = nil
    /// Snapshot of the text being translated — read by MenuBarView's translationTask closure.
    private(set) var pendingTranslationText = ""
    /// Snapshot of the request's language pair — used to validate result on return.
    private(set) var pendingSourceLang: SupportedLanguage = .english
    private(set) var pendingTargetLang: SupportedLanguage = .german
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
    /// Per-pair pack status — populated by verifyLanguagePacks() and download flow
    var packStatus: [LangPair: PackStatus] = [:]
    /// Current download queue (pairs to download in order)
    private(set) var downloadQueue: [LangPair] = []
    private(set) var downloadQueueIndex: Int = 0
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

    private var detectionDebounceTask: Task<Void, Never>?
    private var autoTranslateDebounceTask: Task<Void, Never>?
    private var activeTranslateTask: Task<Void, Never>?
    private var copiedHideTask: Task<Void, Never>?
    private var translationCache: [String: String] = [:]
    private var translationCacheOrder: [String] = []
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

    /// Checks availability of all pairs, then downloads missing ones sequentially.
    func startDownload() async {
        downloadStatus = .checkingAvailability
        downloadProgress = 0

        let allPairs = Array(SupportedLanguage.supportedPairs)
        let availability = LanguageAvailability()

        var missing: [LangPair] = []
        for pair in allPairs {
            let status = await availability.status(
                from: Locale.Language(identifier: pair.source),
                to: Locale.Language(identifier: pair.target)
            )
            packStatus[pair] = status == .installed ? .installed : .notInstalled
            if status != .installed { missing.append(pair) }
        }

        logger.debug("[Download] \(missing.count) pairs need downloading")

        if missing.isEmpty {
            finishDownload()
            return
        }

        downloadQueue = missing
        downloadQueueIndex = 0
        triggerNextDownload()
    }

    /// Called by OnboardingView / SettingsView after the current pair's prepareTranslation() completes.
    func pairReady(_ pair: LangPair) {
        logger.debug("[Download] Pair \(pair.key) ready")
        packStatus[pair] = .installed
        downloadQueueIndex += 1
        downloadProgress = downloadQueue.isEmpty ? 1.0 :
            Double(downloadQueueIndex) / Double(downloadQueue.count)

        if downloadQueueIndex >= downloadQueue.count {
            finishDownload()
        } else {
            triggerNextDownload()
        }
    }

    /// Called when all packages are ready.
    func finishDownload() {
        downloadProgress = 1.0
        downloadStatus = .ready
        prepareConfig?.invalidate()
        prepareConfig = nil
        onboardingCompleted = true
    }

    func downloadFailed(_ error: Error) {
        downloadStatus = .failed(error.localizedDescription)
        prepareConfig?.invalidate()
        prepareConfig = nil
    }

    private func triggerNextDownload() {
        guard downloadQueueIndex < downloadQueue.count else { return }
        let pair = downloadQueue[downloadQueueIndex]
        packStatus[pair] = .downloading
        downloadStatus = .downloading(pair: pair)
        prepareConfig = TranslationSession.Configuration(
            source: Locale.Language(identifier: pair.source),
            target: Locale.Language(identifier: pair.target)
        )
        logger.debug("[Download] Triggering download for \(pair.key)")
    }

    // MARK: - Translation

    func translate() {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= AppState.maxInputLength else { return }
        guard !isTranslating else { return }

        isTranslating = true
        errorMessage = nil

        activeTranslateTask?.cancel()
        activeTranslateTask = Task {
            // Language detection (async — must check cancellation after)
            if !manualLanguageSwap && !sourceLangLocked {
                if let detected = await detector.detect(text) {
                    guard !Task.isCancelled else { isTranslating = false; return }
                    // Only apply detected lang if it's a supported source
                    if SupportedLanguage.validTargets(for: detected).contains(targetLang) {
                        sourceLang = detected
                    } else if let firstValid = SupportedLanguage.validTargets(for: detected).first {
                        sourceLang = detected
                        if !targetLangManuallySet { targetLang = firstValid }
                    } else {
                        sourceLang = detected
                    }
                    if !targetLangManuallySet && targetLang == detected {
                        targetLang = detected == .english ? .german : .english
                        targetLangManuallySet = false
                    }
                }
            }
            guard !Task.isCancelled else { isTranslating = false; return }

            detectedLang = nil
            manualLanguageSwap = false

            // Cache hit
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

            pendingTranslationText = text
            pendingSourceLang = sourceLang
            pendingTargetLang = targetLang
            // Setting activeSessionConfig triggers the .translationTask modifier in MenuBarView,
            // which runs the translation on Apple's cached session for this language pair.
            activeSessionConfig = TranslationSession.Configuration(
                source: Locale.Language(identifier: sourceLang.id),
                target: Locale.Language(identifier: targetLang.id)
            )
            translationConfig = nil
        }
    }

    /// Called while user types — debounced 300ms for detection, 800ms for auto-translate.
    func updateDetectedLang() {
        if sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            translatedText = ""
            detectedLang = nil
            return
        }

        if !manualLanguageSwap && !sourceLangLocked {
            detectionDebounceTask?.cancel()
            detectionDebounceTask = Task {
                try? await Task.sleep(for: .milliseconds(AppState.detectionDebounceMs))
                guard !Task.isCancelled else { return }
                if let detected = await detector.detect(sourceText),
                   !SupportedLanguage.validTargets(for: detected).isEmpty {
                    detectedLang = detected
                }
            }
        } else {
            detectedLang = nil
        }

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
        let finishedText = pendingTranslationText
        let cacheKey = "\(pendingSourceLang.id)>\(pendingTargetLang.id):\(finishedText)"
        if translationCache.count >= translationCacheLimit,
           let oldest = translationCacheOrder.first {
            translationCache.removeValue(forKey: oldest)
            translationCacheOrder.removeFirst()
        }
        translationCache[cacheKey] = result
        translationCacheOrder.append(cacheKey)
        translatedText = result
        isTranslating = false
        activeSessionConfig?.invalidate()
        activeSessionConfig = nil
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
            source: pendingTranslationText, translation: result,
            from: pendingSourceLang, to: pendingTargetLang
        ))
        manualLanguageSwap = false

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
        activeSessionConfig?.invalidate()
        activeSessionConfig = nil
    }

    func translationDidFailWithPackMissing() {
        errorMessage = L("error.pack.missing")
        isTranslating = false
        activeSessionConfig?.invalidate()
        activeSessionConfig = nil
    }

    func swap() {
        guard !isTranslating else { return }
        // Only swap if the reverse pair is also supported
        guard SupportedLanguage.supportedPairs.contains(LangPair(targetLang.id, sourceLang.id)) else { return }
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
        activeSessionConfig?.invalidate()
        activeSessionConfig = nil
        translationCache.removeAll()
        translationCacheOrder.removeAll()
    }

    // MARK: - Private

    private func writeToClipboard(_ text: String) {
        guard !text.isEmpty, text.count <= AppState.maxInputLength else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func userFacingMessage(for error: Error) -> String {
        return L("error.translation.failed")
    }

    // MARK: - Language Pack Verification

    func verifyLanguagePacks() async {
        let availability = LanguageAvailability()
        var anyMissing = false
        for pair in SupportedLanguage.supportedPairs {
            let status = await availability.status(
                from: Locale.Language(identifier: pair.source),
                to: Locale.Language(identifier: pair.target)
            )
            packStatus[pair] = status == .installed ? .installed : .notInstalled
            if status != .installed { anyMissing = true }
        }
        // Only trigger re-onboarding if the core EN↔DE pair is missing
        let coreInstalled = packStatus[LangPair("en", "de")] == .installed &&
                            packStatus[LangPair("de", "en")] == .installed
        if !coreInstalled {
            onboardingCompleted = false
        }
        _ = anyMissing
    }
}

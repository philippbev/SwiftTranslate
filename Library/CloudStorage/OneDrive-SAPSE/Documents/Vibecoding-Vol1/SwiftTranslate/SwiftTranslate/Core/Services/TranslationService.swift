import Foundation
import Translation

/// Wraps Apple's Translation framework.
/// Translation must be triggered via SwiftUI's .translationTask modifier —
/// this service holds the configuration and exposes a simple async interface.
///
/// Design notes:
/// - A new Configuration is created for each request so SwiftUI's .translationTask
///   always fires (it only fires on identity changes, not value changes).
/// - We never call configuration.invalidate() — doing so prevents subsequent translations.
/// - Serial execution: we cancel any pending continuation before storing a new one
///   so there is never more than one in-flight request.
@available(macOS 15.0, *)
@Observable
@MainActor
final class TranslationService {

    var configuration: TranslationSession.Configuration?

    // MARK: - Private

    private var pendingContinuation: CheckedContinuation<String, Error>?
    private(set) var pendingText: String = ""

    // MARK: - Public API

    /// Request a translation. The SwiftUI view must have `.translationTask(configuration)` attached.
    func translate(text: String, from source: SupportedLanguage, to target: SupportedLanguage) async throws -> String {
        // Cancel any previous in-flight request gracefully.
        cancelPending()

        pendingText = text

        // Always create a brand-new Configuration so SwiftUI sees an identity change
        // and fires .translationTask even when the language pair is unchanged.
        configuration = TranslationSession.Configuration(
            source: Locale.Language(identifier: source.localeIdentifier),
            target: Locale.Language(identifier: target.localeIdentifier)
        )

        return try await withCheckedThrowingContinuation { continuation in
            pendingContinuation = continuation
        }
    }

    /// Called by the SwiftUI view's .translationTask handler with the live session.
    func performTranslation(session: TranslationSession) async {
        guard let continuation = pendingContinuation else { return }
        pendingContinuation = nil

        let text = pendingText

        do {
            let response = try await session.translate(text)
            continuation.resume(returning: response.targetText)
        } catch {
            continuation.resume(throwing: error)
        }
        // Note: do NOT call configuration.invalidate() here —
        // invalidating the configuration prevents SwiftUI from reusing the session
        // for the next request, causing all subsequent translations to silently fail.
    }

    // MARK: - Private helpers

    private func cancelPending() {
        if let continuation = pendingContinuation {
            pendingContinuation = nil
            continuation.resume(throwing: CancellationError())
        }
    }
}

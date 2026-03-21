import Testing
import Foundation
@testable import SwiftTranslate

// MARK: - LanguageDetector

@Suite("LanguageDetector")
struct LanguageDetectorTests {
    let d = LanguageDetector()

    @Test func detectsEnglish() { #expect(d.detect("The quick brown fox") == .english) }
    @Test func detectsGerman() { #expect(d.detect("Der schnelle braune Fuchs") == .german) }
    @Test func shortReturnsNil() { #expect(d.detect("Hi") == nil) }
    @Test func emptyReturnsNil() { #expect(d.detect("") == nil) }
}

// MARK: - HistoryStore

@Suite("HistoryStore")
struct HistoryStoreTests {
    func entry(_ s: String = "Hello") -> HistoryEntry {
        HistoryEntry(source: s, translation: "Hallo", from: .english, to: .german)
    }

    @Test @MainActor func addsEntry() { let s = HistoryStore(); s.clear(); s.add(entry()); #expect(s.entries.count == 1) }
    @Test @MainActor func newestFirst() { let s = HistoryStore(); s.clear(); s.add(entry("A")); s.add(entry("B")); #expect(s.entries.first?.source == "B") }
    @Test @MainActor func maxTen() { let s = HistoryStore(); s.clear(); (1...12).forEach { s.add(entry("T\($0)")) }; #expect(s.entries.count == 10) }
    @Test @MainActor func noDuplicates() { let s = HistoryStore(); s.clear(); s.add(entry()); s.add(entry()); #expect(s.entries.count == 1) }
    @Test @MainActor func clearWorks() { let s = HistoryStore(); s.add(entry()); s.clear(); #expect(s.entries.isEmpty) }
    @Test @MainActor func sameSourceDifferentDirectionKeptSeparate() {
        let s = HistoryStore(); s.clear()
        s.add(HistoryEntry(source: "Hello", translation: "Hallo", from: .english, to: .german))
        s.add(HistoryEntry(source: "Hello", translation: "Hallo", from: .german, to: .english))
        #expect(s.entries.count == 2)
    }
}

// MARK: - OnboardingStore

@Suite("OnboardingStore")
struct OnboardingStoreTests {
    private func makeStore() -> OnboardingStore {
        let suite = "test.onboarding.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return OnboardingStore(defaults: defaults)
    }

    @Test func defaultsToFalse() {
        #expect(makeStore().hasCompleted == false)
    }

    @Test func persistsCompletion() {
        let store = makeStore()
        store.hasCompleted = true
        #expect(store.hasCompleted == true)
    }

    @Test func resetClearsFlag() {
        let store = makeStore()
        store.hasCompleted = true
        store.reset()
        #expect(store.hasCompleted == false)
    }
}

// MARK: - Swap + Auto-Detect conflict

@Suite("AppState.swap")
struct AppStateSwapTests {

    @Test("Swap setzt manualLanguageSwap Flag")
    @MainActor func swapSetsManualFlag() {
        if #available(macOS 15.0, *) {
            let state = AppState()
            #expect(state.manualLanguageSwap == false)
            state.swap()
            #expect(state.manualLanguageSwap == true)
        }
    }

    @Test("Clear setzt Texte zurück")
    @MainActor func clearResetsText() {
        if #available(macOS 15.0, *) {
            let state = AppState()
            state.sourceText = "Hello"
            state.translatedText = "Hallo"
            state.clear()
            #expect(state.sourceText.isEmpty)
            #expect(state.translatedText.isEmpty)
        }
    }

    @Test("Swap tauscht Texte und Sprachen")
    @MainActor func swapExchangesContent() {
        if #available(macOS 15.0, *) {
            let state = AppState()
            state.sourceText = "Hello"
            state.translatedText = "Hallo"
            state.sourceLang = .english
            state.targetLang = .german
            state.swap()
            #expect(state.sourceText == "Hallo")
            #expect(state.translatedText == "Hello")
            #expect(state.sourceLang == .german)
            #expect(state.targetLang == .english)
        }
    }
}

import Testing
@testable import SwiftTranslate

// MARK: - LanguageDetector Tests

@Suite("LanguageDetector")
struct LanguageDetectorTests {
    let detector = LanguageDetector()

    @Test("Erkennt Englisch")
    func detectsEnglish() {
        let result = detector.detect("The quick brown fox jumps over the lazy dog")
        #expect(result == .english)
    }

    @Test("Erkennt Deutsch")
    func detectsGerman() {
        let result = detector.detect("Der schnelle braune Fuchs springt über den faulen Hund")
        #expect(result == .german)
    }

    @Test("Kurzer Text gibt nil zurück")
    func shortTextReturnsNil() {
        let result = detector.detect("Hi")
        #expect(result == nil)
    }

    @Test("Leerer Text gibt nil zurück")
    func emptyTextReturnsNil() {
        let result = detector.detect("")
        #expect(result == nil)
    }
}

// MARK: - HistoryStore Tests

@Suite("HistoryStore")
struct HistoryStoreTests {

    func makeEntry(source: String = "Hello") -> HistoryEntry {
        HistoryEntry(source: source, translation: "Hallo", from: .english, to: .german)
    }

    @Test("Eintrag wird hinzugefügt")
    func addEntry() {
        let store = HistoryStore()
        store.clear()
        store.add(makeEntry())
        #expect(store.entries.count == 1)
    }

    @Test("FIFO: Neuester Eintrag ist an erster Stelle")
    func newestEntryFirst() {
        let store = HistoryStore()
        store.clear()
        store.add(makeEntry(source: "First"))
        store.add(makeEntry(source: "Second"))
        #expect(store.entries.first?.source == "Second")
    }

    @Test("Maximal 10 Einträge")
    func maxTenEntries() {
        let store = HistoryStore()
        store.clear()
        for i in 1...12 {
            store.add(makeEntry(source: "Text \(i)"))
        }
        #expect(store.entries.count == 10)
    }

    @Test("Duplikat wird ersetzt, nicht dupliziert")
    func duplicateReplaced() {
        let store = HistoryStore()
        store.clear()
        store.add(makeEntry(source: "Hello"))
        store.add(makeEntry(source: "Hello"))
        #expect(store.entries.count == 1)
    }

    @Test("Clear leert alle Einträge")
    func clearRemovesAll() {
        let store = HistoryStore()
        store.add(makeEntry())
        store.clear()
        #expect(store.entries.isEmpty)
    }
}

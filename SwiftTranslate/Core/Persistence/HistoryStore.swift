import Foundation

@MainActor
protocol HistoryStoring: AnyObject {
    var entries: [HistoryEntry] { get }
    func add(_ entry: HistoryEntry)
    func clear()
}

@Observable
@MainActor
final class HistoryStore: HistoryStoring {
    private(set) var entries: [HistoryEntry] = []
    private let key = "history_v1"

    init() { load() }

    private let maxEntries = 10

    func add(_ entry: HistoryEntry) {
        entries.removeAll {
            $0.source == entry.source && $0.from == entry.from && $0.to == entry.to
        }
        entries.insert(entry, at: 0)
        if entries.count > maxEntries { entries = Array(entries.prefix(maxEntries)) }
        save()
    }

    func clear() { entries.removeAll(); save() }

    private func save() {
        if let d = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: d) {
            entries = decoded
        }
    }
}

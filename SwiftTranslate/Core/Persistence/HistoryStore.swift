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
    private let localKey = "history_v1"
    private let maxEntries = 50

    init() {
        load()
    }

    func add(_ entry: HistoryEntry) {
        entries.removeAll {
            $0.source == entry.source && $0.from == entry.from && $0.to == entry.to
        }
        entries.insert(entry, at: 0)
        if entries.count > maxEntries { entries = Array(entries.prefix(maxEntries)) }
        save()
    }

    func clear() { entries.removeAll(); save() }

    // MARK: - Private

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: localKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: localKey),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data)
        else { return }
        entries = decoded
    }
}

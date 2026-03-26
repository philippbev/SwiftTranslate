import Foundation
import OSLog

private let logger = Logger(subsystem: "com.philippbev.SwiftTranslate", category: "HistoryStore")

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
        if entries.count > maxEntries { entries.removeSubrange(maxEntries..<entries.endIndex) }
        save()
    }

    func clear() { entries.removeAll(); save() }

    // MARK: - Private

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: localKey)
        } catch {
            logger.error("HistoryStore.save failed: \(error, privacy: .public)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: localKey) else { return }
        do {
            entries = try JSONDecoder().decode([HistoryEntry].self, from: data)
        } catch {
            logger.error("HistoryStore.load failed: \(error, privacy: .public)")
        }
    }
}

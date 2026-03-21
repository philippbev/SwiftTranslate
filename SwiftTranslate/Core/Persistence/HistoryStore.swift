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
    private let iCloudKey = "history_icloud_v1"
    private let maxEntries = 50

    init() {
        load()
        observeICloudChanges()
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
        NSUbiquitousKeyValueStore.default.set(data, forKey: iCloudKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    private func load() {
        let local = loadEntries(from: UserDefaults.standard.data(forKey: localKey))
        let cloud = loadEntries(from: NSUbiquitousKeyValueStore.default.data(forKey: iCloudKey))
        entries = merged(local: local, cloud: cloud)
    }

    private func loadEntries(from data: Data?) -> [HistoryEntry] {
        guard let data,
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data)
        else { return [] }
        return decoded
    }

    /// Merge local and cloud entries: deduplicate by (source, from, to), sort newest first, cap at maxEntries.
    private func merged(local: [HistoryEntry], cloud: [HistoryEntry]) -> [HistoryEntry] {
        var seen = Set<String>()
        let combined = (local + cloud).sorted { $0.date > $1.date }
        return combined.filter { entry in
            let key = "\(entry.source)|\(entry.from.id)|\(entry.to.id)"
            return seen.insert(key).inserted
        }.prefix(maxEntries).map { $0 }
    }

    private func observeICloudChanges() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let keys = (notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]) ?? []
            if keys.contains(self.iCloudKey) {
                Task { @MainActor in self.load() }
            }
        }
    }
}

import Foundation
import Combine

enum SortOrder: String, CaseIterable {
    case alphabetical = "A–Z"
    case ratioAsc = "Wert ↑"
    case ratioDesc = "Wert ↓"
}

class SaarlandViewModel: ObservableObject {
    // MARK: - Saarland Constants
    let saarlandFlaeche: Double = 2569.69
    let saarlandBevoelkerung: Int = 986887
    let saarlandHauptstadt = "Saarbrücken"
    let saarlandBIP: Double = 35.7 // Mrd. EUR
    let saarlandDichte: Double = 384.1 // Ew/km²

    // MARK: - Published
    @Published var objects: [ComparisonObject] = []
    @Published var searchText: String = ""
    @Published var selectedKategorie: Kategorie? = nil
    @Published var sortOrder: SortOrder = .ratioAsc
    @Published var randomObject: ComparisonObject? = nil
    @Published var favoriteIDs: Set<Int> = []
    @Published var showFavoritesOnly: Bool = false

    private static let favoritesKey = "favorite_ids_v1"
    private static let viewedKey = "viewed_ids_v1"

    @Published var viewedIDs: Set<Int> = []

    var viewedCount: Int { viewedIDs.count }
    var totalCount: Int { objects.count }
    var meterProgress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(viewedCount) / Double(totalCount)
    }

    var meterTitle: String {
        switch meterProgress {
        case 0:            return "Noch kein Objekt angeschaut"
        case ..<0.1:       return "Frischling 🐣"
        case ..<0.25:      return "Saarland-Neuling"
        case ..<0.5:       return "Saarland-Kenner"
        case ..<0.75:      return "Saarland-Fan 🏳️"
        case ..<1.0:       return "Fast-Experte!"
        default:           return "Saarland-Experte 🏆"
        }
    }

    init() {
        loadData()
        randomObject = objects.randomElement()
        loadFavorites()
        loadViewed()
    }

    func loadData() {
        guard let url = Bundle.main.url(forResource: "vergleichsobjekte", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ComparisonObject].self, from: data)
        else {
            objects = []
            return
        }
        objects = decoded
    }

    func ratio(for object: ComparisonObject) -> Double {
        object.ratio
    }

    func formatRatio(_ ratio: Double) -> String {
        if ratio < 0.0001 {
            return String(format: "%.6f", ratio)
        } else if ratio < 0.01 {
            return String(format: "%.4f", ratio)
        } else if ratio < 10 {
            return String(format: "%.1f", ratio)
        } else if ratio < 1000 {
            return String(format: "%.0f", ratio)
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            formatter.locale = Locale(identifier: "de_DE")
            return formatter.string(from: NSNumber(value: ratio)) ?? String(format: "%.0f", ratio)
        }
    }

    func formatValue(_ value: Double, einheit: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "de_DE")
        let absVal = abs(value)
        if absVal == 0 { return "0 \(einheit)" }
        if absVal < 0.01 {
            formatter.maximumFractionDigits = 4
        } else if absVal < 1 {
            formatter.maximumFractionDigits = 2
        } else if absVal < 1000 {
            formatter.maximumFractionDigits = 1
        } else {
            formatter.maximumFractionDigits = 0
        }
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(formatted) \(einheit)"
    }

    func formatArea(_ km2: Double) -> String {
        formatValue(km2, einheit: "km²")
    }

    func comparisonText(for object: ComparisonObject) -> String {
        let r = ratio(for: object)
        let name = object.name
        switch object.kategorieEnum {
        case .flaeche:
            return r < 1
                ? "Das Saarland ist \(formatRatio(1/r))× größer als \(name)"
                : "In \(name) passen \(formatRatio(r))× Saarlande rein"
        case .gewicht:
            return r < 1
                ? "Die Völklinger Hütte ist \(formatRatio(1/r))× schwerer als \(name)"
                : "\(name) ist \(formatRatio(r))× schwerer als die Völklinger Hütte"
        case .zeit:
            return r < 1
                ? "Das Saarland ist \(formatRatio(1/r))× älter als \(name) dauert"
                : "\(name) ist \(formatRatio(r))× länger als das Saarland ein Bundesland ist"
        case .geld:
            return r < 1
                ? "Das Saarland-BIP ist \(formatRatio(1/r))× mehr als \(name) kostet"
                : "\(name) entspricht \(formatRatio(r))× dem Saarland-Jahresbudget"
        case .laenge:
            return r < 1
                ? "Die Saarland-Flüsse sind \(formatRatio(1/r))× länger als \(name)"
                : "\(name) ist \(formatRatio(r))× länger als alle Saarland-Flüsse zusammen"
        case .anzahl:
            return r < 1
                ? "Das Saarland hat \(formatRatio(1/r))× mehr Einwohner als \(name)"
                : "\(name) übertrifft die Saarland-Bevölkerung um Faktor \(formatRatio(r))"
        case .volumen:
            return r < 1
                ? "Der Bostalsee fasst \(formatRatio(1/r))× mehr als \(name)"
                : "\(name) fasst \(formatRatio(r))× so viel wie der Bostalsee"
        }
    }

    func randomFact() -> String {
        guard let obj = randomObject else { return "Keine Daten verfügbar." }
        return "\(obj.emoji) \(comparisonText(for: obj)). \(obj.name): \(formatValue(obj.wert, einheit: obj.einheit))."
    }

    func refreshRandom() {
        let filtered = objects.filter { $0.id != randomObject?.id }
        randomObject = filtered.randomElement() ?? objects.randomElement()
    }

    // MARK: - Favorites
    func isFavorite(_ object: ComparisonObject) -> Bool {
        favoriteIDs.contains(object.id)
    }

    func toggleFavorite(_ object: ComparisonObject) {
        if favoriteIDs.contains(object.id) {
            favoriteIDs.remove(object.id)
        } else {
            favoriteIDs.insert(object.id)
        }
        saveFavorites()
    }

    func markViewed(_ object: ComparisonObject) {
        guard !viewedIDs.contains(object.id) else { return }
        viewedIDs.insert(object.id)
        saveViewed()
    }

    private func saveViewed() {
        UserDefaults.standard.set(Array(viewedIDs), forKey: Self.viewedKey)
    }

    private func loadViewed() {
        let stored = UserDefaults.standard.array(forKey: Self.viewedKey) as? [Int] ?? []
        viewedIDs = Set(stored)
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIDs), forKey: Self.favoritesKey)
    }

    private func loadFavorites() {
        let stored = UserDefaults.standard.array(forKey: Self.favoritesKey) as? [Int] ?? []
        favoriteIDs = Set(stored)
    }

    var filteredObjects: [ComparisonObject] {
        var result = objects
        if showFavoritesOnly {
            result = result.filter { favoriteIDs.contains($0.id) }
        }
        if let kategorie = selectedKategorie {
            result = result.filter { $0.kategorie == kategorie.rawValue }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        switch sortOrder {
        case .alphabetical:
            result.sort { $0.name < $1.name }
        case .ratioAsc:
            result.sort { $0.ratio < $1.ratio }
        case .ratioDesc:
            result.sort { $0.ratio > $1.ratio }
        }
        return result
    }

    var groupedObjects: [(Kategorie, [ComparisonObject])] {
        Kategorie.allCases.compactMap { kat in
            let items = filteredObjects.filter { $0.kategorie == kat.rawValue }
            return items.isEmpty ? nil : (kat, items)
        }
    }
}

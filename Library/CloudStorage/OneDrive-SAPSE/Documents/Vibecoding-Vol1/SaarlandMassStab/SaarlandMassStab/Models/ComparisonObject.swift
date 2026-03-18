import Foundation

enum Kategorie: String, CaseIterable, Codable {
    case flaeche = "Fläche"
    case gewicht = "Gewicht"
    case zeit = "Zeit"
    case geld = "Geld"
    case laenge = "Länge"
    case anzahl = "Anzahl"
    case volumen = "Volumen"

    var emoji: String {
        switch self {
        case .flaeche: return "🗺️"
        case .gewicht: return "⚖️"
        case .zeit: return "⏱️"
        case .geld: return "💰"
        case .laenge: return "📏"
        case .anzahl: return "🔢"
        case .volumen: return "🧊"
        }
    }
}

struct ComparisonObject: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let wert: Double
    let einheit: String
    let kategorie: String
    let emoji: String
    let quellenhinweis: String
    let saarlandWert: Double

    var kategorieEnum: Kategorie {
        Kategorie(rawValue: kategorie) ?? .flaeche
    }

    var ratio: Double { wert / saarlandWert }
}

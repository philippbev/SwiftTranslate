import Foundation
import FoundationModels

enum ModelAvailabilityState {
    case available
    case unavailable(String)
}

struct KIHistoryEntry: Codable, Identifiable {
    let id: UUID
    let input: String
    let result: String
    let date: Date
}

// MARK: - Dimension

enum KIDimension {
    case flaeche   // m²         — Saarland = 2.569.690.000 m²
    case gewicht   // kg         — Völklinger Hütte ≈ 3.400.000.000 kg (3,4 Mrd.)
    case zeit      // Sekunden   — 67 Jahre ≈ 2.113.920.000 s
    case geld      // Euro       — Saarland BIP = 35.700.000.000 €
    case laenge    // Meter      — Saarland Flüsse gesamt ≈ 347.000 m
    case anzahl    // Stück      — Einwohner 986.887
    case volumen   // Liter      — Bostalsee ≈ 2.500.000.000 l

    var saarlandWert: Double {
        switch self {
        case .flaeche:  return 2_569_690_000.0
        case .gewicht:  return 3_400_000_000.0
        case .zeit:     return 2_113_920_000.0
        case .geld:     return 35_700_000_000.0
        case .laenge:   return 347_000.0
        case .anzahl:   return 986_887.0
        case .volumen:  return 2_500_000_000.0
        }
    }

    var saarlandLabel: String {
        switch self {
        case .flaeche:  return "Saarland (Fläche)"
        case .gewicht:  return "Völklinger Hütte (Gewicht)"
        case .zeit:     return "Saarland als Bundesland (67 J.)"
        case .geld:     return "Saarland-BIP"
        case .laenge:   return "Saarland-Flüsse (gesamt)"
        case .anzahl:   return "Saarland-Bevölkerung"
        case .volumen:  return "Bostalsee (Volumen)"
        }
    }

    func formatWert(_ wert: Double) -> String {
        switch self {
        case .flaeche:
            if wert < 1 { return String(format: "%.0f cm²", wert * 10000) }
            if wert < 10000 { return String(format: "%.1f m²", wert) }
            let km2 = wert / 1_000_000
            return km2 < 1000 ? String(format: "%.2f km²", km2) : String(format: "%.0f km²", km2)
        case .gewicht:
            if wert < 1000 { return String(format: "%.1f g", wert / 1000 * 1000) }
            if wert < 1_000_000 { return String(format: "%.1f kg", wert / 1000) }
            if wert < 1_000_000_000 { return String(format: "%.1f t", wert / 1_000_000) }
            return String(format: "%.1f Mio. t", wert / 1_000_000_000)
        case .zeit:
            if wert < 60 { return String(format: "%.0f Sekunden", wert) }
            if wert < 3600 { return String(format: "%.0f Minuten", wert / 60) }
            if wert < 86400 { return String(format: "%.1f Stunden", wert / 3600) }
            if wert < 31_536_000 { return String(format: "%.0f Tage", wert / 86400) }
            return String(format: "%.1f Jahre", wert / 31_536_000)
        case .geld:
            if wert < 1000 { return String(format: "%.2f €", wert) }
            if wert < 1_000_000 { return String(format: "%.0f €", wert) }
            if wert < 1_000_000_000 { return String(format: "%.1f Mio. €", wert / 1_000_000) }
            return String(format: "%.1f Mrd. €", wert / 1_000_000_000)
        case .laenge:
            if wert < 1 { return String(format: "%.1f cm", wert * 100) }
            if wert < 1000 { return String(format: "%.1f m", wert) }
            return String(format: "%.1f km", wert / 1000)
        case .anzahl:
            if wert < 1000 { return String(format: "%.0f", wert) }
            if wert < 1_000_000 { return String(format: "%.0f.000", wert / 1000) }
            return String(format: "%.1f Mio.", wert / 1_000_000)
        case .volumen:
            if wert < 1 { return String(format: "%.2f ml", wert * 1000) }
            if wert < 1000 { return String(format: "%.1f l", wert) }
            if wert < 1_000_000 { return String(format: "%.0f l", wert) }
            if wert < 1_000_000_000 { return String(format: "%.1f Mio. l", wert / 1_000_000) }
            return String(format: "%.1f Mrd. l", wert / 1_000_000_000)
        }
    }

    func comparisonLabel(name: String, wert: Double, ratio: Double, ratioStr: String) -> String {
        let cap = name.prefix(1).uppercased() + name.dropFirst()
        let wertStr = formatWert(wert)
        let saarStr = formatWert(saarlandWert)
        switch self {
        case .flaeche:
            return ratio >= 1
                ? "\(cap) hat eine Fläche von ca. \(wertStr). Das ist \(ratioStr)× die Fläche des Saarlandes (\(saarStr))."
                : "\(cap) hat eine Fläche von ca. \(wertStr). Das Saarland (\(saarStr)) ist \(ratioStr)× größer."
        case .gewicht:
            return ratio >= 1
                ? "\(cap) wiegt ca. \(wertStr) – das ist \(ratioStr)× so viel wie die gesamte Völklinger Hütte (\(saarStr))."
                : "\(cap) wiegt ca. \(wertStr). Die Völklinger Hütte (\(saarStr)) bringt \(ratioStr)× mehr auf die Waage."
        case .zeit:
            return ratio >= 1
                ? "\(cap) dauert ca. \(wertStr) – das sind \(ratioStr)× so lang wie das Saarland schon Bundesland ist (\(saarStr))."
                : "\(cap) dauert ca. \(wertStr). Das Saarland existiert als Bundesland (\(saarStr)) schon \(ratioStr)× länger."
        case .geld:
            return ratio >= 1
                ? "\(cap) kostet ca. \(wertStr) – das entspricht \(ratioStr)× dem gesamten Saarland-BIP (\(saarStr))."
                : "\(cap) kostet ca. \(wertStr). Das Saarland-BIP (\(saarStr)) ist \(ratioStr)× höher."
        case .laenge:
            return ratio >= 1
                ? "\(cap) ist ca. \(wertStr) lang – das sind \(ratioStr)× alle Saarland-Flüsse zusammen (\(saarStr))."
                : "\(cap) ist ca. \(wertStr) lang. Alle Saarland-Flüsse zusammen (\(saarStr)) sind \(ratioStr)× länger."
        case .anzahl:
            return ratio >= 1
                ? "\(cap) hat ca. \(wertStr) – das sind \(ratioStr)× so viele wie Saarland-Einwohner (\(saarStr))."
                : "\(cap) hat ca. \(wertStr). Das Saarland hat \(ratioStr)× mehr Einwohner (\(saarStr))."
        case .volumen:
            return ratio >= 1
                ? "\(cap) fasst ca. \(wertStr) – das ist \(ratioStr)× so viel wie der Bostalsee (\(saarStr))."
                : "\(cap) fasst ca. \(wertStr). Der Bostalsee (\(saarStr)) fasst \(ratioStr)× mehr."
        }
    }
}

// MARK: - KnownObject

private struct KnownObject {
    let keywords: [String]
    let wert: Double        // in der Basiseinheit der Dimension
    let dimension: KIDimension
    let label: String
    let witz: String
}

@MainActor
class KIVergleichViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var result: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var modelState: ModelAvailabilityState = .available
    @Published var history: [KIHistoryEntry] = []

    private static let historyKey = "ki_history_v1"

    private static let systemPrompt = """
    Du bist ein humorvoller saarländischer Allround-Komödiant. Deine Aufgabe: \
    Vergleiche ein vom Nutzer genanntes Objekt mit dem Saarland – aber NICHT immer nur nach Fläche! \
    Wähle die passende Dimension: Fläche (km²), Gewicht (kg), Zeit (Jahre/Sekunden), \
    Geld (€), Länge (km/m), Anzahl (Stück/Personen) oder Volumen (Liter/m³). \
    Referenzwerte: Fläche=2569,69 km², Gewicht=3,4 Mrd. t (Völklinger Hütte), \
    Zeit=67 Jahre (Bundesland seit 1957), BIP=35,7 Mrd. €, Flüsse=347 km, \
    Einwohner=986.887, Bostalsee=2,5 Mrd. Liter.

    Regeln: Nur Deutsch. Maximal 4 Sätze. Sei konkret mit Zahlen. \
    Kein Markdown. Liebevoll-sarkastischer Abschlusssatz über das Saarland.
    """

    // MARK: - Bekannte Objekte (Multi-Dimension)

    private static let knownObjects: [KnownObject] = [

        // FLÄCHE (m²)
        KnownObject(keywords: ["fiat", "panda"], wert: 7.7, dimension: .flaeche, label: "Grundfläche", witz: "Das Saarland als Parkplatz hätte historische Ausmaße."),
        KnownObject(keywords: ["auto", "pkw", "wagen", "car", "golf", "polo", "passat"], wert: 8.0, dimension: .flaeche, label: "Grundfläche", witz: "Die Saarländer fahren übrigens lieber Auto. Bergauf. Immer."),
        KnownObject(keywords: ["fahrrad", "bike", "rad"], wert: 1.8, dimension: .flaeche, label: "Standfläche", witz: "Saarländer fahren übrigens lieber Auto. Bergauf. Immer."),
        KnownObject(keywords: ["motorrad", "moped", "roller"], wert: 2.2, dimension: .flaeche, label: "Standfläche", witz: "Das Saarland als Motorrad-Parkplatz – die Saar-Kurve wäre beliebt."),
        KnownObject(keywords: ["bus", "reisebus"], wert: 32.0, dimension: .flaeche, label: "Grundfläche", witz: "Ein Saarland voller Busse – der ÖPNV käme ins Grübeln."),
        KnownObject(keywords: ["lkw", "truck", "lastwagen", "sattelzug"], wert: 50.0, dimension: .flaeche, label: "Grundfläche", witz: "Logistisch gesehen wäre das Saarland ein sehr großes Amazon-Lager."),
        KnownObject(keywords: ["flugzeug", "boeing", "airbus", "a380", "a320"], wert: 845.0, dimension: .flaeche, label: "Grundfläche", witz: "Das Saarland als Flughafen: Saarbrücken hätte endlich Direktflüge nach München."),
        KnownObject(keywords: ["pizza"], wert: 0.071, dimension: .flaeche, label: "Fläche", witz: "Das Saarland als Pizzaland – die Idee ist eigentlich gut."),
        KnownObject(keywords: ["fußballfeld", "fussballfeld", "sportplatz"], wert: 7140.0, dimension: .flaeche, label: "Spielfläche", witz: "Der 1. FC Saarbrücken freut sich über die Auswahl."),
        KnownObject(keywords: ["vatikan", "vatican"], wert: 440_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Mehr Päpste pro km² hat trotzdem der Vatikan."),
        KnownObject(keywords: ["disneyland", "disney", "freizeitpark"], wert: 22_300_000.0, dimension: .flaeche, label: "Gesamtfläche", witz: "Das Saarland verarbeitet das noch."),
        KnownObject(keywords: ["central park", "centralpark"], wert: 3_410_000.0, dimension: .flaeche, label: "Parkfläche", witz: "Der Central Park hat trotzdem mehr Eichhörnchen."),
        KnownObject(keywords: ["saarschleife", "mettlach"], wert: 100_000.0, dimension: .flaeche, label: "umschlossene Fläche", witz: "Die Saarschleife ist das schönste Fotomotiv des Saarlandes. Das Foto bleibt das Gleiche."),
        KnownObject(keywords: ["solarpanel", "solar", "photovoltaik"], wert: 1.7, dimension: .flaeche, label: "Fläche", witz: "Das Saarland als Solarpark würde ganz Deutschland mit Strom versorgen – und noch Luxemburg dazu."),
        KnownObject(keywords: ["briefmarke"], wert: 0.0006, dimension: .flaeche, label: "Fläche", witz: "Das Saarland war mal ein eigenes Land mit eigenen Briefmarken. Das vergisst es nicht."),
        KnownObject(keywords: ["iphone", "smartphone", "handy", "samsung"], wert: 0.012, dimension: .flaeche, label: "Displayfläche", witz: "Das Saarland auf dem Bildschirm anzuzeigen braucht sehr viele Pixel."),
        KnownObject(keywords: ["ikea"], wert: 27_000.0, dimension: .flaeche, label: "Verkaufsfläche", witz: "Die Billy-Regal-Abteilung wäre in Saarlouis."),
        KnownObject(keywords: ["flughafen", "airport"], wert: 22_600_000.0, dimension: .flaeche, label: "Gesamtfläche", witz: "Das Saarland hat trotzdem weniger Verspätungen als Frankfurt."),

        // FLÄCHE — Deutsche Städte (m²)
        KnownObject(keywords: ["kaiserslautern"], wert: 139_730_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Der FCK grüßt. Das Saarland ist fast 18× so groß."),
        KnownObject(keywords: ["berlin"], wert: 891_800_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Berlin ist 3× so groß wie das Saarland – aber hat deutlich mehr Hipster."),
        KnownObject(keywords: ["münchen", "munich"], wert: 310_700_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "München ist etwas kleiner als das Saarland. Aber teurer."),
        KnownObject(keywords: ["hamburg"], wert: 755_200_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Hamburg ist fast 3× so groß wie das Saarland. Und hat mehr Regen."),
        KnownObject(keywords: ["köln", "koeln"], wert: 405_200_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Köln ist fast so groß wie das Saarland. Der Dom passt trotzdem rein."),
        KnownObject(keywords: ["frankfurt"], wert: 248_300_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Frankfurt ist ca. 10× kleiner als das Saarland. Der Flughafen zählt mit."),
        KnownObject(keywords: ["stuttgart"], wert: 207_400_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Stuttgart passt 12× ins Saarland. Schwaben nicken."),
        KnownObject(keywords: ["düsseldorf", "dusseldorf"], wert: 217_000_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Düsseldorf ist knapp 12× kleiner als das Saarland. Mehr Schicki-Micki geht nicht."),
        KnownObject(keywords: ["leipzig"], wert: 297_800_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Leipzig passt ca. 9× ins Saarland. Das Saarland ist beeindruckt."),
        KnownObject(keywords: ["dresden"], wert: 328_300_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Dresden ist ca. 8× kleiner als das Saarland. Barock bleibt barock."),
        KnownObject(keywords: ["hannover"], wert: 204_000_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Hannover passt 13× ins Saarland. Der Messe-Komplex wäre in Saarlouis."),
        KnownObject(keywords: ["nürnberg", "nurnberg", "nuernberg"], wert: 186_400_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Nürnberg ist 14× kleiner als das Saarland. Lebkuchen inklusive."),
        KnownObject(keywords: ["bremen"], wert: 318_200_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Bremen passt ca. 8× ins Saarland. Die Stadtmusikanten kommen mit."),
        KnownObject(keywords: ["saarbrücken", "saarbruecken"], wert: 167_000_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Die Hauptstadt passt 15× ins eigene Bundesland. Haupsach gudd gess."),
        KnownObject(keywords: ["saarlouis"], wert: 42_000_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Saarlouis passt ca. 61× ins Saarland. Klein aber fein."),
        KnownObject(keywords: ["homburg"], wert: 82_700_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Homburg passt 31× ins Saarland. Die Uni grüßt."),
        KnownObject(keywords: ["neunkirchen"], wert: 49_400_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Neunkirchen passt 52× ins Saarland. Das Saarland nimmt das zur Kenntnis."),
        KnownObject(keywords: ["trier"], wert: 117_100_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Trier ist 22× kleiner als das Saarland. Die Römer wären überrascht."),
        KnownObject(keywords: ["koblenz"], wert: 105_000_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Koblenz passt 24× ins Saarland. Das Deutsche Eck liegt außerhalb."),
        KnownObject(keywords: ["mannheim"], wert: 144_900_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Mannheim passt 18× ins Saarland. Das Quadrat-System bleibt trotzdem Mannheim."),
        KnownObject(keywords: ["heidelberg"], wert: 108_800_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Heidelberg passt 24× ins Saarland. Das Schloss kommt mit."),
        KnownObject(keywords: ["freiburg"], wert: 153_100_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Freiburg passt 17× ins Saarland. Sonnenschein inklusive."),
        KnownObject(keywords: ["augsburg"], wert: 146_900_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Augsburg passt 17× ins Saarland. Die Fugger wären beeindruckt."),
        KnownObject(keywords: ["bonn"], wert: 141_200_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Bonn passt 18× ins Saarland. Die alte Hauptstadt nimmt das gelassen."),
        KnownObject(keywords: ["wiesbaden"], wert: 203_900_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Wiesbaden passt 13× ins Saarland. Kurstadt-Flair inklusive."),
        KnownObject(keywords: ["mainz"], wert: 97_700_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Mainz passt 26× ins Saarland. Gutenberg grüßt herzlich."),
        KnownObject(keywords: ["karlsruhe"], wert: 173_500_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Karlsruhe passt 15× ins Saarland. Der Bundesgerichtshof auch."),

        // FLÄCHE — Internationale Städte (m²)
        KnownObject(keywords: ["new york", "new york city", "nyc"], wert: 783_800_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "New York City ist ca. 3× kleiner als das Saarland. Der Big Apple hat trotzdem mehr Taxi."),
        KnownObject(keywords: ["london"], wert: 1_572_000_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Groß-London ist fast so groß wie das Saarland. Aber es regnet mehr."),
        KnownObject(keywords: ["paris"], wert: 105_400_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Paris (Stadt) passt 24× ins Saarland. Die Baguettes bleiben trotzdem in Paris."),
        KnownObject(keywords: ["rom", "rome", "roma"], wert: 1_285_000_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Rom ist halb so groß wie das Saarland. Alle Wege führen trotzdem dorthin."),
        KnownObject(keywords: ["madrid"], wert: 604_300_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Madrid passt ca. 4× ins Saarland. Real Madrid ist trotzdem größer."),
        KnownObject(keywords: ["wien", "vienna"], wert: 414_900_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Wien passt ca. 6× ins Saarland. Der Walzer bleibt trotzdem in Wien."),
        KnownObject(keywords: ["amsterdam"], wert: 219_300_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Amsterdam passt 12× ins Saarland. Die Grachten allerdings nicht."),
        KnownObject(keywords: ["tokio", "tokyo"], wert: 2_194_000_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Tokio ist fast so groß wie das Saarland. 14 Millionen Menschen passen rein."),
        KnownObject(keywords: ["dubai"], wert: 4_114_000_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Dubai ist 1,6× so groß wie das Saarland. Aber deutlich heißer."),
        KnownObject(keywords: ["singapur", "singapore"], wert: 733_100_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Singapur passt ca. 3,5× ins Saarland. Ein Stadtstaat macht Eindruck."),
        KnownObject(keywords: ["sydney"], wert: 12_368_000_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Sydney ist fast 5× so groß wie das Saarland. Das Opernhaus kommt mit."),
        KnownObject(keywords: ["moskau", "moscow"], wert: 2_561_500_000.0, dimension: .flaeche, label: "Stadtfläche", witz: "Moskau ist fast exakt so groß wie das Saarland. Selten so eine Übereinstimmung."),

        // FLÄCHE — Deutsche Bundesländer (m²)
        KnownObject(keywords: ["bayern", "bavaria"], wert: 70_542_000_000.0, dimension: .flaeche, label: "Bundeslandfläche", witz: "Bayern ist 27× so groß wie das Saarland. Und ungefähr so selbstbewusst."),
        KnownObject(keywords: ["nordrhein-westfalen", "nrw", "nordrhein westfalen"], wert: 34_113_000_000.0, dimension: .flaeche, label: "Bundeslandfläche", witz: "NRW ist 13× so groß wie das Saarland. Dafür hat das Saarland bessere Lyoner."),
        KnownObject(keywords: ["baden-württemberg", "bawü", "badenwürttemberg"], wert: 35_748_000_000.0, dimension: .flaeche, label: "Bundeslandfläche", witz: "Baden-Württemberg ist 14× so groß wie das Saarland. Wir schauen bescheiden zu."),
        KnownObject(keywords: ["niedersachsen"], wert: 47_710_000_000.0, dimension: .flaeche, label: "Bundeslandfläche", witz: "Niedersachsen ist 18× so groß wie das Saarland. Flach, aber respektabel."),
        KnownObject(keywords: ["hessen"], wert: 21_115_000_000.0, dimension: .flaeche, label: "Bundeslandfläche", witz: "Hessen ist 8× so groß wie das Saarland. Äbbelwoi zum Vergleich."),
        KnownObject(keywords: ["rheinland-pfalz", "rheinlandpfalz", "rlp"], wert: 19_858_000_000.0, dimension: .flaeche, label: "Bundeslandfläche", witz: "Rheinland-Pfalz ist 7,7× so groß wie das Saarland. Gute Nachbarn."),
        KnownObject(keywords: ["sachsen"], wert: 18_450_000_000.0, dimension: .flaeche, label: "Bundeslandfläche", witz: "Sachsen ist 7× so groß wie das Saarland. Dresdner Stollen inklusive."),
        KnownObject(keywords: ["thüringen", "thueringen"], wert: 16_202_000_000.0, dimension: .flaeche, label: "Bundeslandfläche", witz: "Thüringen ist 6,3× so groß wie das Saarland. Bratwurst inklusive."),
        KnownObject(keywords: ["brandenburg"], wert: 29_654_000_000.0, dimension: .flaeche, label: "Bundeslandfläche", witz: "Brandenburg ist 11,5× so groß wie das Saarland. Sehr viel Kiefernwald."),
        KnownObject(keywords: ["sachsen-anhalt", "sachsenanhalt"], wert: 20_452_000_000.0, dimension: .flaeche, label: "Bundeslandfläche", witz: "Sachsen-Anhalt ist 8× so groß wie das Saarland. Das Saarland kennt seine Grenzen."),
        KnownObject(keywords: ["mecklenburg", "mecklenburg-vorpommern"], wert: 23_295_000_000.0, dimension: .flaeche, label: "Bundeslandfläche", witz: "MV ist 9× so groß wie das Saarland. Aber hat weniger Lyoner."),
        KnownObject(keywords: ["schleswig-holstein", "schleswigholstein"], wert: 15_804_000_000.0, dimension: .flaeche, label: "Bundeslandfläche", witz: "Schleswig-Holstein ist 6× so groß wie das Saarland. Und hat zwei Küsten."),

        // FLÄCHE — Länder (m²)
        KnownObject(keywords: ["frankreich", "france"], wert: 551_695_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Frankreich ist 214× so groß wie das Saarland. Direkte Nachbarn bleiben sie trotzdem."),
        KnownObject(keywords: ["österreich", "austria", "oesterreich"], wert: 83_871_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Österreich ist 32,6× so groß wie das Saarland. Schnitzel inklusive."),
        KnownObject(keywords: ["schweiz", "switzerland"], wert: 41_285_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Die Schweiz ist 16× so groß wie das Saarland. Aber teurer."),
        KnownObject(keywords: ["luxemburg", "luxembourg"], wert: 2_586_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Luxemburg ist fast exakt so groß wie das Saarland. Kein Wunder, dass sie sich gut verstehen."),
        KnownObject(keywords: ["belgien", "belgium"], wert: 30_528_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Belgien ist 11,9× so groß wie das Saarland. Und hat doppelt so viele Sprachen."),
        KnownObject(keywords: ["niederlande", "holland", "netherlands"], wert: 41_543_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Die Niederlande sind 16× so groß wie das Saarland. Aber flacher."),
        KnownObject(keywords: ["italien", "italy"], wert: 301_340_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Italien ist 117× so groß wie das Saarland. Pasta wächst trotzdem nicht hier."),
        KnownObject(keywords: ["spanien", "spain"], wert: 505_990_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Spanien ist 197× so groß wie das Saarland. Siesta gibt es hier trotzdem."),
        KnownObject(keywords: ["usa", "vereinigte staaten", "united states", "america"], wert: 9_834_000_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Die USA sind 3,8 Millionen Mal größer als das Saarland. Das Saarland bleibt entspannt."),
        KnownObject(keywords: ["china"], wert: 9_597_000_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "China ist 3,7 Millionen Mal größer als das Saarland. Die Mauer ist trotzdem eindrucksvoll."),
        KnownObject(keywords: ["russland", "russia"], wert: 17_098_000_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Russland ist 6,6 Millionen Mal größer als das Saarland. Das Saarland zählt trotzdem."),
        KnownObject(keywords: ["kanada", "canada"], wert: 9_985_000_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Kanada ist 3,9 Millionen Mal größer als das Saarland. Sorry."),
        KnownObject(keywords: ["australien", "australia"], wert: 7_692_000_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Australien ist fast 3 Millionen Mal größer als das Saarland. Und deutlich giftiger."),
        KnownObject(keywords: ["brasilien", "brazil"], wert: 8_516_000_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Brasilien ist 3,3 Millionen Mal größer als das Saarland. Samba bleibt trotzdem in Rio."),
        KnownObject(keywords: ["indien", "india"], wert: 3_287_000_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Indien ist 1,28 Millionen Mal größer als das Saarland. Das Saarland ist überrascht."),
        KnownObject(keywords: ["japan"], wert: 377_975_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Japan ist 147× so groß wie das Saarland. Manga und Sushi passen trotzdem nicht rein."),
        KnownObject(keywords: ["griechenland", "greece"], wert: 131_957_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Griechenland ist 51× so groß wie das Saarland. Gyros inklusive."),
        KnownObject(keywords: ["portugal"], wert: 92_212_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Portugal ist 35,9× so groß wie das Saarland. Fado vom Atlantik."),
        KnownObject(keywords: ["polen", "poland"], wert: 312_696_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Polen ist 121× so groß wie das Saarland. Guter Nachbar im Osten."),
        KnownObject(keywords: ["ukraine"], wert: 603_550_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Die Ukraine ist 234× so groß wie das Saarland. Das Saarland denkt mit."),
        KnownObject(keywords: ["türkei", "turkey", "turkei"], wert: 783_562_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Die Türkei ist 304× so groß wie das Saarland. Döner kommt trotzdem von dort."),
        KnownObject(keywords: ["island", "iceland"], wert: 103_000_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Island ist 40× so groß wie das Saarland. Und hat mehr Vulkane."),
        KnownObject(keywords: ["irland", "ireland"], wert: 70_273_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Irland ist 27× so groß wie das Saarland. Guinness kommt trotzdem von dort."),
        KnownObject(keywords: ["dänemark", "denmark", "daenemark"], wert: 42_924_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Dänemark ist 16,7× so groß wie das Saarland. Lego auch."),
        KnownObject(keywords: ["norwegen", "norway"], wert: 385_207_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Norwegen ist 150× so groß wie das Saarland. Und deutlich kälter."),
        KnownObject(keywords: ["schweden", "sweden"], wert: 450_295_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Schweden ist 175× so groß wie das Saarland. IKEA und Köttbullar inklusive."),
        KnownObject(keywords: ["finnland", "finland"], wert: 338_455_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Finnland ist 131× so groß wie das Saarland. Sehr viele Seen."),
        KnownObject(keywords: ["kroatien", "croatia"], wert: 56_594_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Kroatien ist 22× so groß wie das Saarland. Die Adria-Küste auch."),
        KnownObject(keywords: ["tschechien", "tschechische republik", "czech"], wert: 78_868_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Tschechien ist 30,7× so groß wie das Saarland. Bier inklusive."),
        KnownObject(keywords: ["südkorea", "korea", "south korea"], wert: 100_410_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Südkorea ist 39× so groß wie das Saarland. K-Pop nicht inklusive."),
        KnownObject(keywords: ["mexiko", "mexico"], wert: 1_964_375_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Mexiko ist 764× so groß wie das Saarland. Tacos kommen trotzdem aus Mexiko."),
        KnownObject(keywords: ["argentinien", "argentina"], wert: 2_780_400_000_000.0, dimension: .flaeche, label: "Staatsfläche", witz: "Argentinien ist 1.082× so groß wie das Saarland. Messi ist trotzdem kleiner."),

        // FLÄCHE — Inseln & Regionen (m²)
        KnownObject(keywords: ["mallorca", "majorca"], wert: 3_640_000_000.0, dimension: .flaeche, label: "Inselfläche", witz: "Mallorca ist 1,4× so groß wie das Saarland. Ballermann inklusive."),
        KnownObject(keywords: ["sylt"], wert: 99_140_000.0, dimension: .flaeche, label: "Inselfläche", witz: "Sylt passt 26× ins Saarland. Friesennerz bleibt dort."),
        KnownObject(keywords: ["rügen"], wert: 926_400_000.0, dimension: .flaeche, label: "Inselfläche", witz: "Rügen passt ca. 2,8× ins Saarland. Kreidefelsen inklusive."),
        KnownObject(keywords: ["helgoland"], wert: 1_700_000.0, dimension: .flaeche, label: "Inselfläche", witz: "Helgoland passt 1.512× ins Saarland. Hummer bleibt trotzdem teuer."),
        KnownObject(keywords: ["korsika", "corsica"], wert: 8_680_000_000.0, dimension: .flaeche, label: "Inselfläche", witz: "Korsika ist 3,4× so groß wie das Saarland. Napoleon stammt daher."),
        KnownObject(keywords: ["sardinien", "sardinia"], wert: 24_090_000_000.0, dimension: .flaeche, label: "Inselfläche", witz: "Sardinien ist 9,4× so groß wie das Saarland. Sehr viel Meeresküste."),
        KnownObject(keywords: ["sizilien", "sicily", "sicilia"], wert: 25_711_000_000.0, dimension: .flaeche, label: "Inselfläche", witz: "Sizilien ist 10× so groß wie das Saarland. Der Ätna passt mit rein."),
        KnownObject(keywords: ["großbritannien", "england", "uk", "britain"], wert: 209_331_000_000.0, dimension: .flaeche, label: "Inselfläche", witz: "Großbritannien ist 81× so groß wie das Saarland. Tee inklusive."),


        KnownObject(keywords: ["blauwal", "wal", "whale"], wert: 150_000.0, dimension: .gewicht, label: "Körpergewicht", witz: "Das Saarland hat zwar keinen Ozean, aber immerhin die Saar."),
        KnownObject(keywords: ["mensch", "person", "mann", "frau"], wert: 75.0, dimension: .gewicht, label: "Durchschnittsgewicht", witz: "Im Saarland wohnen knapp eine Million Menschen. Das macht viel zusammen."),
        KnownObject(keywords: ["auto", "pkw", "wagen", "car"], wert: 1_500.0, dimension: .gewicht, label: "Fahrzeuggewicht", witz: "Wenn man Autos wiegen würde statt zu fahren."),
        KnownObject(keywords: ["lkw", "truck", "lastwagen"], wert: 25_000.0, dimension: .gewicht, label: "Leergewicht", witz: "Logistisch gesehen ein beeindruckendes Bundesland."),
        KnownObject(keywords: ["boeing", "flugzeug", "airbus", "a380"], wert: 412_000.0, dimension: .gewicht, label: "Leergewicht A380", witz: "Das Saarland hebt damit nicht ab – aber es bleibt geerdet."),
        KnownObject(keywords: ["containerschiff", "schiff", "tanker"], wert: 220_000_000.0, dimension: .gewicht, label: "Leergewicht", witz: "Die Saar wäre für sowas zu klein. Aber der Gedanke ist schön."),
        KnownObject(keywords: ["kuh", "rind"], wert: 600.0, dimension: .gewicht, label: "Durchschnittsgewicht", witz: "Das Saarland als Weide hätte Zukunft."),
        KnownObject(keywords: ["grumbeere", "kartoffel"], wert: 0.15, dimension: .gewicht, label: "Stückgewicht", witz: "Grumbeere is de Lieblingsesse vum Saarlänner. Haupsach gudd gess."),
        KnownObject(keywords: ["lyoner", "fleischwurst", "wurst"], wert: 0.04, dimension: .gewicht, label: "Scheiben-Gewicht", witz: "Lyoner gehört zum Saarland wie die Saar zum Wasser."),
        KnownObject(keywords: ["iphone", "smartphone", "handy"], wert: 0.174, dimension: .gewicht, label: "Gewicht", witz: "Das leichteste Objekt im Vergleich mit der Völklinger Hütte."),
        KnownObject(keywords: ["eiffelturm", "eiffel"], wert: 7_300_000.0, dimension: .gewicht, label: "Gesamtgewicht", witz: "Das Saarland ist schwerer als der Eiffelturm. Deutlich."),
        KnownObject(keywords: ["bier", "bierflasche"], wert: 1.0, dimension: .gewicht, label: "Flasche (1 l)", witz: "Im Saarland wiegt Bier genau richtig."),

        // ZEIT (Sekunden)
        KnownObject(keywords: ["weltkrieg", "krieg", "zweiter weltkrieg"], wert: 189_216_000.0, dimension: .zeit, label: "Dauer (6 Jahre)", witz: "Das Saarland hat das überlebt. Und ist danach wieder zu Deutschland gekommen."),
        KnownObject(keywords: ["corona", "pandemie", "covid"], wert: 94_608_000.0, dimension: .zeit, label: "Dauer (ca. 3 Jahre)", witz: "Das Saarland hat auch das überstanden. Mit Schwenker und Lyoner."),
        KnownObject(keywords: ["film", "kinofilm", "movie"], wert: 7_200.0, dimension: .zeit, label: "Dauer (2 Stunden)", witz: "In der Zeit könnte man das Saarland zweimal umrunden."),
        KnownObject(keywords: ["fußballspiel", "fußball", "bundesliga", "spiel"], wert: 5_400.0, dimension: .zeit, label: "Spielzeit (90 Min)", witz: "Der 1. FC Saarbrücken spielt 90 Minuten. Das Saarland schaut zu."),
        KnownObject(keywords: ["mittagspause", "pause", "lunch"], wert: 3_600.0, dimension: .zeit, label: "Mittagspause (1h)", witz: "Im Saarland wird die Mittagspause ernst genommen. Sehr ernst."),
        KnownObject(keywords: ["schulstunde", "unterricht", "schule"], wert: 2_700.0, dimension: .zeit, label: "Schulstunde (45 Min)", witz: "Das Saarland existiert 78.293 Schulstunden lang als Bundesland."),
        KnownObject(keywords: ["menschenleben", "leben", "lebenserwartung"], wert: 2_398_377_600.0, dimension: .zeit, label: "Lebenserwartung (76 J.)", witz: "Das Saarland ist fast so alt wie ein Menschenleben. Und fühlt sich noch jung."),
        KnownObject(keywords: ["römerreich", "römer", "roman empire"], wert: 15_778_800_000.0, dimension: .zeit, label: "Dauer (500 Jahre)", witz: "Das Römerreich war hier. Die Saarländer erinnern sich noch."),
        KnownObject(keywords: ["dinosaurier", "t-rex", "dino"], wert: 5_049_600_000_000.0, dimension: .zeit, label: "vor ca. 160.000 Jahren ausgestorben", witz: "Das Saarland ist deutlich jünger als die Dinosaurier. Fühlt sich manchmal aber nicht so an."),
        KnownObject(keywords: ["marathon", "lauf", "rennen"], wert: 14_400.0, dimension: .zeit, label: "Marathon (ca. 4h)", witz: "Im Saarland bergauf zu laufen ist ein Marathon für sich."),
        KnownObject(keywords: ["urlaub", "ferien", "reise"], wert: 1_814_400.0, dimension: .zeit, label: "Urlaub (3 Wochen)", witz: "Das Saarland ist so schön, da kann man auch Urlaub machen. Wirklich."),
        // GELD (Euro)
        KnownObject(keywords: ["bitcoin", "btc", "krypto", "kryptowährung", "crypto"], wert: 85_000.0, dimension: .geld, label: "Bitcoin-Kurs (ca.)", witz: "Das Saarland-BIP kauft ca. 420.000 Bitcoin. Haupsach gudd gess."),
        KnownObject(keywords: ["iphone", "apple", "smartphone"], wert: 1_200.0, dimension: .geld, label: "Preis", witz: "Mit dem Saarland-BIP könnte man fast 30 Millionen iPhones kaufen."),
        KnownObject(keywords: ["lamborghini", "ferrari", "porsche", "sportwagen"], wert: 250_000.0, dimension: .geld, label: "Fahrzeugpreis", witz: "Mit dem Saarland-BIP kauft man 142.800 Ferraris. Für jeden zweiten Einwohner einen."),
        KnownObject(keywords: ["haus", "immobilie", "wohnung", "eigenheim"], wert: 400_000.0, dimension: .geld, label: "Durchschnittspreis", witz: "Das Saarland-BIP würde 89.250 Häuser kaufen. Mehr als genug für alle Saarländer."),
        KnownObject(keywords: ["kaffee", "café", "espresso"], wert: 3.5, dimension: .geld, label: "Tassen-Preis", witz: "Mit dem Saarland-BIP kauft man 10,2 Milliarden Kaffees. Das reicht."),
        KnownObject(keywords: ["bier", "maß", "pils"], wert: 4.5, dimension: .geld, label: "Glas Bier", witz: "7,9 Milliarden Bier. Das Saarland nickt anerkennend."),
        KnownObject(keywords: ["döner", "doner", "kebab"], wert: 8.0, dimension: .geld, label: "Preis", witz: "4,46 Milliarden Döner für das Saarland-BIP. Nie wieder Hunger."),
        KnownObject(keywords: ["netflix", "streaming", "abo"], wert: 120.0, dimension: .geld, label: "Jahresabo", witz: "297,5 Millionen Netflix-Abos für das Saarland-BIP. Auch für Luxemburg."),
        KnownObject(keywords: ["monatslohn", "gehalt", "lohn", "verdienst"], wert: 3_600.0, dimension: .geld, label: "Medianlohn/Monat", witz: "Das Saarland-BIP zahlt 9,9 Millionen Monatsgehälter. Rechnen lohnt sich."),
        KnownObject(keywords: ["staatsverschuldung", "schulden", "deutschland schulden"], wert: 2_445_000_000_000.0, dimension: .geld, label: "Staatsschulden DE", witz: "Die deutschen Staatsschulden sind 68× größer als das Saarland-BIP. Das Saarland schulterzuckt."),
        KnownObject(keywords: ["amazon", "google", "apple konzern", "microsoft"], wert: 3_000_000_000_000.0, dimension: .geld, label: "Börsenwert (Billion €)", witz: "Apple ist 84× wertvoller als das Saarland-BIP. Das Saarland hat aber bessere Lyoner."),
        KnownObject(keywords: ["lyoner", "wurst", "fleischwurst"], wert: 3.5, dimension: .geld, label: "Preis (500g)", witz: "10,2 Milliarden Packungen Lyoner für das Saarland-BIP. Das wäre toll."),

        // LÄNGE (Meter)
        KnownObject(keywords: ["chinesische mauer", "große mauer", "china mauer"], wert: 21_196_000.0, dimension: .laenge, label: "Gesamtlänge", witz: "Die Chinesische Mauer ist 61× so lang wie alle Saarland-Flüsse. Das Saarland baut dafür den Schwenker."),
        KnownObject(keywords: ["amazon", "amazonas", "fluss"], wert: 6_400_000.0, dimension: .laenge, label: "Länge", witz: "Der Amazonas ist 18,4× so lang wie alle Saarland-Flüsse. Dafür hat die Saar Charakter."),
        KnownObject(keywords: ["rhein"], wert: 1_230_000.0, dimension: .laenge, label: "Länge", witz: "Der Rhein ist 3,5× so lang wie alle Saarland-Flüsse. Der Saarländer bleibt entspannt."),
        KnownObject(keywords: ["saar", "saarfluss"], wert: 246_000.0, dimension: .laenge, label: "Länge", witz: "Die Saar ist ein Drittel der gesamten saarländischen Flusslänge. Klein aber fein."),
        KnownObject(keywords: ["autobahn", "a1", "a6", "a8"], wert: 13_155_000.0, dimension: .laenge, label: "Autobahnnetz DE", witz: "Das deutsche Autobahnnetz ist 37,9× länger als alle Saarland-Flüsse. Das Saarland fährt lieber Autobahn."),
        KnownObject(keywords: ["marathon", "42km", "42 km"], wert: 42_195.0, dimension: .laenge, label: "Marathonstrecke", witz: "Alle Saarland-Flüsse hintereinander wären 8,2 Marathons. Anstrengend."),
        KnownObject(keywords: ["eiffelturm", "eiffel"], wert: 330.0, dimension: .laenge, label: "Höhe", witz: "Der Eiffelturm passt 1.052 Mal in alle Saarland-Flüsse. Hintereinander natürlich."),
        KnownObject(keywords: ["burj khalifa", "burj", "wolkenkratzer"], wert: 828.0, dimension: .laenge, label: "Höhe", witz: "Die Saarland-Flüsse sind 419 Burj Khalifas hoch. Nur eben waagerecht."),
        KnownObject(keywords: ["mond", "mondentfernung"], wert: 384_400_000.0, dimension: .laenge, label: "Entfernung Mond", witz: "Bis zum Mond und zurück sind alle Saarland-Flüsse viel zu kurz. Aber die Aussicht wäre schön."),
        KnownObject(keywords: ["mensch", "körpergröße", "person"], wert: 1.75, dimension: .laenge, label: "Körpergröße", witz: "In die Saarland-Flüsse passen 198.286 Menschen hintereinander. Sehr hintereinander."),
        KnownObject(keywords: ["saarschleife", "schleife"], wert: 10_000.0, dimension: .laenge, label: "Schleifen-Umfang (ca.)", witz: "Die Saarschleife ist kurz aber ikonisch. Das Saarland liebt sie."),
        KnownObject(keywords: ["a1", "autobahn saarland", "autobahn"], wert: 240_000.0, dimension: .laenge, label: "Autobahnnetz Saarland", witz: "Das Saarland-Autobahnnetz ist fast so lang wie alle Flüsse zusammen. Haupsach schnell."),

        // ANZAHL (Stück)
        KnownObject(keywords: ["star wars", "marvel", "disney film"], wert: 500_000_000_000.0, dimension: .anzahl, label: "Star-Wars-Fans weltweit", witz: "Die Saarländer gucken lieber Bundesliga. Und Schwenker-Grillen."),
        KnownObject(keywords: ["amazon produkte", "amazon artikel"], wert: 350_000_000.0, dimension: .anzahl, label: "Produkte auf Amazon", witz: "Amazon hat 355× mehr Produkte als Saarland Einwohner. Das Saarland kauft trotzdem lokal."),
        KnownObject(keywords: ["sterne", "sterne milchstraße", "milchstraße"], wert: 300_000_000_000.0, dimension: .anzahl, label: "Sterne in der Milchstraße", witz: "Die Milchstraße hat 303.900× mehr Sterne als das Saarland Einwohner. Das Saarland glänzt trotzdem."),
        KnownObject(keywords: ["ameise", "ameisen"], wert: 20_000_000_000_000_000.0, dimension: .anzahl, label: "Ameisen weltweit", witz: "Es gibt 20 Billiarden Ameisen. Pro Saarländer wären das 20 Millionen. Die Saarländer sagen: nein danke."),
        KnownObject(keywords: ["fußballstadion", "stadion", "allianz arena"], wert: 75_000.0, dimension: .anzahl, label: "Stadionkapazität (Allianz Arena)", witz: "Das Saarland passt 13 Mal in die Allianz Arena. Der 1. FC Saarbrücken zieht seinen Hut."),
        KnownObject(keywords: ["starbucks", "café"], wert: 36_000.0, dimension: .anzahl, label: "Starbucks-Filialen weltweit", witz: "Das Saarland hat 27,4× mehr Einwohner als Starbucks Filialen. Der Saarländer trinkt eh Kaffee zuhause."),
        KnownObject(keywords: ["mcdonalds", "mcdonald", "fastfood"], wert: 40_000.0, dimension: .anzahl, label: "McDonald's-Filialen weltweit", witz: "Das Saarland hat fast 25× mehr Einwohner als McDonald's Filialen. Der Metzger dankt."),
        KnownObject(keywords: ["grumbeere", "kartoffel"], wert: 3_000.0, dimension: .anzahl, label: "Grumbeere pro Einwohner/Jahr (Schätzung)", witz: "3.000 Kartoffeln pro Einwohner. Das Saarland fasst das noch."),
        KnownObject(keywords: ["buch", "bücher", "bibliothek"], wert: 130_000_000.0, dimension: .anzahl, label: "Bücher weltweit veröffentlicht", witz: "Auf jeden Saarländer kämen 131 Bücher. Haupsach gudd gess, nicht gudd gelese."),
        KnownObject(keywords: ["whatsapp", "nachricht", "message"], wert: 100_000_000_000.0, dimension: .anzahl, label: "WhatsApp-Nachrichten/Tag", witz: "Pro Saarländer werden täglich 101.329 WhatsApp-Nachrichten verschickt. Die meisten davon: Schwenker-Fotos."),
        KnownObject(keywords: ["auto deutschland", "autos", "pkw deutschland"], wert: 49_000_000.0, dimension: .anzahl, label: "Zugelassene PKW in DE", witz: "Auf jeden Saarländer kommen 49,6 Autos in Deutschland. Gefühlt stimmt das."),

        // VOLUMEN (Liter)
        KnownObject(keywords: ["bier", "bierkonsum", "biermenge"], wert: 0.5, dimension: .volumen, label: "Glas Bier (0,5l)", witz: "Der Bostalsee fasst 5 Milliarden Gläser Bier. Das wäre ein Fest."),
        KnownObject(keywords: ["badewanne", "bad", "wanne"], wert: 150.0, dimension: .volumen, label: "Badewanne", witz: "Der Bostalsee fasst 16,7 Millionen Badewannen. Das Saarland nimmt das zur Kenntnis."),
        KnownObject(keywords: ["schwimmbad", "olympiabecken", "freibad"], wert: 2_500_000.0, dimension: .volumen, label: "Olympiaschwimmbecken", witz: "Der Bostalsee fasst 1.000 Olympiabecken. Das Saarland hätte das größte Freibad Europas."),
        KnownObject(keywords: ["bostalsee", "bostal", "see"], wert: 2_500_000_000.0, dimension: .volumen, label: "Bostalsee-Volumen", witz: "Der Bostalsee ist genau 1 Bostalsee groß. Das hat sich noch nie geändert."),
        KnownObject(keywords: ["bodensee"], wert: 48_000_000_000_000.0, dimension: .volumen, label: "Bodensee-Volumen", witz: "Der Bodensee fasst 19.200× so viel wie der Bostalsee. Das Saarland hat trotzdem Strand."),
        KnownObject(keywords: ["coca cola", "cola", "softdrink"], wert: 0.33, dimension: .volumen, label: "Dose Cola (0,33l)", witz: "Der Bostalsee fasst 7,6 Milliarden Cola-Dosen. Den Durstlöscher hat das Saarland also."),
        KnownObject(keywords: ["weinfass", "wein", "fass"], wert: 225.0, dimension: .volumen, label: "Barrique-Fass (225l)", witz: "Der Bostalsee fasst 11,1 Millionen Weinfässer. Die Saarwein-Produzenten sind erfreut."),
        KnownObject(keywords: ["erdöl", "öl", "barrel"], wert: 159.0, dimension: .volumen, label: "Barrel Erdöl (159l)", witz: "Der Bostalsee fasst 15,7 Millionen Barrel Öl. Das Saarland bleibt trotzdem auf Kohle."),
        KnownObject(keywords: ["kaffee", "tasse kaffee"], wert: 0.25, dimension: .volumen, label: "Tasse Kaffee (250ml)", witz: "Der Bostalsee fasst 10 Milliarden Tassen Kaffee. Das Saarland nickt zufrieden."),
        KnownObject(keywords: ["milch", "milchtüte", "milchpackung"], wert: 1.0, dimension: .volumen, label: "Liter Milch", witz: "2,5 Milliarden Liter Milch. Der Bostalsee als weiße See – das wäre was."),
        KnownObject(keywords: ["saar", "saarfluss", "saarwasser"], wert: 45_000_000_000.0, dimension: .volumen, label: "Saar-Jahresabfluss (Schätzung)", witz: "Die Saar pumpt jährlich 18× den Bostalsee. Die Saar schafft das."),
    ]

    private static let saarkommentare = [
        "Das Saarland nimmt das zur Kenntnis.",
        "Die Saarländer sagen: Joa.",
        "Das Saarland bleibt entspannt.",
        "Saarbrücken hat schon Schlimmeres erlebt.",
        "Das Saarland kommentiert das nicht weiter.",
        "Die Saarländer trinken jetzt Kaffee.",
        "Das Saarland ist damit einverstanden.",
        "Typisch, findet das Saarland.",
        "Et is wie et is, sacht der Saarlänner.",
        "Das Saarland schulterzuckt auf saarlännerisch.",
        "Haupsach gudd gess.",
        "Des kennt mer jo.",
        "Das Saarland hat schon größere Krisen überstanden. Zum Beispiel den Strukturwandel.",
        "Die Saarländer grillen jetzt. Auf dem Schwenker natürlich.",
        "Das Saarland hat dafür die beste Lyoner weit und breit.",
    ]

    private func generateFallbackResponse(for input: String) -> String {
        let lower = input.lowercased()

        // Bekanntes Objekt — längste Keyword-Übereinstimmung gewinnt
        var bestMatch: KnownObject? = nil
        var bestMatchLen = 0
        for entry in Self.knownObjects {
            for kw in entry.keywords where lower.contains(kw) {
                if kw.count > bestMatchLen {
                    bestMatchLen = kw.count
                    bestMatch = entry
                }
            }
        }

        if let entry = bestMatch {
            return buildResponse(name: input, wert: entry.wert, dimension: entry.dimension, label: entry.label, witz: entry.witz)
        }

        // Unbekanntes Objekt — kontextbasierte Schätzung
        let seed = abs(input.hashValue)

        // Kontexthinweise erkennen
        let stadtHints = ["stadt", "city", "ort", "gemeinde", "kreis", "landkreis", "bezirk", "stadtteil", "dorf"]
        let landHints = ["land", "staat", "republic", "kingdom", "nation", "provinz", "region", "county"]
        let gewichtHints = ["kg", "gramm", "tonne", "ton", "wiegt", "schwer", "gewicht", "weight"]
        let geldHints = ["euro", "dollar", "preis", "kosten", "kostet", "wert", "zahlen", "bezahlen", "€", "$"]
        let laengeHints = ["meter", "km", "kilometer", "lang", "länge", "strecke", "weg", "straße"]

        if stadtHints.contains(where: { lower.contains($0) }) {
            let wert = [50_000_000.0, 150_000_000.0, 300_000_000.0, 800_000_000.0][seed % 4]
            return buildResponse(name: input, wert: wert, dimension: .flaeche, label: "geschätzte Stadtfläche",
                                 witz: "\(Self.saarkommentare[seed % Self.saarkommentare.count])")
        }
        if landHints.contains(where: { lower.contains($0) }) {
            let wert = [5_000_000_000.0, 30_000_000_000.0, 200_000_000_000.0, 1_000_000_000_000.0][seed % 4]
            return buildResponse(name: input, wert: wert, dimension: .flaeche, label: "geschätzte Staatsfläche",
                                 witz: "\(Self.saarkommentare[seed % Self.saarkommentare.count])")
        }
        if gewichtHints.contains(where: { lower.contains($0) }) {
            let wert = [1.0, 100.0, 5_000.0, 50_000.0][seed % 4]
            return buildResponse(name: input, wert: wert, dimension: .gewicht, label: "geschätztes Gewicht",
                                 witz: "\(Self.saarkommentare[seed % Self.saarkommentare.count])")
        }
        if geldHints.contains(where: { lower.contains($0) }) {
            let wert = [10.0, 500.0, 50_000.0, 1_000_000.0][seed % 4]
            return buildResponse(name: input, wert: wert, dimension: .geld, label: "geschätzter Preis",
                                 witz: "\(Self.saarkommentare[seed % Self.saarkommentare.count])")
        }
        if laengeHints.contains(where: { lower.contains($0) }) {
            let wert = [100.0, 5_000.0, 50_000.0, 500_000.0][seed % 4]
            return buildResponse(name: input, wert: wert, dimension: .laenge, label: "geschätzte Länge",
                                 witz: "\(Self.saarkommentare[seed % Self.saarkommentare.count])")
        }
        let estimates: [(Double, KIDimension, String, String)] = [
            (0.001,             .flaeche,  "geschätzte Grundfläche",    "Klein, aber das Saarland kennt keine Grenzen der Gastfreundschaft."),
            (50.0,              .flaeche,  "geschätzte Grundfläche",    "Das Saarland bleibt trotzdem größer. Immer."),
            (500.0,             .gewicht,  "geschätztes Gewicht",       "Respektabel – für ein Nicht-Bundesland."),
            (50_000.0,          .gewicht,  "geschätztes Gewicht",       "Die Völklinger Hütte ist beeindruckend schwer."),
            (86_400.0,          .zeit,     "geschätzte Dauer",          "Ein Tag ist kurz. Das Saarland denkt in Jahren."),
            (100.0,             .geld,     "geschätzter Preis",         "Das Saarland-BIP kauft davon einige Millionen."),
            (10_000.0,          .geld,     "geschätzter Preis",         "Das Saarland-BIP ist da deutlich größer."),
            (1_000.0,           .laenge,   "geschätzte Länge",          "Ein Kilometer – das Saarland hat 347 davon in Flüssen."),
            (1.0,               .volumen,  "geschätztes Volumen",       "Klein, aber der Bostalsee hat Platz."),
        ]
        let (wert, dimension, label, witz) = estimates[seed % estimates.count]
        let comment = Self.saarkommentare[seed % Self.saarkommentare.count]
        return buildResponse(name: input, wert: wert, dimension: dimension, label: label, witz: "\(witz) \(comment)")
    }

    private func buildResponse(name: String, wert: Double, dimension: KIDimension, label: String, witz: String) -> String {
        let ratio = wert / dimension.saarlandWert
        let ratioStr = formatRatio(ratio >= 1 ? ratio : 1.0 / ratio)
        let comparison = dimension.comparisonLabel(name: name, wert: wert, ratio: ratio, ratioStr: ratioStr)
        return "\(comparison) \(witz)"
    }

    private func formatRatio(_ n: Double) -> String {
        if n >= 1_000_000_000 { return String(format: "%.1f Mrd.", n / 1_000_000_000) }
        if n >= 1_000_000 { return String(format: "%.1f Mio.", n / 1_000_000) }
        if n >= 100_000 { return String(format: "%.0fk", n / 1000) }
        if n >= 10 { return String(format: "%.0f", n) }
        return String(format: "%.1f", n)
    }

    init() {
        checkModelAvailability()
        loadHistory()
    }

    private func checkModelAvailability() {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            modelState = .available
            print("[FoundationModels] ✅ Apple Intelligence available")
        case .unavailable(let reason):
            modelState = .unavailable(unavailabilityText(reason))
            print("[FoundationModels] ❌ Unavailable: \(reason)")
            // Wenn Modell noch lädt — nach 5 Sekunden nochmal prüfen
            if case .modelNotReady = reason {
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    await MainActor.run { self.checkModelAvailability() }
                }
            }
        @unknown default:
            modelState = .unavailable("Apple Intelligence nicht verfügbar.")
            print("[FoundationModels] ❓ Unknown availability state")
        }
    }

    private func unavailabilityText(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "Dieses Gerät unterstützt Apple Intelligence nicht."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence ist deaktiviert."
        case .modelNotReady:
            return "Das Modell wird noch geladen."
        default:
            return "Apple Intelligence ist momentan nicht verfügbar."
        }
    }

    func generateComparison() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        result = nil
        errorMessage = nil

        if case .unavailable = modelState {
            try? await Task.sleep(nanoseconds: 800_000_000)
            let text = generateFallbackResponse(for: trimmed)
            result = text
            saveResult(text, for: trimmed)
            isLoading = false
            return
        }

        do {
            let session = LanguageModelSession(instructions: Self.systemPrompt)
            let response = try await session.respond(to: trimmed)
            result = response.content
            saveResult(response.content, for: trimmed)
        } catch {
            let text = generateFallbackResponse(for: trimmed)
            result = text
            saveResult(text, for: trimmed)
        }

        isLoading = false
    }

    func reset() {
        result = nil
        errorMessage = nil
        inputText = ""
    }

    func restoreFromHistory(_ entry: KIHistoryEntry) {
        inputText = entry.input
        result = entry.result
    }

    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }

    private func saveResult(_ text: String, for input: String) {
        let entry = KIHistoryEntry(id: UUID(), input: input, result: text, date: Date())
        history.insert(entry, at: 0)
        if history.count > 20 { history = Array(history.prefix(20)) }
        saveHistory()
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: Self.historyKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: Self.historyKey),
              let decoded = try? JSONDecoder().decode([KIHistoryEntry].self, from: data)
        else { return }
        history = decoded
    }
}

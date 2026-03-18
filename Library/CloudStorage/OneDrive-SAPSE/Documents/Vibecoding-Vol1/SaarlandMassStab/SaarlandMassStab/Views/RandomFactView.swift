import SwiftUI

struct RandomFactView: View {
    @EnvironmentObject var viewModel: SaarlandViewModel
    @State private var triviaIndex = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Saarland-O-Meter
                saarlandOMeter

                // Main fact card
                if let obj = viewModel.randomObject {
                    factCard(for: obj)
                }

                // Refresh button
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.refreshRandom()
                    }
                } label: {
                    Label("Neuer Fakt", systemImage: "arrow.clockwise.circle.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.saarlandBlue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)

                // Trivia section
                triviaSection

                // Saarland info
                saarlandInfoCard
            }
            .padding(.vertical)
        }
        .navigationTitle("Zufallsfakt")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Saarland-O-Meter

    private var saarlandOMeter: some View {
        let progress = viewModel.meterProgress
        let viewed = viewModel.viewedCount
        let total = viewModel.totalCount

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saarland-O-Meter")
                        .font(.headline)
                    Text(total > 0 ? viewModel.meterTitle : "Lädt…")
                        .font(.caption)
                        .foregroundStyle(Color.saarlandBlue)
                        .fontWeight(.semibold)
                }
                Spacer()
                Text(total > 0 ? "\(viewed)/\(total)" : "–")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.saarlandBlue)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.saarlandBlue.opacity(0.12))
                        .frame(height: 20)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.saarlandBlue, Color.saarlandBlueLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * CGFloat(progress), progress > 0 ? 20 : 0), height: 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 20)

            Text(progress >= 1.0
                 ? "Du hast alle Objekte entdeckt! Haupsach gudd gess. 🏆"
                 : "Tippe auf Objekte in der Liste um den Meter zu füllen – noch \(total - viewed) fehlen!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Fact Card

    @ViewBuilder
    private func factCard(for obj: ComparisonObject) -> some View {
        let ratio = viewModel.ratio(for: obj)

        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color.saarlandBlue, Color.saarlandBlueLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(obj.kategorieEnum.emoji).font(.caption)
                        Text(obj.kategorie).font(.caption).foregroundStyle(.white.opacity(0.8))
                    }
                    HStack {
                        Text(obj.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Spacer()
                        RatioBadgeWhite(ratio: ratio, viewModel: viewModel)
                    }
                    Text(obj.emoji).font(.system(size: 36))
                }
                .padding()
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.comparisonText(for: obj))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top, 4)

                Divider()

                HStack {
                    StatBubble(label: "Wert", value: viewModel.formatValue(obj.wert, einheit: obj.einheit))
                    StatBubble(label: "Kategorie", value: "\(obj.kategorieEnum.emoji) \(obj.kategorie)")
                    StatBubble(label: "Referenz", value: viewModel.formatValue(obj.saarlandWert, einheit: obj.einheit))
                }

                Text(obj.quellenhinweis)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Trivia Section

    private var triviaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Wusstest du das?", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundStyle(Color.saarlandBlue)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        triviaIndex = (triviaIndex + 1) % saarlandTrivia.count
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(Color.saarlandBlue)
                }
            }

            let trivia = saarlandTrivia[triviaIndex]
            HStack(alignment: .top, spacing: 12) {
                Text(trivia.emoji)
                    .font(.title2)
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text(trivia.titel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(trivia.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
            }
            .padding()
            .background(Color.saarlandBlue.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Dots indicator
            HStack(spacing: 6) {
                ForEach(0..<min(saarlandTrivia.count, 8), id: \.self) { i in
                    Circle()
                        .fill(i == triviaIndex % 8 ? Color.saarlandBlue : Color(.tertiaryLabel))
                        .frame(width: 6, height: 6)
                }
                if saarlandTrivia.count > 8 {
                    Text("...")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Saarland Info

    private var saarlandInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🗺️").font(.title2)
                Text("Über das Saarland").font(.headline)
            }
            Text("""
Das Saarland ist das flächenmäßig kleinste Flächenbundesland Deutschlands mit \(viewModel.formatArea(viewModel.saarlandFlaeche)). \
Es grenzt an Frankreich und Luxemburg und liegt im Südwesten Deutschlands. \
Die Hauptstadt ist \(viewModel.saarlandHauptstadt) mit rund \(formatPopulation(viewModel.saarlandBevoelkerung)) Einwohnern (2024).
""")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func formatPopulation(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    // MARK: - Trivia Data

    private struct TriviaEntry {
        let emoji: String
        let titel: String
        let text: String
    }

    private let saarlandTrivia: [TriviaEntry] = [
        TriviaEntry(emoji: "🥔", titel: "Grumbeere", text: "Im Saarland heißt die Kartoffel \"Grumbeere\" – abgeleitet vom Dialektausdruck für \"Grundbirne\". Sie ist das inoffizielle Nationalgericht."),
        TriviaEntry(emoji: "🥩", titel: "Lyoner", text: "Die Lyoner (Fleischwurst) ist ein saarländisches Kulturgut. Kein Frühstück, keine Party ohne sie – und jeder hat seine Lieblings-Metzgerei."),
        TriviaEntry(emoji: "🔥", titel: "Schwenker", text: "Der Schwenkgrill ist die saarländische Erfindung des Grillens. Ein auf einem Dreibein hängender Rost, der über dem Feuer geschwenkt wird. Heilig."),
        TriviaEntry(emoji: "🏭", titel: "Völklinger Hütte", text: "Die Völklinger Hütte ist seit 1994 UNESCO-Weltkulturerbe und eines von nur zwei Industriedenkmälern weltweit, die diesen Status tragen."),
        TriviaEntry(emoji: "🌊", titel: "Die Saarschleife", text: "Die Saarschleife bei Mettlach ist das bekannteste Fotomotiv des Saarlandes. Der Fluss macht dort eine fast kreisförmige Kurve – entstanden durch Erosion über Jahrtausende."),
        TriviaEntry(emoji: "🇫🇷", titel: "Frankreich-Connection", text: "Das Saarland grenzt auf 264 km an Frankreich. Viele Saarländer machen täglich Einkäufe auf der anderen Seite – günstigeres Benzin und Wein locken."),
        TriviaEntry(emoji: "⚽", titel: "1. FC Saarbrücken", text: "Der 1. FC Saarbrücken war 1952 Westdeutscher Meister. Heute spielt er in der 3. Liga – und der Saarländer glaubt immer an den Aufstieg."),
        TriviaEntry(emoji: "🗳️", titel: "Volksabstimmung 1955", text: "Am 23. Oktober 1955 stimmte die saarländische Bevölkerung gegen das Saarstatut. Am 1. Januar 1957 trat das Saarland der Bundesrepublik bei – als letztes deutsches Bundesland."),
        TriviaEntry(emoji: "🌍", titel: "Mitten in Europa", text: "Saarbrücken ist die am nächsten an Frankreich gelegene deutsche Landeshauptstadt. Bis zum Stadtzentrum von Metz sind es nur 65 km."),
        TriviaEntry(emoji: "⛏️", titel: "Bergbaugeschichte", text: "Der Steinkohlebergbau prägte das Saarland über 250 Jahre. 2012 schloss die letzte Grube. Die Bergleute und ihre Kultur sind bis heute lebendiger Teil der saarländischen Identität."),
        TriviaEntry(emoji: "🏰", titel: "Saarbrücker Schloss", text: "Das Saarbrücker Schloss wurde mehrfach zerstört und wiederaufgebaut. Heute beherbergt es das Historische Museum Saar – und ist das Wahrzeichen der Stadt."),
        TriviaEntry(emoji: "🎓", titel: "Universität des Saarlandes", text: "Die Universität des Saarlandes in Saarbrücken wurde 1948 als deutsch-französische Universität gegründet. Sie ist bekannt für ihre Informatik und KI-Forschung."),
        TriviaEntry(emoji: "🍷", titel: "Saarwein", text: "An der Saar wächst Riesling – der Saarwein ist bekannt für seine Mineralität und Eleganz. Die Weinregion ist klein aber fein: knapp 800 Hektar Rebfläche."),
        TriviaEntry(emoji: "🦊", titel: "Fuchsstau", text: "Das Saarland hat eine der höchsten Fuchsdichten Europas. Das liegt am viel Wald, wenig Verkehr – und möglicherweise an den vielen Grumbeere-Resten."),
        TriviaEntry(emoji: "💬", titel: "Saarländisch redd", text: "\"Haupsach gudd gess\" – das saarländische Lebensmotto. Der Dialekt ist eine fränkisch-moselfränkische Mischung mit starkem französischen Einfluss. \"Merci\" sagt man hier ganz normal."),
        TriviaEntry(emoji: "🌳", titel: "Grünes Saarland", text: "Fast ein Drittel des Saarlandes ist bewaldet. Der Saarbrücker Stadtwald ist einer der größten innerstädtischen Wälder Deutschlands."),
        TriviaEntry(emoji: "🛤️", titel: "Beste Autobahnlage", text: "Trotz seiner Kleinheit hat das Saarland ein dichtes Autobahnnetz: A1, A6, A8 und A620 kreuzen sich hier – die Saarländer können also immer schnell flüchten."),
        TriviaEntry(emoji: "🏆", titel: "Sportland", text: "Aus dem Saarland stammen unter anderem Beachvolleyballer Ludwig/Walkenhorst (Olympia-Gold 2016) und Turnerin Kim Bui. Das Saarland macht für seine Größe sportlich ordentlich mit."),
        TriviaEntry(emoji: "🎭", titel: "Saarbrücker Theater", text: "Das Saarländische Staatstheater ist eine der wichtigsten Kultureinrichtungen der Region – mit Oper, Schauspiel und Ballett unter einem Dach."),
        TriviaEntry(emoji: "🤝", titel: "Drei Länder, eine Region", text: "Saarland, Lothringen (Frankreich) und Luxemburg bilden die \"Großregion SaarLorLux\" – ein grenzüberschreitender Wirtschafts- und Kulturraum mit 11 Millionen Menschen."),
    ]
}

struct RatioBadgeWhite: View {
    let ratio: Double
    let viewModel: SaarlandViewModel

    var body: some View {
        let text = ratio < 1
            ? "÷\(viewModel.formatRatio(1.0/ratio))"
            : "×\(viewModel.formatRatio(ratio))"

        Text(text)
            .font(.subheadline)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.25))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

struct StatBubble: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        RandomFactView()
    }
    .environmentObject(SaarlandViewModel())
}

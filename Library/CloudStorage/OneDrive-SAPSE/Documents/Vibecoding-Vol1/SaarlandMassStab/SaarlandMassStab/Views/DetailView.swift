import SwiftUI
import UIKit

struct DetailView: View {
    @EnvironmentObject var viewModel: SaarlandViewModel
    let object: ComparisonObject

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                diagramSection
                comparisonTextSection
                saarlandFactsSection
                sourceSection
            }
            .padding()
        }
        .navigationTitle("\(object.emoji) \(object.name)")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.markViewed(object)
        }
    }

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(object.name)
                    .font(.title2)
                    .fontWeight(.bold)
                HStack(spacing: 4) {
                    Text(object.kategorieEnum.emoji)
                        .font(.caption)
                    Text(object.kategorie)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(viewModel.formatValue(object.wert, einheit: object.einheit))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saarlandBlue)
            }
            Spacer()
            Text(object.emoji)
                .font(.system(size: 60))
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var diagramSection: some View {
        let ratio = viewModel.ratio(for: object)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Verhältnis zum Saarland")
                .font(.headline)

            if object.kategorieEnum == .flaeche {
                ProportionDiagram(ratio: ratio, objectName: object.name, objectEmoji: object.emoji)
                    .frame(height: 200)
            } else {
                BarComparisonDiagram(
                    ratio: ratio,
                    objectName: object.name,
                    objectEmoji: object.emoji,
                    objectValue: viewModel.formatValue(object.wert, einheit: object.einheit),
                    saarlandValue: viewModel.formatValue(object.saarlandWert, einheit: object.einheit),
                    saarlandLabel: saarlandReferenceLabel
                )
                .frame(height: 140)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var saarlandReferenceLabel: String {
        switch object.kategorieEnum {
        case .flaeche:  return "Saarland"
        case .gewicht:  return "Völklinger Hütte"
        case .zeit:     return "Saarland (\(Calendar.current.component(.year, from: Date()) - 1957) J.)"
        case .geld:     return "Saarland-BIP"
        case .laenge:   return "Saarland-Flüsse"
        case .anzahl:   return "Saarland-Einw."
        case .volumen:  return "Bostalsee"
        }
    }

    private var comparisonTextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vergleich")
                .font(.headline)
            Text(viewModel.comparisonText(for: object))
                .font(.body)
                .foregroundStyle(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.saarlandBlue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var saarlandFactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Das Saarland")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                FactCell(icon: "map", label: "Fläche", value: viewModel.formatArea(viewModel.saarlandFlaeche))
                FactCell(icon: "person.2", label: "Bevölkerung", value: formatPopulation(viewModel.saarlandBevoelkerung))
                FactCell(icon: "building.columns", label: "Hauptstadt", value: viewModel.saarlandHauptstadt)
                FactCell(icon: "eurosign.circle", label: "BIP", value: "\(viewModel.saarlandBIP) Mrd. €")
                FactCell(icon: "house.and.flag", label: "Bev.-Dichte", value: "\(Int(viewModel.saarlandDichte)) Ew/km²")
                FactCell(icon: "flag", label: "Bundesland seit", value: "1957")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Quelle")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text(object.quellenhinweis)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 4)
    }

    private func formatPopulation(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - BarComparisonDiagram

struct BarComparisonDiagram: View {
    let ratio: Double
    let objectName: String
    let objectEmoji: String
    let objectValue: String
    let saarlandValue: String
    let saarlandLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Saarland reference bar
            barRow(
                emoji: "🏳️",
                label: saarlandLabel,
                value: saarlandValue,
                fraction: ratio >= 1 ? CGFloat(1.0 / ratio) : 1.0,
                color: Color.saarlandBlue
            )
            // Object bar
            barRow(
                emoji: objectEmoji,
                label: objectName,
                value: objectValue,
                fraction: ratio >= 1 ? 1.0 : CGFloat(ratio),
                color: ratio >= 1 ? Color.saarlandBlueLight : Color.orange
            )
        }
    }

    private func barRow(emoji: String, label: String, value: String, fraction: CGFloat, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(emoji).font(.caption)
                Text(label).font(.caption).fontWeight(.semibold).lineLimit(1)
                Spacer()
                Text(value).font(.caption2).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.8))
                    .frame(width: max(geo.size.width * fraction, 4))
            }
            .frame(height: 24)
        }
    }
}

// MARK: - ProportionDiagram

struct ProportionDiagram: View {
    let ratio: Double
    let objectName: String
    let objectEmoji: String

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let totalHeight = geo.size.height
            let padding: CGFloat = 8

            if ratio >= 1.0 {
                let saarlandFraction = 1.0 / ratio
                let saarlandWidth = max(totalWidth * CGFloat(saarlandFraction), 24)
                let saarlandHeight = max(totalHeight * CGFloat(saarlandFraction), 24)

                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.saarlandBlueLight.opacity(0.25))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.saarlandBlueLight, lineWidth: 2))
                        .overlay(VStack {
                            Text(objectEmoji).font(.title)
                            Text(objectName).font(.caption).fontWeight(.semibold).multilineTextAlignment(.center)
                        }.padding(4), alignment: .center)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.saarlandBlue.opacity(0.7))
                        .frame(width: saarlandWidth, height: saarlandHeight)
                        .overlay(Text("🏳️").font(saarlandHeight > 30 ? .caption : .system(size: 10)), alignment: .center)
                        .padding(padding)
                }
            } else {
                let objectWidth = max(totalWidth * CGFloat(ratio), 24)
                let objectHeight = max(totalHeight * CGFloat(ratio), 24)

                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.saarlandBlue.opacity(0.25))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.saarlandBlue, lineWidth: 2))
                        .overlay(VStack {
                            Text("🏳️").font(.title)
                            Text("Saarland").font(.caption).fontWeight(.semibold)
                        }.padding(4), alignment: .center)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange.opacity(0.6))
                        .frame(width: objectWidth, height: objectHeight)
                        .overlay(Text(objectEmoji).font(objectHeight > 30 ? .caption : .system(size: 10)), alignment: .center)
                        .padding(padding)
                }
            }
        }
    }
}

struct FactCell: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack {
        DetailView(object: ComparisonObject(
            id: 1, name: "Deutschland", wert: 357588.0, einheit: "km²",
            kategorie: "Fläche", emoji: "🇩🇪",
            quellenhinweis: "Statistisches Bundesamt 2024", saarlandWert: 2569.69
        ))
    }
    .environmentObject(SaarlandViewModel())
}

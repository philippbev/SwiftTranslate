import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject var viewModel: SaarlandViewModel
    @State private var inputText: String = ""
    @State private var selectedUnit: AreaUnit = .km2

    private let converter = UnitConverterService()

    private var inputValue: Double? {
        let normalized = inputText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private var km2Value: Double? {
        guard let v = inputValue else { return nil }
        return converter.toKm2(v, from: selectedUnit)
    }

    private var ratio: Double? {
        guard let km2 = km2Value, km2 > 0 else { return nil }
        return km2 / viewModel.saarlandFlaeche
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                inputSection
                if inputValue != nil {
                    resultSection
                }
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("Flächenrechner")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fläche eingeben")
                .font(.headline)

            HStack(spacing: 12) {
                TextField("z.B. 100", text: $inputText)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .font(.title3)

                if !inputText.isEmpty {
                    Button {
                        inputText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Picker("Einheit", selection: $selectedUnit) {
                ForEach(AreaUnit.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.segmented)

            if let km2 = km2Value {
                Text("= \(viewModel.formatArea(km2))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ergebnis")
                .font(.headline)

            if let r = ratio, let km2 = km2Value {
                // Main comparison
                VStack(spacing: 8) {
                    if r < 1.0 {
                        resultCard(
                            emoji: "🔵",
                            text: "Das Saarland ist \(viewModel.formatRatio(1.0/r))x größer",
                            color: .saarlandBlue
                        )
                    } else {
                        resultCard(
                            emoji: "📐",
                            text: "Entspricht \(viewModel.formatRatio(r))x der Saarlandfläche",
                            color: .green
                        )
                    }
                }

                Divider()

                // Conversions table
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alle Einheiten")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(AreaUnit.allCases, id: \.self) { unit in
                        if unit != selectedUnit {
                            let converted = converter.fromKm2(km2, to: unit)
                            HStack {
                                Text(unit.rawValue)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatConverted(converted, unit: unit))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }

                Divider()

                // Closest comparison object
                if let closest = findClosestObject(km2: km2) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ähnlichste Referenz")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text(closest.emoji)
                            Text(closest.name)
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            Text(viewModel.formatValue(closest.wert, einheit: closest.einheit))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text("Bitte gib eine gültige Fläche ein.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func resultCard(emoji: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.title2)
            Text(text)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatConverted(_ value: Double, unit: AreaUnit) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "de_DE")
        formatter.maximumFractionDigits = value < 1 ? 4 : (value < 100 ? 2 : 0)
        return (formatter.string(from: NSNumber(value: value)) ?? "\(value)") + " " + unit.rawValue
    }

    private func findClosestObject(km2: Double) -> ComparisonObject? {
        viewModel.objects.filter { $0.kategorieEnum == .flaeche }
            .min { abs($0.wert - km2) < abs($1.wert - km2) }
    }
}

#Preview {
    NavigationStack {
        CalculatorView()
    }
    .environmentObject(SaarlandViewModel())
}

import SwiftUI
import UIKit

struct QuizView: View {
    @EnvironmentObject var saarlandVM: SaarlandViewModel
    @StateObject private var quiz: QuizViewModel = QuizViewModel(objects: [])
    @State private var initialized = false
    @State private var selectedKategorien: Set<Kategorie> = Set(Kategorie.allCases)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Scoreboard
                scoreBoard

                // Kategorie-Filter
                if !quiz.gameOver {
                    kategoriePicker
                }

                if quiz.gameOver {
                    gameOverCard
                } else if let q = quiz.currentQuestion {
                    questionCard(q)
                } else {
                    ProgressView()
                        .padding(40)
                }
            }
            .padding()
        }
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if !initialized {
                quiz.objects = saarlandVM.objects
                quiz.nextQuestion()
                initialized = true
            }
        }
        .onChange(of: selectedKategorien) { _, newVal in
            quiz.allowedKategorien = newVal
            quiz.nextQuestion()
        }
    }

    private var kategoriePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Kategorie.allCases, id: \.self) { kat in
                    let isOn = selectedKategorien.contains(kat)
                    Button {
                        if isOn && selectedKategorien.count > 1 {
                            selectedKategorien.remove(kat)
                        } else if !isOn {
                            selectedKategorien.insert(kat)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(kat.emoji).font(.caption)
                            Text(kat.rawValue).font(.caption).fontWeight(isOn ? .semibold : .regular)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isOn ? Color.saarlandBlue : Color(.tertiarySystemBackground))
                        .foregroundStyle(isOn ? .white : .primary)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isOn ? Color.clear : Color(.separator), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Scoreboard

    private var scoreBoard: some View {
        HStack(spacing: 0) {
            ScoreCell(icon: "star.fill", color: .yellow, label: "Punkte", value: "\(quiz.score)")
            Divider().frame(height: 40)
            ScoreCell(icon: "flame.fill", color: .orange, label: "Serie", value: "\(quiz.streak)")
            Divider().frame(height: 40)
            ScoreCell(icon: "trophy.fill", color: Color.saarlandBlue, label: "Rekord", value: "\(quiz.highScore)")
            Divider().frame(height: 40)
            ScoreCell(icon: "heart.fill", color: .red, label: "Leben", value: String(repeating: "❤️", count: quiz.lives))
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Question card

    private func questionCard(_ q: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            // Kategorie-Badge + Schwierigkeit
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text(q.kategorie.emoji)
                        .font(.subheadline)
                    Text(q.kategorie.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.saarlandBlue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.saarlandBlue.opacity(0.1))
                .clipShape(Capsule())

                let diff = quiz.difficultyLabel(for: q)
                let diffColor: Color = diff.color == "green" ? .green : (diff.color == "orange" ? .orange : .red)
                Text(diff.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(diffColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(diffColor.opacity(0.1))
                    .clipShape(Capsule())
            }

            Text(quiz.questionText(for: q.kategorie))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            HStack(alignment: .top, spacing: 12) {
                answerButton(object: q.objectA, isA: true, q: q)
                    .frame(maxWidth: .infinity)

                Text("VS")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 50)

                answerButton(object: q.objectB, isA: false, q: q)
                    .frame(maxWidth: .infinity)
            }

            // Streak-Belohnung
            if quiz.streak > 0 && quiz.streak % 5 == 0 {
                HStack(spacing: 8) {
                    Text("🔥")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(quiz.streak)er Serie!")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                        Text("Haupsach gudd gess – du bist on fire!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .transition(.scale.combined(with: .opacity))
            }

            // Feedback
            if let correct = quiz.lastAnswerCorrect {
                feedbackBanner(correct: correct, q: q)
                    .transition(.scale.combined(with: .opacity))
            }

            // Saarland reference
            Text(quiz.referenzText(for: q.kategorie))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: quiz.lastAnswerCorrect)
    }

    private func answerButton(object: ComparisonObject, isA: Bool, q: QuizQuestion) -> some View {
        let answered = quiz.lastAnswerCorrect != nil
        let isCorrect = isA == q.correctAnswer
        let bgColor: Color = answered
            ? (isCorrect ? .green.opacity(0.15) : .red.opacity(0.1))
            : Color(.tertiarySystemGroupedBackground)
        let borderColor: Color = answered
            ? (isCorrect ? .green : .red.opacity(0.4))
            : Color(.separator)

        return Button {
            guard quiz.lastAnswerCorrect == nil else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation { quiz.answer(aIsBigger: isA) }
        } label: {
            VStack(spacing: 8) {
                Text(object.emoji)
                    .font(.system(size: 40))
                Text(object.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if answered {
                    Text(saarlandVM.formatValue(object.wert, einheit: object.einheit))
                        .font(.caption)
                        .foregroundStyle(isCorrect ? .green : .secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderColor, lineWidth: answered ? 2 : 1))
        }
        .buttonStyle(.plain)
        .disabled(answered)
    }

    private func feedbackBanner(correct: Bool, q: QuizQuestion) -> some View {
        let bigger = q.correctAnswer ? q.objectA : q.objectB
        let smaller = q.correctAnswer ? q.objectB : q.objectA
        let ratio = bigger.ratio / smaller.ratio
        let verb: String = {
            switch q.kategorie {
            case .flaeche:  return "größer"
            case .gewicht:  return "schwerer"
            case .zeit:     return "länger"
            case .geld:     return "teurer"
            case .laenge:   return "länger"
            case .anzahl:   return "mehr"
            case .volumen:  return "größer"
            }
        }()

        return HStack(spacing: 8) {
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(correct ? .green : .red)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(correct ? "Richtig!" : "Falsch!")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(correct ? .green : .red)
                Text("\(bigger.name) ist \(saarlandVM.formatRatio(ratio))× \(verb) als \(smaller.name).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .background(correct ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Game Over

    private var gameOverCard: some View {
        VStack(spacing: 20) {
            Text("🏁")
                .font(.system(size: 64))
            Text("Spiel vorbei!")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ResultRow(label: "Dein Score", value: "\(quiz.score)")
                ResultRow(label: "Rekord", value: "\(quiz.highScore)")
                if quiz.score == quiz.highScore && quiz.score > 0 {
                    Label("Neuer Rekord!", systemImage: "trophy.fill")
                        .foregroundStyle(.yellow)
                        .font(.headline)
                }
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation { quiz.restart() }
            } label: {
                Label("Nochmal spielen", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.saarlandBlue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            let shareText = quiz.score > 0
                ? "Ich habe \(quiz.score) Punkte im Saarland Rechner Quiz erreicht! 🏆 Schaffst du mehr? #SaarlandRechner"
                : "Ich habe das Saarland Rechner Quiz gespielt! 🏳️ #SaarlandRechner"
            ShareLink(item: shareText) {
                Label("Ergebnis teilen", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Helpers

struct ScoreCell: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ResultRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    NavigationStack {
        QuizView()
    }
    .environmentObject(SaarlandViewModel())
}

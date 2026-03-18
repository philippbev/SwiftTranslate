import Foundation
import SwiftUI

struct QuizQuestion {
    let objectA: ComparisonObject
    let objectB: ComparisonObject
    let correctAnswer: Bool // true = A is bigger (higher ratio)
    let kategorie: Kategorie
}

class QuizViewModel: ObservableObject {
    @Published var currentQuestion: QuizQuestion? = nil
    @Published var score: Int = 0
    @Published var streak: Int = 0
    @Published var highScore: Int = 0
    @Published var lastAnswerCorrect: Bool? = nil
    @Published var gameOver: Bool = false
    @Published var lives: Int = 3

    var objects: [ComparisonObject] = []
    var allowedKategorien: Set<Kategorie> = Set(Kategorie.allCases)
    private var recentPairs: [String] = []  // FIFO-Queue statt Set
    private static let highScoreKey = "quiz_highscore_v1"

    init(objects: [ComparisonObject]) {
        self.objects = objects
        self.highScore = UserDefaults.standard.integer(forKey: Self.highScoreKey)
        nextQuestion()
    }

    func nextQuestion() {
        guard objects.count >= 2 else { return }
        lastAnswerCorrect = nil

        // Wähle eine zufällige Kategorie aus den erlaubten die mindestens 2 Objekte hat
        let kategorien = allowedKategorien.filter { kat in
            objects.filter { $0.kategorie == kat.rawValue }.count >= 2
        }
        guard let kat = kategorien.randomElement() else { return }
        let pool = objects.filter { $0.kategorie == kat.rawValue }

        var attempts = 0
        var a: ComparisonObject
        var b: ComparisonObject
        repeat {
            a = pool.randomElement()!
            b = pool.filter { $0.id != a.id }.randomElement()!
            attempts += 1
        } while recentPairs.contains("\(min(a.id,b.id))-\(max(a.id,b.id))") && attempts < 30

        let key = "\(min(a.id,b.id))-\(max(a.id,b.id))"
        recentPairs.append(key)
        if recentPairs.count > 30 { recentPairs.removeFirst() }
        currentQuestion = QuizQuestion(objectA: a, objectB: b, correctAnswer: a.ratio > b.ratio, kategorie: kat)
    }

    func questionText(for kat: Kategorie) -> String {
        switch kat {
        case .flaeche:  return "Was ist flächenmäßig größer?"
        case .gewicht:  return "Was wiegt mehr?"
        case .zeit:     return "Was dauert länger?"
        case .geld:     return "Was kostet mehr?"
        case .laenge:   return "Was ist länger?"
        case .anzahl:   return "Was gibt es mehr davon?"
        case .volumen:  return "Was fasst mehr?"
        }
    }

    func referenzText(for kat: Kategorie) -> String {
        switch kat {
        case .flaeche:  return "Referenz: Saarland = 2.569,69 km²"
        case .gewicht:  return "Referenz: Völklinger Hütte = 3,4 Mrd. t"
        case .zeit:     return "Referenz: Saarland als Bundesland seit 1957 (67 J.)"
        case .geld:     return "Referenz: Saarland-BIP = 35,7 Mrd. €"
        case .laenge:   return "Referenz: Saarland-Flüsse = 347 km"
        case .anzahl:   return "Referenz: Saarland-Einwohner = 986.887"
        case .volumen:  return "Referenz: Bostalsee = 2,5 Mrd. Liter"
        }
    }

    func difficultyLabel(for q: QuizQuestion) -> (label: String, color: String) {
        let ratio = max(q.objectA.ratio, q.objectB.ratio) / min(q.objectA.ratio, q.objectB.ratio)
        if ratio > 10  { return ("Einfach", "green") }
        if ratio > 2   { return ("Mittel", "orange") }
        return ("Schwer", "red")
    }

    func answer(aIsBigger: Bool) {
        guard let q = currentQuestion else { return }
        let correct = aIsBigger == q.correctAnswer

        withAnimation {
            lastAnswerCorrect = correct
        }

        if correct {
            score += 1
            streak += 1
            if score > highScore {
                highScore = score
                UserDefaults.standard.set(highScore, forKey: Self.highScoreKey)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                self.nextQuestion()
            }
        } else {
            streak = 0
            lives -= 1
            if lives <= 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    self.gameOver = true
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    self.nextQuestion()
                }
            }
        }
    }

    func restart() {
        score = 0
        streak = 0
        lives = 3
        gameOver = false
        // recentPairs bewusst NICHT leeren — verhindert sofortige Wiederholungen
        nextQuestion()
    }
}

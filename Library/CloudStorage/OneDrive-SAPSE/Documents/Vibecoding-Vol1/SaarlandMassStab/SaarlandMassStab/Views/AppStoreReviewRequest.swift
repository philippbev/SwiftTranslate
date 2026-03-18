import StoreKit
import SwiftUI

extension SaarlandViewModel {
    func requestReviewIfAppropriate() {
        let runCount = UserDefaults.standard.integer(forKey: "app_run_count")
        let lastReviewRequestVersion = UserDefaults.standard.string(forKey: "last_review_version")
        
        UserDefaults.standard.set(runCount + 1, forKey: "app_run_count")
        
        // Review-Request Logic
        let shouldRequestReview = (runCount == 5 || runCount == 15 || runCount == 50) &&
                                 lastReviewRequestVersion != AppConfig.version
        
        if shouldRequestReview {
            UserDefaults.standard.set(AppConfig.version, forKey: "last_review_version")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
            }
        }
    }
    
    // Analytics für App Store Optimierung
    func trackAppUsage(_ event: AnalyticsEvent) {
        #if DEBUG
        print("📊 Analytics: \(event.name)")
        #endif
        
        // Hier könntest du später Analytics hinzufügen
        // Für den Start: Privacy-First, keine Tracking
    }
}
enum AnalyticsEvent {
    case appLaunched
    case quizStarted
    case quizCompleted(score: Int)
    case randomFactViewed
    case kiComparisonGenerated
    case shareButtonTapped
    case onboardingCompleted
    
    var name: String {
        switch self {
        case .appLaunched: return "app_launched"
        case .quizStarted: return "quiz_started"
        case .quizCompleted(let score): return "quiz_completed_score_\(score)"
        case .randomFactViewed: return "random_fact_viewed"
        case .kiComparisonGenerated: return "ki_comparison_generated"
        case .shareButtonTapped: return "share_button_tapped"
        case .onboardingCompleted: return "onboarding_completed"
        }
    }
}


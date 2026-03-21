import Foundation

/// Tracks whether onboarding has been completed across app launches.
struct OnboardingStore {
    private let key = "onboarding_completed_v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasCompleted: Bool {
        get { defaults.bool(forKey: key) }
        nonmutating set { defaults.set(newValue, forKey: key) }
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}

/// Shared instance used by the app.
extension OnboardingStore {
    static let shared = OnboardingStore()
}

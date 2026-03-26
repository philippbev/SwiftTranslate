import SwiftUI
import Translation

// MARK: - Onboarding Container

@available(macOS 15.0, *)
struct OnboardingView: View {
    @Environment(AppState.self) private var state
    @State private var currentStep: Step = .welcome

    enum Step { case welcome, download, ready }

    var body: some View {
        ZStack {
            switch currentStep {
            case .welcome:
                WelcomeStepView {
                    withAnimation(.easeInOut(duration: 0.35)) { currentStep = .download }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .download:
                DownloadStepView {
                    withAnimation(.easeInOut(duration: 0.35)) { currentStep = .ready }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .ready:
                ReadyStepView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .frame(width: 340)
        // Single .translationTask that reacts to state.prepareConfig.
        // AppState.triggerNextDownload() swaps prepareConfig to advance the queue.
        .translationTask(state.prepareConfig) { session in
            do {
                try await session.prepareTranslation()
                if case .downloading(let pair) = state.downloadStatus {
                    state.pairReady(pair)
                    if state.downloadStatus == .ready {
                        withAnimation(.easeInOut(duration: 0.35)) { currentStep = .ready }
                    }
                }
            } catch {
                state.downloadFailed(error)
            }
        }
    }
}

// MARK: - Step 1: Welcome

@available(macOS 15.0, *)
private struct WelcomeStepView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Image(systemName: "translate")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.blue)
                    .padding(.top, 28)

                Text("SwiftTranslate")
                    .font(.title).fontWeight(.bold)

                Text(L("onboarding.welcome.subtitle"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Divider().padding(.vertical, 18)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "globe",           color: .blue,   title: L("feature.offline.title"),       subtitle: L("feature.offline.subtitle"))
                FeatureRow(icon: "wand.and.stars",  color: .purple, title: L("feature.autodetect.title"),    subtitle: L("feature.autodetect.subtitle"))
                FeatureRow(icon: "doc.on.clipboard",color: .green,  title: L("feature.autocopy.title"),      subtitle: L("feature.autocopy.subtitle"))
                FeatureRow(icon: "keyboard",        color: .orange, title: L("feature.hotkey.title"),        subtitle: L("feature.hotkey.subtitle"))
            }
            .padding(.horizontal, 24)

            Divider().padding(.vertical, 18)

            VStack(spacing: 10) {
                StepDots(current: 0, total: 3)
                Button(action: { onContinue() }) {
                    Text(L("onboarding.continue"))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Step 2: Download

@available(macOS 15.0, *)
private struct DownloadStepView: View {
    @Environment(AppState.self) private var state
    let onComplete: () -> Void

    @State private var animatedProgress: Double = 0
    @State private var progressTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 72, height: 72)
                    Image(systemName: downloadIcon)
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.blue)
                        .contentTransition(.symbolEffect(.replace))
                }
                .padding(.top, 28)

                Text(L("download.title"))
                    .font(.title2).fontWeight(.bold)

                Text(L("download.subtitle"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Divider().padding(.vertical, 14)

            // Progress bar area
            VStack(spacing: 8) {
                if isDownloading {
                    VStack(spacing: 6) {
                        ProgressView(value: animatedProgress)
                            .progressViewStyle(.linear)
                            .tint(.blue)
                            .animation(.easeInOut(duration: 0.3), value: animatedProgress)

                        HStack {
                            Text(progressLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(animatedProgress * 100))%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if case .failed = state.downloadStatus {
                    Label {
                        Text(L("download.failed"))
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .foregroundStyle(.orange)
                    .font(.caption)
                } else {
                    Text(L("download.size.hint"))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 24)

            Divider().padding(.vertical, 14)

            // CTA
            VStack(spacing: 10) {
                StepDots(current: 1, total: 3)
                ctaButton
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onChange(of: state.downloadStatus) { _, new in
            switch new {
            case .downloading:
                let total = Double(max(state.downloadQueue.count, 1))
                let done = Double(state.downloadQueueIndex)
                let start = done / total
                let end = (done + 1) / total * 0.95
                startProgressAnimation(from: start, to: end, duration: 60)
            case .ready:
                progressTask?.cancel()
                animatedProgress = 1.0
            default:
                break
            }
        }
        .onDisappear {
            progressTask?.cancel()
        }
    }

    // MARK: - Derived state helpers

    private var isDownloading: Bool {
        if case .downloading = state.downloadStatus { return true }
        return false
    }

    private var downloadIcon: String {
        switch state.downloadStatus {
        case .idle, .checkingAvailability: return "arrow.down.circle"
        case .downloading:                 return "arrow.down.circle.fill"
        case .ready:                       return "checkmark.circle.fill"
        case .failed:                      return "exclamationmark.triangle"
        }
    }

    private var progressLabel: String {
        if case .downloading(let pair) = state.downloadStatus {
            let src = SupportedLanguage.from(id: pair.source)?.displayName ?? pair.source
            let tgt = SupportedLanguage.from(id: pair.target)?.displayName ?? pair.target
            let idx = state.downloadQueueIndex + 1
            let total = state.downloadQueue.count
            return "\(src) → \(tgt)  (\(idx)/\(total))"
        }
        if case .checkingAvailability = state.downloadStatus {
            return L("download.checking")
        }
        return ""
    }

    @ViewBuilder
    private var ctaButton: some View {
        switch state.downloadStatus {
        case .idle:
            Button(action: { Task { await state.startDownload() } }) {
                Text(L("download.start"))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)

        case .checkingAvailability:
            Button(action: {}) {
                Text(L("download.checking.button"))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(true)

        case .downloading:
            Button(action: {}) {
                Text(L("download.loading.button"))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(true)

        case .ready:
            EmptyView()

        case .failed:
            Button(action: { Task { await state.startDownload() } }) {
                Text(L("download.retry"))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .tint(.orange)
        }
    }

    // MARK: - Animated progress

    private func startProgressAnimation(from start: Double, to end: Double, duration: Double) {
        progressTask?.cancel()
        animatedProgress = start
        progressTask = Task {
            let steps = 200
            let delay = duration / Double(steps)
            let increment = (end - start) / Double(steps)
            for _ in 0..<steps {
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    animatedProgress = min(animatedProgress + increment, end)
                }
            }
        }
    }
}

// MARK: - Step 3: Ready

@available(macOS 15.0, *)
private struct ReadyStepView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 72, height: 72)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.green)
                }
                .padding(.top, 28)

                Text(L("ready.title"))
                    .font(.title).fontWeight(.bold)

                Text(L("ready.subtitle"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Divider().padding(.vertical, 18)

            VStack(alignment: .leading, spacing: 12) {
                TipRow(icon: "command",          text: "tip.hotkey")
                TipRow(icon: "return",           text: "tip.translate")
                TipRow(icon: "doc.on.clipboard", text: "tip.autocopy")
            }
            .padding(.horizontal, 24)

            Divider().padding(.vertical, 18)

            VStack(spacing: 10) {
                StepDots(current: 2, total: 3)
                Button(action: { state.onboardingCompleted = true }) {
                    Text(L("onboarding.finish"))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Shared Components

private struct FeatureRow: View {
    let icon: String; let color: Color; let title: String; let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout).fontWeight(.medium)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

@available(macOS 15.0, *)
struct PackageRow: View {
    enum Status { case waiting, downloading, done, failed }
    let flag: String; let title: String; let status: Status

    var body: some View {
        HStack(spacing: 10) {
            Text(flag).font(.body)
            Text(title).font(.callout)
            Spacer()
            statusIcon
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .animation(.easeInOut(duration: 0.3), value: status)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .waiting:
            Image(systemName: "circle").foregroundStyle(.tertiary)
        case .downloading:
            ProgressView().scaleEffect(0.65).frame(width: 16, height: 16)
        case .done:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
        }
    }
}

private struct TipRow: View {
    let icon: String; let text: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(text).font(.callout)
            Spacer()
        }
    }
}

private struct StepDots: View {
    let current: Int; let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.blue : Color.secondary.opacity(0.25))
                    .frame(width: i == current ? 20 : 8, height: 6)
                    .animation(.spring(duration: 0.3), value: current)
            }
        }
    }
}

import ActivityKit
import SwiftUI
import WidgetKit

private let wftGreen = Color(red: 63 / 255, green: 191 / 255, blue: 169 / 255)
private let wftBg = Color(red: 16 / 255, green: 22 / 255, blue: 21 / 255)
private let wftMuted = Color(red: 147 / 255, green: 163 / 255, blue: 158 / 255)

private func fmtRemaining(_ s: Double) -> String {
    let t = Int(max(0, s.rounded()))
    return String(format: "%d:%02d:%02d", t / 3600, (t % 3600) / 60, t % 60)
}

private func pausedFraction(_ s: FocusActivityAttributes.ContentState) -> Double {
    guard s.goalSeconds > 0 else { return 0 }
    return min(1, max(0, (s.goalSeconds - s.remainingSeconds) / s.goalSeconds))
}

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .activityBackgroundTint(wftBg)
                .activitySystemActionForegroundColor(wftGreen)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.objectiveName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimeText(state: context.state)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(wftGreen)
                        .frame(maxWidth: 72, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        ProgressBar(state: context.state)
                        ToggleButton(paused: context.state.paused)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: context.state.paused ? "pause.fill" : "timer")
                    .foregroundStyle(wftGreen)
            } compactTrailing: {
                TimeText(state: context.state)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(wftGreen)
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: context.state.paused ? "pause.fill" : "timer")
                    .foregroundStyle(wftGreen)
            }
            .keylineTint(wftGreen)
        }
    }
}

/// Countdown text: live-ticking while running, frozen while paused.
private struct TimeText: View {
    let state: FocusActivityAttributes.ContentState
    var body: some View {
        if state.paused {
            Text(fmtRemaining(state.remainingSeconds))
                .monospacedDigit()
        } else {
            Text(timerInterval: state.startReference ... state.endDate, countsDown: true)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }
}

/// Goal progress bar: animates natively while running, static while paused.
private struct ProgressBar: View {
    let state: FocusActivityAttributes.ContentState
    var body: some View {
        Group {
            if state.paused {
                ProgressView(value: pausedFraction(state))
            } else {
                ProgressView(timerInterval: state.startReference ... state.endDate, countsDown: false,
                             label: { EmptyView() }, currentValueLabel: { EmptyView() })
            }
        }
        .progressViewStyle(.linear)
        .tint(wftGreen)
        .shadow(color: wftGreen.opacity(0.55), radius: 4)
    }
}

private struct ToggleButton: View {
    let paused: Bool
    var body: some View {
        Button(intent: TimerControlIntent(pause: !paused)) {
            Image(systemName: paused ? "play.fill" : "pause.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(wftBg)
                .frame(width: 36, height: 36)
                .background(Circle().fill(wftGreen).shadow(color: wftGreen.opacity(0.6), radius: 6))
        }
        .buttonStyle(.plain)
    }
}

private struct LockScreenView: View {
    let state: FocusActivityAttributes.ContentState
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 7) {
                    Image(systemName: state.paused ? "pause.circle.fill" : "timer")
                        .foregroundStyle(wftGreen)
                        .shadow(color: wftGreen.opacity(0.6), radius: 5)
                    Text(state.objectiveName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                TimeText(state: state)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(wftGreen)
                    .shadow(color: wftGreen.opacity(0.5), radius: 5)
            }
            HStack(spacing: 14) {
                ProgressBar(state: state)
                ToggleButton(paused: state.paused)
            }
            Text(state.paused ? "Paused" : "Tracking — tap to open")
                .font(.caption)
                .foregroundStyle(wftMuted)
        }
        .padding(16)
    }
}

import Foundation
#if canImport(AppIntents) && canImport(ActivityKit)
import AppIntents
import ActivityKit

/// Pause/resume button inside the Live Activity. Runs in the app's process,
/// updates the activity UI immediately, and queues the action so the web app
/// applies it to its own timer state next time it wakes up.
@available(iOS 17.0, *)
public struct TimerControlIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Pause or resume focus timer"
    public static var openAppWhenRun: Bool = false

    @Parameter(title: "Pause")
    public var pause: Bool

    public init() {}
    public init(pause: Bool) {
        self.pause = pause
    }

    public func perform() async throws -> some IntentResult {
        let now = Date()

        // Queue the action (with its exact timestamp) for the web app.
        let defaults = UserDefaults.standard
        var pending = defaults.array(forKey: "wft-pending-actions") as? [[String: Any]] ?? []
        pending.append([
            "action": pause ? "pause" : "resume",
            "at": now.timeIntervalSince1970 * 1000.0
        ])
        defaults.set(pending, forKey: "wft-pending-actions")

        // Flip the Live Activity UI in place.
        for activity in Activity<FocusActivityAttributes>.activities {
            var s = activity.content.state
            if pause {
                guard !s.paused else { continue }
                s.remainingSeconds = max(0, s.endDate.timeIntervalSince(now))
                s.paused = true
            } else {
                guard s.paused else { continue }
                let spent = max(0, s.goalSeconds - s.remainingSeconds)
                s.startReference = now.addingTimeInterval(-spent)
                s.endDate = now.addingTimeInterval(s.remainingSeconds)
                s.paused = false
            }
            await activity.update(ActivityContent(state: s, staleDate: s.paused ? nil : s.endDate))
        }

        // Let the plugin know (if the app is awake) so the web UI updates live.
        NotificationCenter.default.post(name: Notification.Name("WFTTimerAction"), object: nil)
        return .result()
    }
}
#endif

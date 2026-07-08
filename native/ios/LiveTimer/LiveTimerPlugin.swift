import Foundation
import Capacitor
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Bridges the web app's timer state to an iOS Live Activity.
/// - `sync`: called whenever timer state changes; starts/updates/ends the activity.
/// - `consumeActions`: returns pause/resume actions taken from the Live Activity
///   (with timestamps) so the web app can apply them to its own state.
@objc(LiveTimerPlugin)
public class LiveTimerPlugin: CAPPlugin {

    public override func load() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onTimerAction),
            name: Notification.Name("WFTTimerAction"),
            object: nil
        )
    }

    @objc private func onTimerAction() {
        notifyListeners("timerAction", data: [:])
    }

    @objc func sync(_ call: CAPPluginCall) {
        guard #available(iOS 17.0, *) else {
            call.resolve(["supported": false])
            return
        }
        let running = call.getBool("running") ?? false
        let name = call.getString("name") ?? "Objective"
        let objectiveId = call.getString("id") ?? "objective"
        let remaining = call.getDouble("remainingSeconds") ?? 0
        let goal = call.getDouble("goalSeconds") ?? 0

        Task {
            if running && remaining > 0 && goal > 0 && ActivityAuthorizationInfo().areActivitiesEnabled {
                let now = Date()
                let spent = max(0, goal - remaining)
                let state = FocusActivityAttributes.ContentState(
                    objectiveName: name,
                    paused: false,
                    startReference: now.addingTimeInterval(-spent),
                    endDate: now.addingTimeInterval(remaining),
                    remainingSeconds: remaining,
                    goalSeconds: goal
                )
                let content = ActivityContent(state: state, staleDate: state.endDate)
                if let existing = Activity<FocusActivityAttributes>.activities.first {
                    await existing.update(content)
                } else {
                    _ = try? Activity.request(
                        attributes: FocusActivityAttributes(objectiveId: objectiveId),
                        content: content
                    )
                }
            } else {
                for activity in Activity<FocusActivityAttributes>.activities {
                    await activity.end(activity.content, dismissalPolicy: .immediate)
                }
            }
            call.resolve(["supported": true])
        }
    }

    @objc func consumeActions(_ call: CAPPluginCall) {
        let defaults = UserDefaults.standard
        let pending = defaults.array(forKey: "wft-pending-actions") as? [[String: Any]] ?? []
        defaults.removeObject(forKey: "wft-pending-actions")
        call.resolve(["actions": pending])
    }
}

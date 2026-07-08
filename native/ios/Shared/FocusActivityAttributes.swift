import Foundation
#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
public struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var objectiveName: String
        public var paused: Bool
        /// Anchor so a running progress bar can be rendered natively with no updates:
        /// startReference = now - spentSeconds, endDate = now + remainingSeconds.
        /// The interval's full span equals the weekly goal, so elapsed fraction == goal progress.
        public var startReference: Date
        public var endDate: Date
        /// Frozen values used while paused.
        public var remainingSeconds: Double
        public var goalSeconds: Double

        public init(objectiveName: String, paused: Bool, startReference: Date, endDate: Date,
                    remainingSeconds: Double, goalSeconds: Double) {
            self.objectiveName = objectiveName
            self.paused = paused
            self.startReference = startReference
            self.endDate = endDate
            self.remainingSeconds = remainingSeconds
            self.goalSeconds = goalSeconds
        }
    }

    public var objectiveId: String

    public init(objectiveId: String) {
        self.objectiveId = objectiveId
    }
}
#endif

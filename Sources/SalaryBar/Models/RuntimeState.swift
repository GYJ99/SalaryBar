import Foundation

struct RuntimeState: Codable {
    var dayAnchor: Date
    var manualPaused: Bool
    var pauseStartedAt: Date?
    var accumulatedPausedWorkSeconds: TimeInterval
    var notifiedGoalIDs: [UUID]

    static func `default`(calendar: Calendar = .current) -> RuntimeState {
        RuntimeState(
            dayAnchor: calendar.startOfDay(for: Date()),
            manualPaused: false,
            pauseStartedAt: nil,
            accumulatedPausedWorkSeconds: 0,
            notifiedGoalIDs: []
        )
    }
}

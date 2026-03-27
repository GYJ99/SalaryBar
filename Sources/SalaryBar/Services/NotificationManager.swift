import Foundation
import UserNotifications

actor NotificationManager {
    static let shared = NotificationManager()

    private var hasRequestedAuthorization = false

    func requestAuthorizationIfNeeded() async {
        guard !hasRequestedAuthorization else {
            return
        }
        hasRequestedAuthorization = true
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            print("Notification auth request failed: \(error)")
        }
    }

    func sendGoalUnlockedNotification(goal: GoalItem) async {
        let content = UNMutableNotificationContent()
        content.title = "回血目标解锁"
        content.body = "已赚到 \(goal.title)，继续冲。"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "goal-\(goal.id.uuidString)",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Goal notification failed: \(error)")
        }
    }
}

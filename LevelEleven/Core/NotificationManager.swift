// NotificationManager.swift — LevelEleven
// v1.0 | 2026-03-16
// - Local notification scheduling for aftercare hints and check-in reminders
// - In-app banner support via observable state
//

import Foundation
import UserNotifications

@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    var permissionGranted = false
    var pendingBanner: BannerInfo?

    struct BannerInfo: Identifiable {
        let id = UUID().uuidString
        let title: String
        let message: String
        let category: String // "aftercare" | "checkin"
    }

    // MARK: - Permission

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.permissionGranted = granted
            }
        }
    }

    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Aftercare Notifications

    /// Schedule aftercare hint notifications after a session ends
    func scheduleAftercareNotifications(sessionEndDate: Date, substanceIds: [String]) {
        let center = UNUserNotificationCenter.current()

        // Clear old aftercare notifications
        center.removePendingNotificationRequests(withIdentifiers: ["aftercare-"])

        let hints = AftercareEngine.allTimedHints.filter { hint in
            hint.substanceId == nil || substanceIds.contains(hint.substanceId!)
        }

        for hint in hints {
            var triggerDate: Date?

            if let hours = hint.triggerHoursAfterSession {
                triggerDate = sessionEndDate.addingTimeInterval(Double(hours) * 3600)
            } else if let days = hint.triggerDaysAfterSession {
                triggerDate = Calendar.current.date(byAdding: .day, value: days, to: sessionEndDate)
                // Schedule for 10:00 AM on that day
                if var date = triggerDate {
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                    components.hour = 10
                    components.minute = 0
                    if let adjusted = Calendar.current.date(from: components) {
                        date = adjusted
                    }
                    triggerDate = date
                }
            }

            guard let fireDate = triggerDate, fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = hint.title
            content.body = hint.message
            content.sound = .default
            content.categoryIdentifier = "aftercare"

            let interval = fireDate.timeIntervalSinceNow
            guard interval > 0 else { continue }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: "aftercare-\(hint.id)", content: content, trigger: trigger)

            center.add(request) { error in
                #if DEBUG
                if let error {
                    print("[Notifications] Failed to schedule aftercare: \(error)")
                }
                #endif
            }
        }

        #if DEBUG
        print("[Notifications] Scheduled aftercare notifications for \(substanceIds)")
        #endif
    }

    // MARK: - Check-in Reminders

    /// Schedule daily check-in reminders for 7 days after session
    func scheduleCheckInReminders(sessionEndDate: Date) {
        let center = UNUserNotificationCenter.current()

        // Clear old check-in reminders
        center.removePendingNotificationRequests(withIdentifiers:
            (1...7).map { "checkin-day-\($0)" }
        )

        for day in 1...7 {
            guard let reminderDate = Calendar.current.date(byAdding: .day, value: day, to: sessionEndDate) else { continue }

            var components = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
            components.hour = 11
            components.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "Wellbeing Check-in"
            content.body = day <= 3
                ? "How are you feeling today? Log a quick check-in to track your recovery."
                : "Day \(day) — a quick mood check helps you understand your patterns."
            content.sound = .default
            content.categoryIdentifier = "checkin"

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "checkin-day-\(day)", content: content, trigger: trigger)

            center.add(request) { error in
                #if DEBUG
                if let error {
                    print("[Notifications] Failed to schedule check-in day \(day): \(error)")
                }
                #endif
            }
        }

        #if DEBUG
        print("[Notifications] Scheduled 7-day check-in reminders")
        #endif
    }

    // MARK: - In-Session Check-in Reminder

    /// Schedule a check-in reminder during an active session (every 2 hours)
    func scheduleInSessionReminder(afterMinutes: Int = 120) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["session-checkin"])

        let content = UNMutableNotificationContent()
        content.title = "Session Check-in"
        content.body = "How are you feeling? Open the app to log a quick check-in."
        content.sound = .default
        content.categoryIdentifier = "session-checkin"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(afterMinutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "session-checkin", content: content, trigger: trigger)

        center.add(request)
    }

    /// Cancel in-session reminders (when session ends)
    func cancelInSessionReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["session-checkin"])
    }

    // MARK: - Cancel All

    func cancelAllAftercareNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.filter {
                $0.identifier.hasPrefix("aftercare-") || $0.identifier.hasPrefix("checkin-day-")
            }.map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - In-App Banner

    func showBanner(title: String, message: String, category: String = "aftercare") {
        DispatchQueue.main.async {
            self.pendingBanner = BannerInfo(title: title, message: message, category: category)

            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if self.pendingBanner?.title == title {
                    self.pendingBanner = nil
                }
            }
        }
    }
}

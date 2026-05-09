import UserNotifications

@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    var isAuthorized = false

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }

    func scheduleNotification(for slot: ScheduleSlot, on date: Date, reminderMinutes: Int) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        let title: String

        switch slot.scheduleType {
        case .individual:
            let studentName = slot.student?.name ?? "学生"
            title = "课程提醒"
            content.body = "\(studentName) 将在\(reminderMinutes)分钟后上课"
        case .group:
            let className = slot.groupClass?.name ?? "集体课"
            title = "集体课提醒"
            let count = slot.groupClass?.students?.count ?? 0
            content.body = "\(className) (\(count)名学生) 将在\(reminderMinutes)分钟后上课"
        }

        content.title = title

        // Schedule for `reminderMinutes` minutes before the lesson
        let triggerDate = Calendar.current.date(byAdding: .minute, value: -reminderMinutes, to: date) ?? date
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "\(slot.id.uuidString)_\(date.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelNotification(for slotID: UUID, on date: Date) {
        let identifier = "\(slotID.uuidString)_\(date.timeIntervalSince1970)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllNotifications(for slotID: UUID) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.identifier.hasPrefix(slotID.uuidString) }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
}

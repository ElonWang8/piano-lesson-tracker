import Foundation
import SwiftData

@Model
final class ScheduleSlot {
    var id: UUID
    var scheduleType: ScheduleType
    var student: Student?
    var groupClass: GroupClass?
    var weekday: Int
    var hour: Int
    var minute: Int
    var startTime: Date
    var duration: Int
    var location: String?
    var notes: String?
    var isActive: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        scheduleType: ScheduleType = .individual,
        student: Student? = nil,
        groupClass: GroupClass? = nil,
        weekday: Int = 2,
        hour: Int = 16,
        minute: Int = 0,
        startTime: Date = Date(),
        duration: Int = 45,
        location: String? = nil,
        notes: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scheduleType = scheduleType
        self.student = student
        self.groupClass = groupClass
        self.weekday = weekday
        self.hour = hour
        self.minute = minute
        self.startTime = startTime
        self.duration = duration
        self.location = location
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
    }

    var displayName: String {
        switch scheduleType {
        case .individual:
            return student?.name ?? "未指定"
        case .group:
            return groupClass?.name ?? "未指定"
        }
    }

    var weekdayName: String {
        let names = ["", "周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return (1...7).contains(weekday) ? names[weekday] : "未知"
    }

    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

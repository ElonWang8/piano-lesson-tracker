import Foundation
import SwiftData

@Model
final class ScheduleException {
    var id: UUID
    var scheduleSlot: ScheduleSlot?
    var exceptionType: ExceptionType
    var originalDate: Date
    var newDate: Date?
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        scheduleSlot: ScheduleSlot? = nil,
        exceptionType: ExceptionType = .cancelled,
        originalDate: Date = Date(),
        newDate: Date? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scheduleSlot = scheduleSlot
        self.exceptionType = exceptionType
        self.originalDate = originalDate
        self.newDate = newDate
        self.notes = notes
        self.createdAt = createdAt
    }

    var isExpired: Bool {
        let cutoff = exceptionType == .rescheduled ? (newDate ?? originalDate) : originalDate
        return cutoff < Calendar.current.startOfDay(for: Date())
    }
}

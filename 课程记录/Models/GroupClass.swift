import Foundation
import SwiftData

@Model
final class GroupClass {
    var id: UUID
    var name: String
    @Relationship(inverse: \Student.groupClasses)
    var students: [Student]?
    @Relationship(deleteRule: .cascade, inverse: \ScheduleSlot.groupClass)
    var scheduleSlots: [ScheduleSlot]?
    var totalLessons: Int
    var completedLessons: Int
    var price: Double
    var startDate: Date
    var notes: String?
    var isActive: Bool
    var createdAt: Date

    var remainingLessons: Int {
        max(0, totalLessons - completedLessons)
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        students: [Student] = [],
        totalLessons: Int = 0,
        completedLessons: Int = 0,
        price: Double = 0,
        startDate: Date = Date(),
        notes: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.students = students
        self.totalLessons = totalLessons
        self.completedLessons = completedLessons
        self.price = price
        self.startDate = startDate
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

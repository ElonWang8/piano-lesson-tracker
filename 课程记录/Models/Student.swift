import Foundation
import SwiftData

@Model
final class Student {
    var id: UUID
    var name: String
    var phone: String?
    var age: Int?
    var grade: String?
    var notes: String?
    var startDate: Date
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Lesson.student)
    var lessons: [Lesson]?

    @Relationship(deleteRule: .cascade, inverse: \Payment.student)
    var payments: [Payment]?

    @Relationship(deleteRule: .cascade, inverse: \ScheduleSlot.student)
    var scheduleSlots: [ScheduleSlot]?

    var groupClasses: [GroupClass]?

    var completedLessonCount: Int {
        (lessons ?? []).filter { $0.status == .completed }.count
    }

    var purchasedLessonCount: Int {
        (payments ?? []).reduce(0) { $0 + $1.lessonCount }
    }

    var remainingLessons: Int {
        max(0, purchasedLessonCount - completedLessonCount)
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        phone: String? = nil,
        age: Int? = nil,
        grade: String? = nil,
        notes: String? = nil,
        startDate: Date = Date(),
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.age = age
        self.grade = grade
        self.notes = notes
        self.startDate = startDate
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

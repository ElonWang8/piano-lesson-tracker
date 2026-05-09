import Foundation
import SwiftData

@Model
final class Lesson {
    var id: UUID
    var student: Student?
    var groupClass: GroupClass?
    var date: Date
    var duration: Int
    var content: String?
    var status: LessonStatus
    var isRescheduled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        student: Student? = nil,
        groupClass: GroupClass? = nil,
        date: Date = Date(),
        duration: Int = 45,
        content: String? = nil,
        status: LessonStatus = .scheduled,
        isRescheduled: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.student = student
        self.groupClass = groupClass
        self.date = date
        self.duration = duration
        self.content = content
        self.status = status
        self.isRescheduled = isRescheduled
        self.createdAt = createdAt
    }
}

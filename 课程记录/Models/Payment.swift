import Foundation
import SwiftData

@Model
final class Payment {
    var id: UUID
    var student: Student?
    var groupClass: GroupClass?
    var date: Date
    var amount: Double
    var validityStart: Date
    var validityEnd: Date
    var paymentMethod: PaymentMethod
    var lessonCount: Int
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        student: Student? = nil,
        groupClass: GroupClass? = nil,
        date: Date = Date(),
        amount: Double = 0,
        validityStart: Date = Date(),
        validityEnd: Date = Date(),
        paymentMethod: PaymentMethod = .wechat,
        lessonCount: Int = 4,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.student = student
        self.groupClass = groupClass
        self.date = date
        self.amount = amount
        self.validityStart = validityStart
        self.validityEnd = validityEnd
        self.paymentMethod = paymentMethod
        self.lessonCount = lessonCount
        self.notes = notes
        self.createdAt = createdAt
    }
}

import Foundation
import SwiftData

struct ScheduleOccurrence: Identifiable, Hashable {
    let id = UUID()
    let scheduleSlot: ScheduleSlot
    let date: Date
    let isRescheduled: Bool
    let originalWeekday: Int?
    var isCheckedIn: Bool = false
    var isCompleted: Bool = false

    var displayName: String {
        scheduleSlot.displayName
    }

    var scheduleType: ScheduleType {
        scheduleSlot.scheduleType
    }

    var student: Student? {
        scheduleSlot.student
    }

    var groupClass: GroupClass? {
        scheduleSlot.groupClass
    }

    var duration: Int {
        scheduleSlot.duration
    }
}

struct ScheduleRenderer {
    static func generateOccurrences(
        for date: Date,
        slots: [ScheduleSlot],
        exceptions: [ScheduleException],
        todayLessons: [Lesson]
    ) -> [ScheduleOccurrence] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let weekStart = date.startOfWeek
        var occurrences: [ScheduleOccurrence] = []

        for slot in slots where slot.isActive {
            let slotWeekday = slot.weekday
            let daysOffset = (slotWeekday - weekStart.weekday + 7) % 7
            let occurrenceDate = calendar.date(byAdding: .day, value: daysOffset, to: weekStart) ?? weekStart

            let fullDate = calendar.date(bySettingHour: slot.hour,
                                          minute: slot.minute,
                                          second: 0,
                                          of: occurrenceDate) ?? occurrenceDate

            let occurrence = ScheduleOccurrence(
                scheduleSlot: slot,
                date: fullDate,
                isRescheduled: false,
                originalWeekday: nil
            )
            occurrences.append(occurrence)
        }

        for exception in exceptions {
            guard let slot = exception.scheduleSlot else { continue }

            let exceptionDate = exception.exceptionType == .rescheduled
                ? (exception.newDate ?? exception.originalDate)
                : exception.originalDate

            if exceptionDate < calendar.startOfDay(for: weekStart) ||
               exceptionDate > calendar.startOfDay(for: weekStart.addingDays(6)).addingTimeInterval(86399) {
                continue
            }

            if exception.exceptionType == .cancelled {
                occurrences.removeAll { occ in
                    occ.scheduleSlot.id == slot.id &&
                    calendar.isDate(occ.date, inSameDayAs: exception.originalDate)
                }
            }

            if exception.exceptionType == .rescheduled, let newDate = exception.newDate {
                occurrences.removeAll { occ in
                    occ.scheduleSlot.id == slot.id &&
                    calendar.isDate(occ.date, inSameDayAs: exception.originalDate)
                }

                let timeComponents = calendar.dateComponents([.hour, .minute], from: newDate)
                let fullNewDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                 minute: timeComponents.minute ?? 0,
                                                 second: 0,
                                                 of: newDate) ?? newDate

                if fullNewDate >= weekStart && fullNewDate < weekStart.addingDays(7) {
                    let rescheduledOccurrence = ScheduleOccurrence(
                        scheduleSlot: slot,
                        date: fullNewDate,
                        isRescheduled: true,
                        originalWeekday: exception.originalDate.weekday
                    )
                    occurrences.append(rescheduledOccurrence)
                }
            }
        }

        for i in occurrences.indices {
            let occ = occurrences[i]
            let matchingLesson = todayLessons.first { lesson in
                lesson.student?.id == occ.student?.id &&
                calendar.isDate(lesson.date, inSameDayAs: occ.date)
            }
            if let lesson = matchingLesson {
                occurrences[i].isCheckedIn = true
                occurrences[i].isCompleted = lesson.status == .completed
            }
        }

        return occurrences.sorted { $0.date < $1.date }
    }

    // MARK: - Lesson Auto-Generation

    static func generateLessons(for slot: ScheduleSlot, modelContext: ModelContext) -> Int {
        guard let student = slot.student else { return 0 }

        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let remaining = student.remainingLessons

        let allLessons = student.lessons ?? []
        var existingDates = Set(allLessons.map { calendar.startOfDay(for: $0.date) })

        let exceptions = (try? modelContext.fetch(FetchDescriptor<ScheduleException>())) ?? []
        let cancelledDates = Set(exceptions.compactMap { ex in
            ex.scheduleSlot?.id == slot.id && ex.exceptionType == .cancelled
                ? calendar.startOfDay(for: ex.originalDate) : nil
        })
        let rescheduledFromDates = Set(exceptions.compactMap { ex in
            ex.scheduleSlot?.id == slot.id && ex.exceptionType == .rescheduled
                ? calendar.startOfDay(for: ex.originalDate) : nil
        })

        let slotWeekday = slot.weekday
        let existingScheduledCount = allLessons.filter { lesson in
            lesson.status == .scheduled &&
            calendar.component(.weekday, from: lesson.date) == slotWeekday &&
            calendar.component(.hour, from: lesson.date) == slot.hour
        }.count

        let needToGenerate = max(0, remaining - existingScheduledCount)
        guard needToGenerate > 0 else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let weekStart = today.startOfWeek
        var generated = 0
        var weekOffset = 0

        while generated < needToGenerate && weekOffset < 52 {
            let baseWeekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: weekStart) ?? weekStart
            let daysOffset = (slotWeekday - baseWeekStart.weekday + 7) % 7
            let occurrenceDate = calendar.date(byAdding: .day, value: daysOffset, to: baseWeekStart) ?? baseWeekStart

            let lessonDate = calendar.date(bySettingHour: slot.hour,
                                            minute: slot.minute,
                                            second: 0,
                                            of: occurrenceDate) ?? occurrenceDate

            let lessonDay = calendar.startOfDay(for: lessonDate)

            if lessonDay >= today,
               !existingDates.contains(lessonDay),
               !cancelledDates.contains(lessonDay),
               !rescheduledFromDates.contains(lessonDay) {
                let lesson = Lesson(
                    student: student,
                    date: lessonDate,
                    duration: slot.duration,
                    status: .scheduled
                )
                modelContext.insert(lesson)
                existingDates.insert(lessonDay)
                generated += 1
            }
            weekOffset += 1
        }

        return generated
    }

    static func fillLessons(for student: Student, modelContext: ModelContext) -> Int {
        guard let slots = student.scheduleSlots, !slots.isEmpty else { return 0 }
        var total = 0
        for slot in slots where slot.isActive {
            total += generateLessons(for: slot, modelContext: modelContext)
        }
        return total
    }

    static func occurrencesForDay(
        _ day: Date,
        occurrences: [ScheduleOccurrence]
    ) -> [ScheduleOccurrence] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return occurrences.filter { calendar.isDate($0.date, inSameDayAs: day) }
    }
}

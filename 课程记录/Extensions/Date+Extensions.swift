import Foundation

extension Date {
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    var endOfWeek: Date {
        let calendar = Calendar.current
        let start = startOfWeek
        return calendar.date(byAdding: .day, value: 6, to: start) ?? self
    }

    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    var endOfMonth: Date {
        let calendar = Calendar.current
        let start = startOfMonth
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? self
    }

    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }

    static var todayStart: Date {
        Calendar.current.startOfDay(for: Date())
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }

    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: self)
    }

    func fullDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: self)
    }

    func weekdayShortString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }

    func monthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        return formatter.string(from: self)
    }

    func yearMonthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: self)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

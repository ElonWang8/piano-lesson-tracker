import SwiftUI
import SwiftData

struct LessonCalendarView: View {
    @Query private var lessons: [Lesson]
    @State private var currentMonth: Date
    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let dayNames = ["一", "二", "三", "四", "五", "六", "日"]

    init() {
        _currentMonth = State(initialValue: Date().startOfMonth)
    }

    var body: some View {
        VStack(spacing: 0) {
            monthHeader

            HStack(spacing: 0) {
                ForEach(dayNames, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)

            let days = generateDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        let hasLesson = lessonsForDate(date).count > 0

                        VStack(spacing: 4) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 14, weight: date.isSameDay(as: selectedDate ?? Date()) ? .bold : .regular))
                                .foregroundColor(dayTextColor(date))
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(date.isToday() ? Color.blue : (date.isSameDay(as: selectedDate ?? Date()) ? Color.blue.opacity(0.2) : Color.clear))
                                )

                            if hasLesson {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 4, height: 4)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Text("")
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .padding(.horizontal, 4)

            if let selected = selectedDate {
                Divider().padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 0) {
                    Text(selected.fullDateString())
                        .font(.subheadline.bold())
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    let dayLessons = lessonsForDate(selected)
                    if dayLessons.isEmpty {
                        Text("当天无课程")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(dayLessons) { lesson in
                            NavigationLink {
                                LessonDetailView(lesson: lesson)
                            } label: {
                                LessonRowView(lesson: lesson)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()
            Text(currentMonth.yearMonthString())
                .font(.headline)
            Spacer()

            Button {
                currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
    }

    private func generateDays() -> [Date?] {
        let start = currentMonth
        let firstWeekday = start.weekday
        let offset = (firstWeekday + 5) % 7

        let daysInMonth = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        var days: [Date?] = Array(repeating: nil, count: offset)

        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: start) {
                days.append(date)
            }
        }

        let remaining = 42 - days.count
        if remaining > 0 {
            days.append(contentsOf: Array(repeating: nil, count: remaining))
        }

        return days
    }

    private func dayTextColor(_ date: Date) -> Color {
        if date.isToday() {
            return .white
        }
        if !calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
            return .secondary.opacity(0.3)
        }
        return .primary
    }

    private func lessonsForDate(_ date: Date) -> [Lesson] {
        lessons.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }
}

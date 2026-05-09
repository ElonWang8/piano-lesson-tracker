import SwiftUI
import SwiftData

struct ClassScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScheduleSlot.startTime) private var slots: [ScheduleSlot]
    @Query private var exceptions: [ScheduleException]
    @Query private var lessons: [Lesson]

    @State private var currentWeekStart: Date
    @State private var showingScheduleForm = false
    @State private var showingExceptionForm = false
    @State private var editingSlot: ScheduleSlot?
    @State private var selectedSlotForException: ScheduleSlot?
    @State private var exceptionOriginalDate: Date?
    @State private var showingGroupCheckIn = false
    @State private var selectedGroupClass: GroupClass?
    @State private var selectedOccurrence: ScheduleOccurrence?

    @State private var showingCancelAlert = false
    @State private var cancelSlot: ScheduleSlot?
    @State private var cancelDate: Date?

    @State private var selectedStudent: Student?
    @State private var navigateToStudent = false

    private let calendar = Calendar.current
    private let timeSlots: [Int] = Array(stride(from: 8, through: 21, by: 1))
    private let rowHeight: CGFloat = 38

    init() {
        let today = Date()
        _currentWeekStart = State(initialValue: today.startOfWeek)
    }

    var body: some View {
        VStack(spacing: 0) {
            weekHeader

            HStack(spacing: 0) {
                timeColumn

                ScrollView(.horizontal, showsIndicators: false) {
                    scheduleGrid
                }
            }
        }
        .navigationTitle("课程表")
        .navigationBarTitleDisplayMode(.inline)
        .padding(.top, 4)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingSlot = nil
                    showingScheduleForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    currentWeekStart = Date().startOfWeek
                } label: {
                    Text("今天")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(12)
                }
            }
        }
        .sheet(isPresented: $showingScheduleForm) {
            ScheduleFormView(existingSlot: editingSlot)
        }
        .sheet(isPresented: $showingExceptionForm) {
            if let slot = selectedSlotForException, let originalDate = exceptionOriginalDate {
                ScheduleExceptionFormView(
                    scheduleSlot: slot,
                    originalDate: originalDate
                )
            }
        }
        .sheet(isPresented: $showingGroupCheckIn) {
            if let gc = selectedGroupClass, let occ = selectedOccurrence {
                GroupCheckInView(groupClass: gc, occurrence: occ)
            }
        }
        .alert("取消本次课程", isPresented: $showingCancelAlert) {
            Button("确定取消", role: .destructive) {
                cancelThisOccurrence()
            }
            Button("再想想", role: .cancel) {}
        } message: {
            Text("该课程将在本周课程表中隐藏，下周自动恢复。确定要取消吗？")
        }
        .navigationDestination(isPresented: $navigateToStudent) {
            if let student = selectedStudent {
                StudentDetailView(student: student)
            }
        }
    }

    private var weekHeader: some View {
        HStack(spacing: 0) {
            Button {
                currentWeekStart = calendar.date(byAdding: .day, value: -7, to: currentWeekStart) ?? currentWeekStart
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
            }
            .frame(width: 44)

            Spacer()

            VStack(spacing: 2) {
                Text(weekRangeString)
                    .font(.system(size: 17, weight: .semibold))
                Text(currentWeekStart.yearMonthString())
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                currentWeekStart = calendar.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
            }
            .frame(width: 44)
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var weekRangeString: String {
        let end = currentWeekStart.addingDays(6)
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return "\(formatter.string(from: currentWeekStart)) - \(formatter.string(from: end))"
    }

    private var timeColumn: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 30)

            ForEach(timeSlots, id: \.self) { hour in
                Text(String(format: "%02d:00", hour))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: rowHeight, alignment: .top)
            }
        }
    }

    private var scheduleGrid: some View {
        let occurrences = ScheduleRenderer.generateOccurrences(
            for: currentWeekStart,
            slots: slots,
            exceptions: exceptions,
            todayLessons: lessons
        )

        let groupedByDay = groupOccurrencesByDay(occurrences)

        return VStack(spacing: 0) {
            dayHeaderRow

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    ForEach(timeSlots, id: \.self) { hour in
                        Divider()
                            .frame(height: rowHeight)
                    }
                }

                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { dayOffset in
                        let dayDate = currentWeekStart.addingDays(dayOffset)
                        let dayOccurrences = groupedByDay[dayOffset] ?? []

                        VStack(spacing: 0) {
                            ZStack(alignment: .top) {
                                ForEach(dayOccurrences) { occ in
                                    if let slotIndex = timeSlotIndex(for: occ) {
                                        let cellHeight = CGFloat(occ.duration) / 60.0 * rowHeight
                                        ScheduleSlotCell(
                                            occurrence: occ,
                                            onCheckIn: {
                                                checkIn(occurrence: occ)
                                            },
                                            onLongPress: {
                                                handleLongPress(occurrence: occ)
                                            }
                                        )
                                        .frame(height: cellHeight)
                                        .offset(y: CGFloat(slotIndex) * rowHeight + 1)
                                        .padding(.horizontal, 1)
                                        .onTapGesture {
                                            handleCellTap(occurrence: occ)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: cellWidth)

                        if dayOffset < 6 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var cellWidth: CGFloat {
        let totalWidth = UIScreen.main.bounds.width - 30
        return (totalWidth - 6) / 7.0
    }

    private var dayHeaderRow: some View {
        let dayNames = ["一", "二", "三", "四", "五", "六", "日"]
        let today = Date()

        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { offset in
                let dayDate = currentWeekStart.addingDays(offset)
                let isToday = calendar.isDate(dayDate, inSameDayAs: today)
                let isWeekend = offset >= 5

                VStack(spacing: 1) {
                    Text(dayNames[offset])
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isToday ? .white : (isWeekend ? .secondary : .secondary))
                    Text("\(calendar.component(.day, from: dayDate))")
                        .font(.system(size: 14, weight: isToday ? .bold : .medium))
                        .foregroundColor(isToday ? .white : (isWeekend ? .secondary : .primary))
                }
                .frame(width: cellWidth, height: 32)
                .background(
                    isToday
                        ? RoundedRectangle(cornerRadius: 8).fill(Color.blue).shadow(color: .blue.opacity(0.3), radius: 3, y: 1)
                        : nil
                )
            }
        }
        .padding(.bottom, 6)
        .padding(.horizontal, 1)
    }

    private func groupOccurrencesByDay(_ occurrences: [ScheduleOccurrence]) -> [Int: [ScheduleOccurrence]] {
        var result: [Int: [ScheduleOccurrence]] = [:]
        for occ in occurrences {
            let dayOffset = calendar.dateComponents([.day], from: currentWeekStart, to: occ.date.startOfDay).day ?? 0
            if dayOffset >= 0 && dayOffset < 7 {
                result[dayOffset, default: []].append(occ)
            }
        }
        return result
    }

    private func timeSlotIndex(for occurrence: ScheduleOccurrence) -> Int? {
        let hour = calendar.component(.hour, from: occurrence.date)
        let minute = calendar.component(.minute, from: occurrence.date)
        guard let startIdx = timeSlots.firstIndex(of: hour) else { return nil }
        let fractionalOffset = Double(minute) / 60.0
        return startIdx + (fractionalOffset > 0 ? 1 : 0)
    }

    private func handleCellTap(occurrence: ScheduleOccurrence) {
        switch occurrence.scheduleType {
        case .individual:
            selectedStudent = occurrence.student
            navigateToStudent = true
        case .group:
            selectedGroupClass = occurrence.groupClass
            selectedOccurrence = occurrence
            showingGroupCheckIn = true
        }
    }

    private func handleLongPress(occurrence: ScheduleOccurrence) {
        selectedSlotForException = occurrence.scheduleSlot
        exceptionOriginalDate = occurrence.date
        showingExceptionForm = true
    }

    private func checkIn(occurrence: ScheduleOccurrence) {
        guard let student = occurrence.student else { return }

        // 查找已有的 scheduled lesson
        if let existingLesson = lessons.first(where: { lesson in
            lesson.student?.id == student.id &&
            calendar.isDate(lesson.date, inSameDayAs: occurrence.date) &&
            lesson.status == .scheduled
        }) {
            existingLesson.status = .completed
            existingLesson.isRescheduled = occurrence.isRescheduled
            existingLesson.duration = occurrence.duration
            if let gc = occurrence.groupClass {
                gc.completedLessons += 1
            }
            return
        }

        // 若无 scheduled lesson，检查是否已签到
        let alreadyCheckedIn = lessons.contains { lesson in
            lesson.student?.id == student.id &&
            calendar.isDate(lesson.date, inSameDayAs: occurrence.date) &&
            lesson.status == .completed
        }

        guard !alreadyCheckedIn else { return }

        // 创建新记录（兼容旧数据或手动签到）
        let lesson = Lesson(
            student: student,
            groupClass: occurrence.groupClass,
            date: occurrence.date,
            duration: occurrence.duration,
            status: .completed,
            isRescheduled: occurrence.isRescheduled
        )
        modelContext.insert(lesson)

        if let gc = occurrence.groupClass {
            gc.completedLessons += 1
        }
    }

    private func cancelThisOccurrence() {
        guard let slot = cancelSlot, let date = cancelDate else { return }
        let exception = ScheduleException(
            scheduleSlot: slot,
            exceptionType: .cancelled,
            originalDate: date
        )
        modelContext.insert(exception)
        cancelSlot = nil
        cancelDate = nil
    }
}

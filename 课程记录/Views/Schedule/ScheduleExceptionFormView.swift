import SwiftUI
import SwiftData

struct ScheduleExceptionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let scheduleSlot: ScheduleSlot
    let originalDate: Date

    @State private var exceptionType: ExceptionType = .rescheduled
    @State private var newDate: Date
    @State private var notes: String = ""

    private let calendar = Calendar.current

    init(scheduleSlot: ScheduleSlot, originalDate: Date) {
        self.scheduleSlot = scheduleSlot
        self.originalDate = originalDate
        _newDate = State(initialValue: originalDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("课程信息") {
                    LabeledContent("学生/班级") {
                        Text(scheduleSlot.displayName)
                    }
                    LabeledContent("原上课时间") {
                        Text(formattedDate(originalDate))
                            .foregroundColor(.secondary)
                    }
                }

                Section("调整方式") {
                    Picker("类型", selection: $exceptionType) {
                        ForEach(ExceptionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if exceptionType == .rescheduled {
                    Section("新课时间") {
                        DatePicker("日期时间", selection: $newDate, displayedComponents: [.date, .hourAndMinute])

                        if !calendar.isDate(newDate, inSameDayAs: originalDate) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.orange)
                                Text("已调整到不同日期，下周自动恢复原排课")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }

                        if calendar.isDate(newDate, inSameDayAs: originalDate) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("仅调整时间，保持原日期")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }

                if exceptionType == .cancelled {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.gray)
                            Text("本次课程将在课程表中隐藏，下周自动恢复")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("备注（可选）") {
                    TextField("如：学生考试、临时有事", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("临时调整")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认") { saveException() }
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 (EEE) HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private func saveException() {
        let exception = ScheduleException(
            scheduleSlot: scheduleSlot,
            exceptionType: exceptionType,
            originalDate: originalDate,
            newDate: exceptionType == .rescheduled ? newDate : nil,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(exception)
        dismiss()
    }
}

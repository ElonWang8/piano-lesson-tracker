import SwiftUI
import SwiftData

struct ScheduleFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let existingSlot: ScheduleSlot?
    let preselectedStudent: Student?
    let preselectedGroupClass: GroupClass?

    @State private var scheduleType: ScheduleType = .individual
    @State private var selectedStudent: Student?
    @State private var selectedGroupClass: GroupClass?
    @State private var weekday: Int = 2
    @State private var startTime = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var duration: Int = 45
    @State private var location: String = ""
    @State private var notes: String = ""

    @Query(sort: \Student.name) private var students: [Student]
    @Query(sort: \GroupClass.name) private var groupClasses: [GroupClass]

    private let weekdays = ["", "周日", "周一", "周二", "周三", "周四", "周五", "周六"]
    private let durations = [30, 45, 60, 90, 120]

    var body: some View {
        NavigationStack {
            Form {
                Section("课程类型") {
                    Picker("类型", selection: $scheduleType) {
                        ForEach(ScheduleType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(scheduleType == .individual ? "学生" : "集体课") {
                    if scheduleType == .individual {
                        Picker("学生", selection: $selectedStudent) {
                            Text("请选择").tag(nil as Student?)
                            ForEach(students.filter { $0.isActive }) { student in
                                Text(student.name).tag(student as Student?)
                            }
                        }
                    } else {
                        Picker("集体课", selection: $selectedGroupClass) {
                            Text("请选择").tag(nil as GroupClass?)
                            ForEach(groupClasses.filter { $0.isActive }) { gc in
                                Text(gc.name).tag(gc as GroupClass?)
                            }
                        }
                    }
                }

                Section("上课时间") {
                    Picker("星期", selection: $weekday) {
                        ForEach(1..<8) { index in
                            Text(weekdays[index]).tag(index)
                        }
                    }

                    DatePicker("时间", selection: $startTime, displayedComponents: .hourAndMinute)

                    Picker("时长", selection: $duration) {
                        ForEach(durations, id: \.self) { d in
                            Text("\(d)分钟").tag(d)
                        }
                    }
                }

                Section("其他（可选）") {
                    TextField("地点", text: $location)
                    TextField("备注", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(existingSlot == nil ? "添加排课" : "编辑排课")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear { populateExisting() }
        }
    }

    private var isValid: Bool {
        switch scheduleType {
        case .individual:
            return selectedStudent != nil
        case .group:
            return selectedGroupClass != nil
        }
    }

    private func populateExisting() {
        guard let slot = existingSlot else {
            if let student = preselectedStudent {
                selectedStudent = student
            }
            if let gc = preselectedGroupClass {
                scheduleType = .group
                selectedGroupClass = gc
            }
            return
        }
        scheduleType = slot.scheduleType
        selectedStudent = slot.student
        selectedGroupClass = slot.groupClass
        weekday = slot.weekday
        startTime = slot.startTime
        duration = slot.duration
        location = slot.location ?? ""
        notes = slot.notes ?? ""
    }

    private func save() {
        let cal = Calendar.current
        let h = cal.component(.hour, from: startTime)
        let m = cal.component(.minute, from: startTime)
        if let slot = existingSlot {
            slot.scheduleType = scheduleType
            slot.student = selectedStudent
            slot.groupClass = selectedGroupClass
            slot.weekday = weekday
            slot.hour = h
            slot.minute = m
            slot.startTime = startTime
            slot.duration = duration
            slot.location = location.isEmpty ? nil : location
            slot.notes = notes.isEmpty ? nil : notes
        } else {
            let slot = ScheduleSlot(
                scheduleType: scheduleType,
                student: selectedStudent,
                groupClass: selectedGroupClass,
                weekday: weekday,
                hour: h,
                minute: m,
                startTime: startTime,
                duration: duration,
                location: location.isEmpty ? nil : location,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(slot)

            if scheduleType == .individual, let _ = selectedStudent {
                _ = ScheduleRenderer.generateLessons(for: slot, modelContext: modelContext)
            }
        }
        dismiss()
    }

    init(
        existingSlot: ScheduleSlot? = nil,
        preselectedStudent: Student? = nil,
        preselectedGroupClass: GroupClass? = nil
    ) {
        self.existingSlot = existingSlot
        self.preselectedStudent = preselectedStudent
        self.preselectedGroupClass = preselectedGroupClass
    }
}

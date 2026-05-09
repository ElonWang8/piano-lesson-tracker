import SwiftUI
import SwiftData

struct GroupCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let groupClass: GroupClass
    let occurrence: ScheduleOccurrence

    @Query private var todayLessons: [Lesson]
    @State private var selectedStudents: Set<UUID> = []
    @State private var showLowReminder = false
    @State private var showDuplicateAlert = false

    private let calendar = Calendar.current

    init(groupClass: GroupClass, occurrence: ScheduleOccurrence) {
        self.groupClass = groupClass
        self.occurrence = occurrence
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text(groupClass.name)
                        .font(.title2.bold())

                    HStack {
                        Label("\(groupClass.remainingLessons)课时剩余", systemImage: "creditcard")
                            .foregroundColor(remainingColor)
                        Spacer()
                        Label("已上\(groupClass.completedLessons)/\(groupClass.totalLessons)", systemImage: "checkmark")
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                    .padding(.horizontal)
                }
                .padding(.vertical)

                Divider()

                List {
                    Section("签到学生（\(selectedStudents.count)/\(students.count)）") {
                        ForEach(students) { student in
                            let alreadyChecked = isAlreadyCheckedIn(student: student)
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(student.name)
                                        .font(.body)
                                    if let grade = student.grade {
                                        Text(grade)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if alreadyChecked {
                                    Label("已签到", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Button {
                                        toggleStudent(student)
                                    } label: {
                                        Image(systemName: selectedStudents.contains(student.id)
                                            ? "checkmark.circle.fill"
                                            : "circle")
                                        .font(.title3)
                                        .foregroundColor(selectedStudents.contains(student.id) ? .blue : .gray)
                                    }
                                }
                            }
                            .opacity(alreadyChecked ? 0.5 : 1.0)
                        }
                    }

                    Section {
                        Button {
                            if selectedStudents.isEmpty {
                                selectedStudents = Set(students.filter { !isAlreadyCheckedIn(student: $0) }.map(\.id))
                            } else {
                                selectedStudents = []
                            }
                        } label: {
                            Text(selectedStudents.isEmpty ? "全选" : "取消全选")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("集体课签到")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("签到 (\(selectedStudents.count))") {
                        performCheckIn()
                    }
                    .disabled(selectedStudents.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .alert("课包即将用完", isPresented: $showLowReminder) {
                Button("知道了") {}
            } message: {
                Text("该集体课仅剩 \(groupClass.remainingLessons) 课时，请及时续费。")
            }
            .alert("重复签到", isPresented: $showDuplicateAlert) {
                Button("确定") {}
            } message: {
                Text("部分学生今天已经签到过了，已自动跳过。")
            }
        }
        .onAppear {
            selectedStudents = Set(students.filter { !isAlreadyCheckedIn(student: $0) }.map(\.id))
        }
    }

    private var students: [Student] {
        (groupClass.students ?? []).filter { $0.isActive }
    }

    private var remainingColor: Color {
        let remaining = groupClass.remainingLessons
        if remaining > 10 { return .green }
        if remaining >= 3 { return .orange }
        return .red
    }

    private func isAlreadyCheckedIn(student: Student) -> Bool {
        todayLessons.contains { lesson in
            lesson.student?.id == student.id &&
            lesson.groupClass?.id == groupClass.id &&
            calendar.isDate(lesson.date, inSameDayAs: occurrence.date) &&
            lesson.status == .completed
        }
    }

    private func toggleStudent(_ student: Student) {
        if selectedStudents.contains(student.id) {
            selectedStudents.remove(student.id)
        } else {
            selectedStudents.insert(student.id)
        }
    }

    private func performCheckIn() {
        var hadDuplicate = false

        for student in students where selectedStudents.contains(student.id) {
            guard !isAlreadyCheckedIn(student: student) else {
                hadDuplicate = true
                continue
            }

            let lesson = Lesson(
                student: student,
                groupClass: groupClass,
                date: occurrence.date,
                duration: occurrence.duration,
                status: .completed,
                isRescheduled: occurrence.isRescheduled
            )
            modelContext.insert(lesson)
        }

        groupClass.completedLessons += 1

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        if groupClass.remainingLessons <= 2 {
            showLowReminder = true
        }

        if hadDuplicate {
            showDuplicateAlert = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

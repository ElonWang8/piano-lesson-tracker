import SwiftUI
import SwiftData

struct LessonFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let existingLesson: Lesson?
    let preselectedStudent: Student?

    @State private var selectedStudent: Student?
    @State private var lessonDate: Date = Date()
    @State private var duration: Int = 45
    @State private var content: String = ""
    @State private var status: LessonStatus = .completed

    @Query(sort: \Student.name) private var students: [Student]
    private let durations = [30, 45, 60, 90, 120]

    init(existingLesson: Lesson? = nil, preselectedStudent: Student? = nil) {
        self.existingLesson = existingLesson
        self.preselectedStudent = preselectedStudent
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("学生") {
                    Picker("学生", selection: $selectedStudent) {
                        Text("请选择").tag(nil as Student?)
                        ForEach(students.filter { $0.isActive }) { student in
                            Text(student.name).tag(student as Student?)
                        }
                    }
                }

                Section("课程时间") {
                    DatePicker("日期时间", selection: $lessonDate, displayedComponents: [.date, .hourAndMinute])

                    Picker("时长", selection: $duration) {
                        ForEach(durations, id: \.self) { d in
                            Text("\(d)分钟").tag(d)
                        }
                    }
                }

                Section("状态") {
                    Picker("状态", selection: $status) {
                        ForEach(LessonStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("课堂内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(existingLesson == nil ? "添加课程" : "编辑课程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(selectedStudent == nil)
                }
            }
            .onAppear { populateExisting() }
        }
    }

    private func populateExisting() {
        if let lesson = existingLesson {
            selectedStudent = lesson.student
            lessonDate = lesson.date
            duration = lesson.duration
            content = lesson.content ?? ""
            status = lesson.status
        } else if let student = preselectedStudent {
            selectedStudent = student
        }
    }

    private func save() {
        guard let student = selectedStudent else { return }

        if let lesson = existingLesson {
            lesson.student = student
            lesson.date = lessonDate
            lesson.duration = duration
            lesson.content = content.isEmpty ? nil : content
            lesson.status = status
        } else {
            let lesson = Lesson(
                student: student,
                date: lessonDate,
                duration: duration,
                content: content.isEmpty ? nil : content,
                status: status
            )
            modelContext.insert(lesson)
        }
        dismiss()
    }
}

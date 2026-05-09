import SwiftUI
import SwiftData

struct StudentFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let existingStudent: Student?

    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var age: Int = 7
    @State private var grade: String = ""
    @State private var notes: String = ""
    @State private var startDate: Date = Date()
    @State private var isActive: Bool = true

    @State private var showNameError = false

    let gradeOptions = [
        "学龄前", "小学一年级", "小学二年级", "小学三年级",
        "小学四年级", "小学五年级", "小学六年级",
        "初中一年级", "初中二年级", "初中三年级",
        "高中一年级", "高中二年级", "高中三年级",
        "大学", "成人"
    ]

    init(existingStudent: Student? = nil) {
        self.existingStudent = existingStudent
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    HStack {
                        Text("姓名")
                        Text("*")
                            .foregroundColor(.red)
                            .font(.caption)
                        TextField("必填", text: $name)
                            .multilineTextAlignment(.trailing)
                    }

                    TextField("手机号", text: $phone)
                        .keyboardType(.phonePad)

                    Stepper("年龄: \(age)", value: $age, in: 3...99)

                    Picker("年级", selection: $grade) {
                        Text("未设置").tag("")
                        ForEach(gradeOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }

                Section("学琴信息") {
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)

                    Toggle("活跃状态", isOn: $isActive)
                }

                Section("备注") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(existingStudent == nil ? "添加学生" : "编辑学生")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("请输入姓名", isPresented: $showNameError) {
                Button("确定") {}
            }
            .onAppear { populateExisting() }
        }
    }

    private func populateExisting() {
        guard let student = existingStudent else { return }
        name = student.name
        phone = student.phone ?? ""
        age = student.age ?? 7
        grade = student.grade ?? ""
        notes = student.notes ?? ""
        startDate = student.startDate
        isActive = student.isActive
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            showNameError = true
            return
        }

        if let student = existingStudent {
            student.name = trimmedName
            student.phone = phone.isEmpty ? nil : phone
            student.age = age
            student.grade = grade.isEmpty ? nil : grade
            student.notes = notes.isEmpty ? nil : notes
            student.startDate = startDate
            student.isActive = isActive
        } else {
            let student = Student(
                name: trimmedName,
                phone: phone.isEmpty ? nil : phone,
                age: age,
                grade: grade.isEmpty ? nil : grade,
                notes: notes.isEmpty ? nil : notes,
                startDate: startDate,
                isActive: isActive
            )
            modelContext.insert(student)
        }
        dismiss()
    }
}

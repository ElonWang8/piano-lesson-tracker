import SwiftUI
import SwiftData

struct GroupClassFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let existingGroupClass: GroupClass?

    @State private var name: String = ""
    @State private var selectedStudentIDs: Set<UUID> = []
    @State private var totalLessons: Int = 12
    @State private var price: Double = 0
    @State private var startDate: Date = Date()
    @State private var notes: String = ""
    @State private var isActive: Bool = true

    @Query(sort: \Student.name) private var allStudents: [Student]

    @State private var showNameError = false

    init(existingGroupClass: GroupClass? = nil) {
        self.existingGroupClass = existingGroupClass
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    HStack {
                        Text("名称")
                        Text("*").foregroundColor(.red).font(.caption)
                        TextField("如：周六启蒙班", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("学生（\(selectedStudentIDs.count)人）") {
                    ForEach(allStudents.filter { $0.isActive }) { student in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(student.name)
                                if let grade = student.grade {
                                    Text(grade)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: selectedStudentIDs.contains(student.id)
                                ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedStudentIDs.contains(student.id) ? .blue : .gray)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedStudentIDs.contains(student.id) {
                                selectedStudentIDs.remove(student.id)
                            } else {
                                selectedStudentIDs.insert(student.id)
                            }
                        }
                    }
                }

                Section("课包设置") {
                    Stepper("总课时: \(totalLessons)", value: $totalLessons, in: 1...100)

                    HStack {
                        Text("总价")
                        TextField("0", value: $price, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("元")
                            .foregroundColor(.secondary)
                    }

                    DatePicker("开课日期", selection: $startDate, displayedComponents: .date)

                    Toggle("活跃状态", isOn: $isActive)
                }

                Section("备注") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle(existingGroupClass == nil ? "创建集体课" : "编辑集体课")
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
            .alert("请输入名称", isPresented: $showNameError) {
                Button("确定") {}
            }
            .onAppear { populateExisting() }
        }
    }

    private func populateExisting() {
        guard let gc = existingGroupClass else { return }
        name = gc.name
        selectedStudentIDs = Set((gc.students ?? []).map(\.id))
        totalLessons = gc.totalLessons
        price = gc.price
        startDate = gc.startDate
        notes = gc.notes ?? ""
        isActive = gc.isActive
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            showNameError = true
            return
        }

        let selectedStudents = allStudents.filter { selectedStudentIDs.contains($0.id) }

        if let gc = existingGroupClass {
            gc.name = trimmedName
            gc.students = selectedStudents
            gc.totalLessons = totalLessons
            gc.price = price
            gc.startDate = startDate
            gc.notes = notes.isEmpty ? nil : notes
            gc.isActive = isActive
        } else {
            let gc = GroupClass(
                name: trimmedName,
                students: selectedStudents,
                totalLessons: totalLessons,
                price: price,
                startDate: startDate,
                notes: notes.isEmpty ? nil : notes,
                isActive: isActive
            )
            modelContext.insert(gc)
        }
        dismiss()
    }
}

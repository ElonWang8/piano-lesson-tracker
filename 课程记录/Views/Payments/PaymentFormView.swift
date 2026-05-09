import SwiftUI
import SwiftData

struct PaymentFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let existingPayment: Payment?
    let preselectedStudent: Student?

    @State private var selectedStudent: Student?
    @State private var paymentDate: Date = Date()
    @State private var amount: Double = 0
    @State private var validityStart: Date = Date()
    @State private var validityEnd: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var paymentMethod: PaymentMethod = .wechat
    @State private var lessonCount: Int = 4
    @State private var notes: String = ""

    @Query(sort: \Student.name) private var students: [Student]

    init(existingPayment: Payment? = nil, preselectedStudent: Student? = nil) {
        self.existingPayment = existingPayment
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

                Section("缴费信息") {
                    DatePicker("缴费日期", selection: $paymentDate, displayedComponents: .date)

                    HStack {
                        Text("金额")
                        TextField("0", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("元")
                            .foregroundColor(.secondary)
                    }

                    Stepper("课时数: \(lessonCount)", value: $lessonCount, in: 1...200)

                    Picker("支付方式", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                }

                Section("有效期") {
                    DatePicker("开始", selection: $validityStart, displayedComponents: .date)
                    DatePicker("结束", selection: $validityEnd, displayedComponents: .date)
                }

                Section("备注") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle(existingPayment == nil ? "添加缴费" : "编辑缴费")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(selectedStudent == nil || amount <= 0)
                }
            }
            .onAppear { populateExisting() }
        }
    }

    private func populateExisting() {
        if let payment = existingPayment {
            selectedStudent = payment.student
            paymentDate = payment.date
            amount = payment.amount
            validityStart = payment.validityStart
            validityEnd = payment.validityEnd
            paymentMethod = payment.paymentMethod
            lessonCount = payment.lessonCount
            notes = payment.notes ?? ""
        } else if let student = preselectedStudent {
            selectedStudent = student
        }
    }

    private func save() {
        guard let student = selectedStudent, amount > 0 else { return }

        if let payment = existingPayment {
            payment.student = student
            payment.date = paymentDate
            payment.amount = amount
            payment.validityStart = validityStart
            payment.validityEnd = validityEnd
            payment.paymentMethod = paymentMethod
            payment.lessonCount = lessonCount
            payment.notes = notes.isEmpty ? nil : notes
        } else {
            let payment = Payment(
                student: student,
                date: paymentDate,
                amount: amount,
                validityStart: validityStart,
                validityEnd: validityEnd,
                paymentMethod: paymentMethod,
                lessonCount: lessonCount,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(payment)
        }
        dismiss()
    }
}

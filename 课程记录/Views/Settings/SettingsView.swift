import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Codable DTOs for backup

struct StudentDTO: Codable {
    var id: UUID
    var name: String
    var phone: String?
    var age: Int?
    var grade: String?
    var notes: String?
    var startDate: Date
    var isActive: Bool
}

struct LessonDTO: Codable {
    var id: UUID
    var studentName: String
    var groupClassName: String?
    var date: Date
    var duration: Int
    var content: String?
    var status: String
    var isRescheduled: Bool
}

struct PaymentDTO: Codable {
    var id: UUID
    var studentName: String
    var date: Date
    var amount: Double
    var validityStart: Date
    var validityEnd: Date
    var paymentMethod: String
    var lessonCount: Int
    var notes: String?
}

struct BackupData: Codable {
    var students: [StudentDTO]
    var lessons: [LessonDTO]
    var payments: [PaymentDTO]
}

// MARK: - SettingsView

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allStudents: [Student]
    @Query private var allLessons: [Lesson]
    @Query private var allPayments: [Payment]

    @AppStorage("reminderMinutes") private var reminderMinutes: Int = 30
    @AppStorage("defaultDuration") private var defaultDuration: Int = 45
    @AppStorage("defaultLessonCount") private var defaultLessonCount: Int = 4
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true

    @State private var showingExport = false
    @State private var backupURL: URL?
    @State private var showBackupShare = false
    @State private var showFileImporter = false
    @State private var restoreMessage: String?
    @State private var showRestoreAlert = false

    let reminderOptions: [(Int, String)] = [
        (5, "5分钟前"), (15, "15分钟前"), (30, "30分钟前"),
        (60, "1小时前"), (120, "2小时前"), (1440, "1天前")
    ]
    let durationOptions = [30, 45, 60, 90, 120]

    var body: some View {
        Form {
            Section("默认设置") {
                Picker("默认课时长", selection: $defaultDuration) {
                    ForEach(durationOptions, id: \.self) { d in
                        Text("\(d)分钟").tag(d)
                    }
                }
                Stepper("默认课时数: \(defaultLessonCount)", value: $defaultLessonCount, in: 1...100)
            }

            Section("提醒设置") {
                Toggle("开启上课提醒", isOn: $notificationsEnabled)
                if notificationsEnabled {
                    Picker("提醒时间", selection: $reminderMinutes) {
                        ForEach(reminderOptions, id: \.0) { (minutes, label) in
                            Text(label).tag(minutes)
                        }
                    }
                }
            }

            Section("数据管理") {
                Button {
                    showingExport = true
                } label: {
                    Label("导出课程/缴费 CSV", systemImage: "doc.text")
                }

                Button {
                    performBackup()
                } label: {
                    Label("备份全部数据", systemImage: "externaldrive.badge.timemachine")
                }

                Button {
                    showFileImporter = true
                } label: {
                    Label("恢复备份数据", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Section("关于") {
                LabeledContent("应用名称") { Text("课程记录").foregroundColor(.secondary) }
                LabeledContent("版本") { Text("1.0").foregroundColor(.secondary) }
            }

            Section {
                Text("数据仅存储在本地，建议定期备份。")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .navigationTitle("设置")
        .sheet(isPresented: $showingExport) { ExportView() }
        .sheet(isPresented: $showBackupShare) {
            if let url = backupURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json]) { result in
            handleImport(result)
        }
        .alert("恢复结果", isPresented: $showRestoreAlert) {
            Button("确定") {}
        } message: {
            Text(restoreMessage ?? "")
        }
    }

    // MARK: - Backup

    private func performBackup() {
        let studentDTOs = allStudents.map { s in
            StudentDTO(id: s.id, name: s.name, phone: s.phone, age: s.age,
                       grade: s.grade, notes: s.notes, startDate: s.startDate, isActive: s.isActive)
        }
        let lessonDTOs = allLessons.map { l in
            LessonDTO(id: l.id, studentName: l.student?.name ?? "", groupClassName: l.groupClass?.name,
                      date: l.date, duration: l.duration, content: l.content,
                      status: l.status.rawValue, isRescheduled: l.isRescheduled)
        }
        let paymentDTOs = allPayments.map { p in
            PaymentDTO(id: p.id, studentName: p.student?.name ?? "", date: p.date,
                       amount: p.amount, validityStart: p.validityStart, validityEnd: p.validityEnd,
                       paymentMethod: p.paymentMethod.rawValue, lessonCount: p.lessonCount, notes: p.notes)
        }

        let backup = BackupData(students: studentDTOs, lessons: lessonDTOs, payments: paymentDTOs)

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(backup)

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let filename = "课程记录备份_\(formatter.string(from: Date())).json"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: url)
            backupURL = url
            showBackupShare = true
        } catch {
            restoreMessage = "备份失败: \(error.localizedDescription)"
            showRestoreAlert = true
        }
    }

    // MARK: - Restore

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let backup = try decoder.decode(BackupData.self, from: data)

                var imported = 0
                let nameToStudent = Dictionary(uniqueKeysWithValues: allStudents.map { ($0.name, $0) })

                for dto in backup.lessons {
                    if let student = nameToStudent[dto.studentName] {
                        let lesson = Lesson(student: student, date: dto.date,
                                            duration: dto.duration, content: dto.content,
                                            status: LessonStatus(rawValue: dto.status) ?? .completed,
                                            isRescheduled: dto.isRescheduled)
                        modelContext.insert(lesson)
                        imported += 1
                    }
                }

                for dto in backup.payments {
                    if let student = nameToStudent[dto.studentName] {
                        let payment = Payment(student: student, date: dto.date,
                                              amount: dto.amount,
                                              validityStart: dto.validityStart,
                                              validityEnd: dto.validityEnd,
                                              paymentMethod: PaymentMethod(rawValue: dto.paymentMethod) ?? .wechat,
                                              lessonCount: dto.lessonCount, notes: dto.notes)
                        modelContext.insert(payment)
                        imported += 1
                    }
                }

                restoreMessage = "成功恢复 \(backup.lessons.count) 条课程、\(backup.payments.count) 条缴费记录"
            } catch {
                restoreMessage = "恢复失败: \(error.localizedDescription)"
            }

        case .failure(let error):
            restoreMessage = "读取文件失败: \(error.localizedDescription)"
        }
        showRestoreAlert = true
    }
}

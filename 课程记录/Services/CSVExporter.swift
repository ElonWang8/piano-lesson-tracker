import Foundation

struct CSVExporter {
    static func exportLessons(_ lessons: [Lesson]) -> URL? {
        var csv = "\u{FEFF}学生姓名,日期,时间,时长(分钟),课堂内容,状态,集体课,是否调课\n"

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for lesson in lessons.sorted(by: { $0.date > $1.date }) {
            let studentName = escapeCSV(lesson.student?.name ?? "")
            let date = formatter.string(from: lesson.date)
            let time = timeFormatter.string(from: lesson.date)
            let duration = "\(lesson.duration)"
            let content = escapeCSV(lesson.content ?? "")
            let status = lesson.status.rawValue
            let groupClassName = escapeCSV(lesson.groupClass?.name ?? "")
            let isRescheduled = lesson.isRescheduled ? "是" : "否"

            csv += "\(studentName),\(date),\(time),\(duration),\(content),\(status),\(groupClassName),\(isRescheduled)\n"
        }

        return writeToTempFile(csv, prefix: "lessons")
    }

    static func exportPayments(_ payments: [Payment]) -> URL? {
        var csv = "\u{FEFF}学生姓名,缴费日期,金额(元),有效期开始,有效期结束,课时数,支付方式,备注\n"

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for payment in payments.sorted(by: { $0.date > $1.date }) {
            let studentName = escapeCSV(payment.student?.name ?? "")
            let date = formatter.string(from: payment.date)
            let amount = String(format: "%.0f", payment.amount)
            let validityStart = formatter.string(from: payment.validityStart)
            let validityEnd = formatter.string(from: payment.validityEnd)
            let lessonCount = "\(payment.lessonCount)"
            let method = payment.paymentMethod.rawValue
            let notes = escapeCSV(payment.notes ?? "")

            csv += "\(studentName),\(date),\(amount),\(validityStart),\(validityEnd),\(lessonCount),\(method),\(notes)\n"
        }

        return writeToTempFile(csv, prefix: "payments")
    }

    private static func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    private static func writeToTempFile(_ content: String, prefix: String) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "\(prefix)_\(timestamp).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("CSV export failed: \(error)")
            return nil
        }
    }
}

import UIKit

struct PDFExporter {
    static func exportLessons(_ lessons: [Lesson]) -> URL? {
        let sorted = lessons.sorted { $0.date > $1.date }
        return generatePDF(title: "课程记录", headers: ["学生", "日期", "时间", "时长", "状态"],
                           rows: sorted.map { lesson in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return [
                lesson.student?.name ?? "",
                dateFormatter.string(from: lesson.date),
                timeFormatter.string(from: lesson.date),
                "\(lesson.duration)分钟",
                lesson.status.rawValue
            ]
        }, filename: "lessons")
    }

    static func exportPayments(_ payments: [Payment]) -> URL? {
        let sorted = payments.sorted { $0.date > $1.date }
        return generatePDF(title: "缴费记录", headers: ["学生", "日期", "金额", "课时数", "支付方式"],
                           rows: sorted.map { payment in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return [
                payment.student?.name ?? "",
                formatter.string(from: payment.date),
                "¥\(Int(payment.amount))",
                "\(payment.lessonCount)节",
                payment.paymentMethod.rawValue
            ]
        }, filename: "payments")
    }

    private static func generatePDF(title: String, headers: [String], rows: [[String]], filename: String) -> URL? {
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 40
        let contentWidth = pageWidth - margin * 2

        let colWidths = headers.enumerated().map { index, _ in
            let weights: [CGFloat] = [0.20, 0.22, 0.18, 0.18, 0.22]
            let idx = min(index, weights.count - 1)
            return contentWidth * weights[idx]
        }

        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        let data = renderer.pdfData { ctx in
            var yPosition: CGFloat = margin

            let titleFont = UIFont.boldSystemFont(ofSize: 20)
            let headerFont = UIFont.boldSystemFont(ofSize: 11)
            let rowFont = UIFont.systemFont(ofSize: 10)
            let rowHeight: CGFloat = 22

            ctx.beginPage()

            let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
            (title as NSString).draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 36

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "导出日期: yyyy年M月d日"
            let dateStr = dateFormatter.string(from: Date())
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.gray
            ]
            (dateStr as NSString).draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateAttributes)
            yPosition += 24

            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .backgroundColor: UIColor(white: 0.95, alpha: 1)
            ]
            var xPosition = margin
            for (index, header) in headers.enumerated() {
                let rect = CGRect(x: xPosition, y: yPosition, width: colWidths[index], height: rowHeight)
                UIColor(white: 0.93, alpha: 1).setFill()
                ctx.fill(CGRect(x: xPosition, y: yPosition, width: colWidths[index], height: rowHeight))
                (header as NSString).draw(in: rect.insetBy(dx: 3, dy: 3), withAttributes: headerAttributes)
                xPosition += colWidths[index]
            }
            yPosition += rowHeight

            let rowAttributes: [NSAttributedString.Key: Any] = [.font: rowFont]

            for (rowIndex, row) in rows.enumerated() {
                if yPosition > pageHeight - margin - rowHeight {
                    ctx.beginPage()
                    yPosition = margin
                }

                if rowIndex % 2 == 0 {
                    UIColor(white: 0.97, alpha: 1).setFill()
                    ctx.fill(CGRect(x: margin, y: yPosition, width: contentWidth, height: rowHeight))
                }

                xPosition = margin
                for (colIndex, cell) in row.enumerated() {
                    let rect = CGRect(x: xPosition, y: yPosition, width: colWidths[colIndex], height: rowHeight)
                    (cell as NSString).draw(in: rect.insetBy(dx: 3, dy: 3), withAttributes: rowAttributes)
                    xPosition += colWidths[colIndex]
                }
                yPosition += rowHeight
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(filename)_\(timestamp).pdf")

        do {
            try data.write(to: url)
            return url
        } catch {
            print("PDF export failed: \(error)")
            return nil
        }
    }
}

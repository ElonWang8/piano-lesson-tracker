import SwiftUI
import SwiftData

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var lessons: [Lesson]
    @Query private var payments: [Payment]

    @State private var exportType: ExportType = .lessons
    @State private var format: ExportFormat = .csv
    @State private var dateRange: ExportDateRange = .all

    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            Form {
                Section("导出类型") {
                    Picker("类型", selection: $exportType) {
                        ForEach(ExportType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("日期范围") {
                    Picker("范围", selection: $dateRange) {
                        ForEach(ExportDateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                }

                Section("文件格式") {
                    Picker("格式", selection: $format) {
                        ForEach(ExportFormat.allCases, id: \.self) { fmt in
                            Text(fmt.rawValue).tag(fmt)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button {
                        generateExport()
                    } label: {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                            } else {
                                Label("导出", systemImage: "square.and.arrow.up")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isGenerating)
                }
            }
            .navigationTitle("导出数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private var filteredLessons: [Lesson] {
        lessons.filter { dateRange.contains($0.date) }
            .sorted { $0.date > $1.date }
    }

    private var filteredPayments: [Payment] {
        payments.filter { dateRange.contains($0.date) }
            .sorted { $0.date > $1.date }
    }

    private func generateExport() {
        isGenerating = true

        DispatchQueue.global(qos: .userInitiated).async {
            let url: URL?
            switch (exportType, format) {
            case (.lessons, .csv):
                url = CSVExporter.exportLessons(filteredLessons)
            case (.lessons, .pdf):
                url = PDFExporter.exportLessons(filteredLessons)
            case (.payments, .csv):
                url = CSVExporter.exportPayments(filteredPayments)
            case (.payments, .pdf):
                url = PDFExporter.exportPayments(filteredPayments)
            }

            DispatchQueue.main.async {
                isGenerating = false
                exportURL = url
                if url != nil {
                    showShareSheet = true
                }
            }
        }
    }
}

enum ExportType: String, CaseIterable {
    case lessons = "课程记录"
    case payments = "缴费记录"
}

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case pdf = "PDF"
}

enum ExportDateRange: String, CaseIterable {
    case month = "本月"
    case threeMonths = "近3月"
    case year = "本年"
    case all = "全部"

    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .month:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .threeMonths:
            return date >= (calendar.date(byAdding: .month, value: -3, to: now) ?? now)
        case .year:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .all:
            return true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query private var lessons: [Lesson]
    @Query private var payments: [Payment]
    @Query private var students: [Student]

    @State private var dateRange: StatisticsRange = .all
    @State private var showingExport = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("", selection: $dateRange) {
                    ForEach(StatisticsRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                summaryCards

                MonthlyLessonChart(lessons: filteredLessons)
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                MonthlyIncomeChart(payments: filteredPayments)
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                StudentDistributionChart(lessons: filteredLessons, students: students)
                    .frame(height: 220)
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("统计")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingExport = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingExport) {
            ExportView()
        }
    }

    private var filteredLessons: [Lesson] {
        lessons.filter { lesson in
            dateRange.contains(lesson.date) && lesson.status == .completed
        }
    }

    private var filteredPayments: [Payment] {
        payments.filter { dateRange.contains($0.date) }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "总课时",
                value: "\(filteredLessons.count)",
                systemImage: "calendar.badge.checkmark",
                color: .blue
            )
            StatCard(
                title: "总收入",
                value: "¥\(Int(filteredPayments.reduce(0) { $0 + $1.amount }))",
                systemImage: "yensign.circle",
                color: .green
            )
            StatCard(
                title: "活跃学生",
                value: "\(students.filter { $0.isActive }.count)",
                systemImage: "person.2",
                color: .orange
            )
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

enum StatisticsRange: String, CaseIterable {
    case month = "本月"
    case threeMonths = "近3月"
    case sixMonths = "近6月"
    case year = "本年"
    case all = "全部"

    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .month:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .threeMonths:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return date >= threeMonthsAgo
        case .sixMonths:
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) ?? now
            return date >= sixMonthsAgo
        case .year:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .all:
            return true
        }
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
}

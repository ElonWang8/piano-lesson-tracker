import SwiftUI
import Charts

struct MonthlyLessonChart: View {
    let lessons: [Lesson]

    private var monthlyData: [(month: String, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: lessons) { lesson in
            calendar.dateComponents([.year, .month], from: lesson.date)
        }
        let sorted = grouped.keys.sorted {
            let d1 = calendar.date(from: $0) ?? Date()
            let d2 = calendar.date(from: $1) ?? Date()
            return d1 < d2
        }
        return sorted.compactMap { components in
            guard let date = calendar.date(from: components),
                  let range = calendar.range(of: .day, in: .month, for: date) else { return nil }
            let monthName = "\(calendar.component(.month, from: date))月"
            return (monthName, grouped[components]?.count ?? 0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("每月课时")
                .font(.headline)

            if monthlyData.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart {
                    ForEach(monthlyData, id: \.month) { item in
                        BarMark(
                            x: .value("月份", item.month),
                            y: .value("课时", item.count)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(4)
                    }
                }
            }
        }
    }
}

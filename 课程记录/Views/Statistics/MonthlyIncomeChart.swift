import SwiftUI
import Charts

struct MonthlyIncomeChart: View {
    let payments: [Payment]

    private var monthlyData: [(month: String, income: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: payments) { payment in
            calendar.dateComponents([.year, .month], from: payment.date)
        }
        let sorted = grouped.keys.sorted {
            let d1 = calendar.date(from: $0) ?? Date()
            let d2 = calendar.date(from: $1) ?? Date()
            return d1 < d2
        }
        return sorted.compactMap { components in
            guard let date = calendar.date(from: components) else { return nil }
            let monthName = "\(calendar.component(.month, from: date))月"
            let total = grouped[components]?.reduce(0) { $0 + $1.amount } ?? 0
            return (monthName, total)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("每月收入")
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
                            y: .value("收入", item.income)
                        )
                        .foregroundStyle(Color.green.gradient)
                        .cornerRadius(4)
                    }
                }
            }
        }
    }
}

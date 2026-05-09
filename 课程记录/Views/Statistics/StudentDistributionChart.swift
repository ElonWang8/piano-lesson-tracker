import SwiftUI
import Charts

struct StudentDistributionChart: View {
    let lessons: [Lesson]
    let students: [Student]

    private var studentData: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: lessons) { $0.student?.name ?? "未知" }
        let mapped: [(name: String, count: Int)] = grouped.map { ($0.key, $0.value.count) }
        return mapped
            .sorted { $0.count > $1.count }
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("学生课时分布")
                .font(.headline)

            if studentData.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart {
                    ForEach(Array(studentData.enumerated()), id: \.offset) { index, item in
                        SectorMark(
                            angle: .value("课时", item.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 1
                        )
                        .foregroundStyle(by: .value("学生", item.name))
                    }
                }
            }
        }
    }
}

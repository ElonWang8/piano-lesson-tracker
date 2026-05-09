import SwiftUI

struct GroupClassRowView: View {
    let groupClass: GroupClass

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(groupClass.name)
                    .font(.body.bold())
                Text("\(groupClass.students?.count ?? 0)名学生")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(groupClass.remainingLessons)")
                    .font(.title3.bold())
                    .foregroundColor(remainingColor)
                Text("剩余/\(groupClass.totalLessons)课时")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var remainingColor: Color {
        let r = groupClass.remainingLessons
        if r > 10 { return .green }
        if r >= 3 { return .orange }
        return .red
    }
}

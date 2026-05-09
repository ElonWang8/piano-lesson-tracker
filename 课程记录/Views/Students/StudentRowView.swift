import SwiftUI

struct StudentRowView: View {
    let student: Student

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(baseColor.opacity(0.2))
                    .frame(width: 38, height: 38)

                Text(String(student.name.prefix(1)))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(baseColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(student.name)
                    .font(.body.weight(.medium))

                if let grade = student.grade {
                    Text(grade)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(student.remainingLessons)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(remainingColor)
                Text("课时")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var baseColor: Color {
        colorForStudent(student.name)
    }

    private var remainingColor: Color {
        let r = student.remainingLessons
        if r > 10 { return .green }
        if r >= 3 { return .orange }
        return .red
    }
}

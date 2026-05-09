import SwiftUI

struct LessonRowView: View {
    let lesson: Lesson

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(lesson.date.timeString())
                    .font(.subheadline.bold())
                Text(lesson.date.dateString())
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(lesson.student?.name ?? "未知")
                        .font(.subheadline)

                    if lesson.isRescheduled {
                        Text("调课")
                            .font(.system(size: 9))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(3)
                    }

                    if let gc = lesson.groupClass {
                        Text(gc.name)
                            .font(.system(size: 9))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(3)
                    }
                }

                HStack(spacing: 8) {
                    Text("\(lesson.duration)分钟")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let content = lesson.content, !content.isEmpty {
                        Text(content)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            StatusBadgeView(status: lesson.status)
        }
        .padding(.vertical, 6)
    }
}

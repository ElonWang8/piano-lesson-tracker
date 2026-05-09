import SwiftUI

let studentColorPalette: [Color] = [
    Color(red: 1.0, green: 0.55, blue: 0.55),   // 珊瑚红
    Color(red: 0.45, green: 0.70, blue: 0.95),   // 天空蓝
    Color(red: 0.50, green: 0.80, blue: 0.65),   // 薄荷绿
    Color(red: 0.65, green: 0.55, blue: 0.90),   // 薰衣草紫
    Color(red: 1.0, green: 0.65, blue: 0.35),    // 蜜橙
    Color(red: 0.95, green: 0.55, blue: 0.70),   // 桃粉
    Color(red: 0.40, green: 0.65, blue: 0.85),   // 湖水蓝
    Color(red: 0.95, green: 0.75, blue: 0.40),   // 暖黄
]

func colorForStudent(_ name: String) -> Color {
    let hash = abs(name.hashValue)
    return studentColorPalette[hash % studentColorPalette.count]
}

struct ScheduleSlotCell: View {
    let occurrence: ScheduleOccurrence
    let onCheckIn: () -> Void
    let onLongPress: () -> Void

    @State private var showCheckedAnimation = false

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                if occurrence.isRescheduled {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                }

                Text(occurrence.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)

                if occurrence.scheduleType == .group {
                    Text("×\(occurrence.groupClass?.students?.count ?? 0)")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.7))
                }

                Text("\(occurrence.duration)′")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.leading, 6)

            Spacer(minLength: 2)

            if occurrence.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(.trailing, 4)
            } else if occurrence.isCheckedIn {
                Button {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    showCheckedAnimation = true
                    onCheckIn()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showCheckedAnimation = false
                    }
                } label: {
                    Image(systemName: "circle")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.trailing, 4)
            } else {
                Button {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    showCheckedAnimation = true
                    onCheckIn()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showCheckedAnimation = false
                    }
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.trailing, 4)
            }
        }
        .frame(height: 28)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: occurrence.isRescheduled ? 1.5 : 0.5)
                )
        )
        .overlay(
            showCheckedAnimation
                ? RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.4))
                : nil
        )
        .animation(.easeInOut(duration: 0.3), value: showCheckedAnimation)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onLongPress()
            } label: {
                Label("临时调课", systemImage: "arrow.triangle.swap")
            }
        }
    }

    private var baseColor: Color {
        let displayName = occurrence.displayName
        return colorForStudent(displayName)
    }

    private var backgroundColor: Color {
        if occurrence.isCompleted {
            return Color.green.opacity(0.20)
        }
        if occurrence.isRescheduled {
            return Color.orange.opacity(0.20)
        }
        return baseColor.opacity(0.22)
    }

    private var borderColor: Color {
        if occurrence.isCompleted {
            return Color.green.opacity(0.5)
        }
        if occurrence.isRescheduled {
            return Color.orange.opacity(0.8)
        }
        return baseColor.opacity(0.5)
    }
}

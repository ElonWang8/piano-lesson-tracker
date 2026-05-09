import SwiftUI

struct StatusBadgeView: View {
    let status: LessonStatus

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }

    private var backgroundColor: Color {
        switch status {
        case .scheduled: return .blue
        case .completed: return .green
        case .cancelled: return .gray
        }
    }
}

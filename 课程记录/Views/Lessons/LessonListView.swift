import SwiftUI
import SwiftData

struct LessonListView: View {
    @Query(sort: \Lesson.date, order: .reverse) private var lessons: [Lesson]
    @Query(sort: \Student.name) private var students: [Student]
    @State private var selectedStudentFilter: Student? = nil

    private var filteredLessons: [Lesson] {
        guard let filterStudent = selectedStudentFilter else { return lessons }
        return lessons.filter { $0.student?.id == filterStudent.id }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "全部", isSelected: selectedStudentFilter == nil) {
                        selectedStudentFilter = nil
                    }
                    ForEach(students.filter { $0.isActive }) { student in
                        FilterChip(label: student.name, isSelected: selectedStudentFilter?.id == student.id) {
                            selectedStudentFilter = student
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            if filteredLessons.isEmpty {
                EmptyStateView(systemImage: "calendar", title: "暂无课程记录")
            } else {
                List {
                    ForEach(filteredLessons) { lesson in
                        NavigationLink {
                            LessonDetailView(lesson: lesson)
                        } label: {
                            LessonRowView(lesson: lesson)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if let ctx = lesson.modelContext {
                                    ctx.delete(lesson)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

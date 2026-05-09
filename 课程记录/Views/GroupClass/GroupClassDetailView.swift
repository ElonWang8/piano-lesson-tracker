import SwiftUI
import SwiftData

struct GroupClassDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let groupClass: GroupClass

    @State private var selectedSegment = 0
    @State private var showingEditForm = false
    @State private var showingCheckIn = false

    private let segments = ["学生", "课程记录"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)

                    Text(groupClass.name)
                        .font(.title2.bold())

                    if let notes = groupClass.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                remainingCard

                Picker("", selection: $selectedSegment) {
                    ForEach(0..<segments.count, id: \.self) { idx in
                        Text(segments[idx]).tag(idx)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedSegment {
                case 0: studentsSection
                case 1: lessonsSection
                default: EmptyView()
                }
            }
        }
        .navigationTitle(groupClass.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditForm = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            GroupClassFormView(existingGroupClass: groupClass)
        }
    }

    private var remainingCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("剩余课时")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(groupClass.remainingLessons)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(remainingColor)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Text("总课时")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(groupClass.totalLessons)")
                        .font(.caption.bold())
                }
                HStack {
                    Text("已上")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(groupClass.completedLessons)")
                        .font(.caption.bold())
                }

                ProgressView(value: Double(groupClass.completedLessons), total: Double(groupClass.totalLessons))
                    .tint(remainingColor)
                    .frame(width: 80)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var remainingColor: Color {
        let r = groupClass.remainingLessons
        if r > 10 { return .green }
        if r >= 3 { return .orange }
        return .red
    }

    private var studentsSection: some View {
        let students = groupClass.students ?? []

        return VStack(spacing: 0) {
            if students.isEmpty {
                EmptyStateView(systemImage: "person.slash", title: "暂无学生")
                    .padding(.top, 40)
            } else {
                ForEach(students) { student in
                    NavigationLink {
                        StudentDetailView(student: student)
                    } label: {
                        StudentRowView(student: student)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    Divider().padding(.leading)
                }
            }
        }
    }

    private var lessonsSection: some View {
        let allLessons = studentLessons.sorted { $0.date > $1.date }

        return VStack(spacing: 0) {
            if allLessons.isEmpty {
                EmptyStateView(systemImage: "calendar", title: "暂无课程记录")
                    .padding(.top, 40)
            } else {
                ForEach(allLessons.prefix(50)) { lesson in
                    HStack(spacing: 12) {
                        VStack(spacing: 2) {
                            Text(lesson.date.timeString())
                                .font(.caption.bold())
                            Text(lesson.date.dateString())
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 44)

                        VStack(alignment: .leading, spacing: 2) {
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
                        }

                        Spacer()

                        StatusBadgeView(status: lesson.status)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal)

                    Divider().padding(.leading)
                }
            }
        }
    }

    private var studentLessons: [Lesson] {
        let students = groupClass.students ?? []
        var allLessons: [Lesson] = []
        for student in students {
            let groupLessons = (student.lessons ?? []).filter { $0.groupClass?.id == groupClass.id }
            allLessons.append(contentsOf: groupLessons)
        }
        return allLessons
    }
}

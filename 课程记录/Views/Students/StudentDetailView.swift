import SwiftUI
import SwiftData

struct StudentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let student: Student

    @State private var selectedSegment = 0
    @State private var lessonSubSegment = 0
    @State private var selectedLessonIDs: Set<UUID> = []
    @State private var showingEditForm = false
    @State private var showingLessonForm = false
    @State private var showingPaymentForm = false
    @State private var groupClassToShow: GroupClass?
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    private let segments = ["课程记录", "缴费记录", "集体课"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                studentInfoCard

                remainingLessonsCard

                Picker("", selection: $selectedSegment) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Text(segments[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedSegment {
                case 0: lessonsSection
                case 1: paymentsSection
                case 2: groupClassesSection
                default: EmptyView()
                }
            }
        }
        .navigationTitle(student.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    if selectedSegment == 0 {
                        Button {
                            exportStudentLessons()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    Menu {
                        if selectedSegment == 0 {
                            Button {
                                if selectedLessonIDs.isEmpty {
                                    selectedLessonIDs = Set(studentLessons.map(\.id))
                                } else {
                                    selectedLessonIDs = []
                                }
                            } label: {
                                Label(selectedLessonIDs.isEmpty ? "选择删除" : "取消选择", systemImage: "checkmark.circle")
                            }
                        }
                        Button {
                            showingLessonForm = true
                        } label: {
                            Label("添加课程", systemImage: "calendar.badge.plus")
                        }
                        Button {
                            showingPaymentForm = true
                        } label: {
                            Label("添加缴费", systemImage: "yensign.circle")
                        }
                        Divider()
                        Button {
                            showingEditForm = true
                        } label: {
                            Label("编辑信息", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            StudentFormView(existingStudent: student)
        }
        .sheet(isPresented: $showingLessonForm) {
            LessonFormView(preselectedStudent: student)
        }
        .sheet(isPresented: $showingPaymentForm) {
            PaymentFormView(preselectedStudent: student)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private var studentInfoCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(colorForStudent(student.name).opacity(0.15))
                    .frame(width: 60, height: 60)

                Text(String(student.name.prefix(1)))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(colorForStudent(student.name))
            }

            Text(student.name)
                .font(.title2.bold())

            if let grade = student.grade {
                Text(grade)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
            }

            HStack(spacing: 20) {
                if let phone = student.phone {
                    Label(phone, systemImage: "phone")
                        .font(.caption)
                }
                if let age = student.age {
                    Label("\(age)岁", systemImage: "figure.child")
                        .font(.caption)
                }
            }
            .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Circle()
                    .fill(student.isActive ? Color.green : Color.gray)
                    .frame(width: 6, height: 6)
                Text(student.isActive ? "在读" : "已停课")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("·")
                    .foregroundColor(.secondary)
                Text("学琴自 \(student.startDate.dateString())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private var remainingLessonsCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("剩余课时")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(student.remainingLessons)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(remainingColor)
                    Text("节")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("已购 \(student.purchasedLessonCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        Text("已上 \(student.completedLessonCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 6)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: student.purchasedLessonCount > 0
                        ? CGFloat(student.completedLessonCount) / CGFloat(student.purchasedLessonCount)
                        : 0)
                    .stroke(remainingColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: student.completedLessonCount)

                VStack(spacing: 0) {
                    Text("\(student.remainingLessons)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(remainingColor)
                    Text("剩余")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
        .padding(.horizontal)
    }

    private var remainingColor: Color {
        let remaining = student.remainingLessons
        if remaining > 10 { return .green }
        if remaining >= 3 { return .orange }
        return .red
    }

    private var studentLessons: [Lesson] {
        (student.lessons ?? []).sorted { $0.date > $1.date }
    }

    private var completedLessons: [Lesson] {
        studentLessons.filter { $0.status == .completed }
    }

    private var scheduledLessons: [Lesson] {
        studentLessons.filter { $0.status == .scheduled }
    }

    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if studentLessons.isEmpty {
                EmptyStateView(
                    systemImage: "calendar.badge.plus",
                    title: "暂无课程记录",
                    subtitle: "点击右上角菜单添加课程"
                )
                .padding(.top, 40)
            } else {
                Picker("", selection: $lessonSubSegment) {
                    Text("已上课").tag(0)
                    Text("未上课").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                let lessons = lessonSubSegment == 0 ? completedLessons : scheduledLessons

                if lessons.isEmpty {
                    EmptyStateView(
                        systemImage: lessonSubSegment == 0 ? "checkmark.circle" : "clock",
                        title: lessonSubSegment == 0 ? "暂无已完成课程" : "暂无待上课程",
                        subtitle: nil
                    )
                    .padding(.top, 30)
                } else {
                    ForEach(lessons.prefix(100)) { lesson in
                        HStack(spacing: 0) {
                            if !selectedLessonIDs.isEmpty {
                                Button {
                                    if selectedLessonIDs.contains(lesson.id) {
                                        selectedLessonIDs.remove(lesson.id)
                                    } else {
                                        selectedLessonIDs.insert(lesson.id)
                                    }
                                } label: {
                                    Image(systemName: selectedLessonIDs.contains(lesson.id)
                                        ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                                .padding(.trailing, 8)
                            }

                            NavigationLink {
                                LessonDetailView(lesson: lesson)
                            } label: {
                                lessonRow(lesson)
                            }
                            .buttonStyle(.plain)

                            if lessonSubSegment == 1 {
                                Spacer()
                                Button {
                                    lesson.status = .completed
                                    let g = UINotificationFeedbackGenerator()
                                    g.notificationOccurred(.success)
                                } label: {
                                    Text("签到")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundColor(.green)
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(lesson)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }

                        Divider().padding(.leading, 44)
                    }
                    .padding(.horizontal)

                    if !selectedLessonIDs.isEmpty {
                        Button(role: .destructive) {
                            for id in selectedLessonIDs {
                                if let lesson = lessons.first(where: { $0.id == id }) {
                                    modelContext.delete(lesson)
                                }
                            }
                            selectedLessonIDs = []
                        } label: {
                            Label("删除选中 (\(selectedLessonIDs.count))", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .padding()
                    }
                }
            }
        }
    }

    private func lessonRow(_ lesson: Lesson) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(lesson.date.timeString())
                    .font(.caption.bold())
                Text(lesson.date.dateString())
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(lesson.duration)分钟")
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

                if let content = lesson.content, !content.isEmpty {
                    Text(content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            StatusBadgeView(status: lesson.status)
        }
        .padding(.vertical, 8)
    }

    private var paymentsSection: some View {
        let studentPayments = (student.payments ?? [])
            .sorted { $0.date > $1.date }

        return VStack(alignment: .leading, spacing: 0) {
            if studentPayments.isEmpty {
                EmptyStateView(
                    systemImage: "yensign.circle",
                    title: "暂无缴费记录",
                    subtitle: "点击右上角菜单添加缴费"
                )
                .padding(.top, 40)
            } else {
                ForEach(studentPayments) { payment in
                    PaymentRowView(payment: payment)
                        .padding(.horizontal)
                    Divider().padding(.leading)
                }
            }
        }
    }

    private var groupClassesSection: some View {
        let groups = student.groupClasses ?? []

        return VStack(alignment: .leading, spacing: 0) {
            if groups.isEmpty {
                EmptyStateView(
                    systemImage: "person.3",
                    title: "未加入集体课",
                    subtitle: "该学生还没有加入任何集体课"
                )
                .padding(.top, 40)
            } else {
                ForEach(groups) { gc in
                    NavigationLink {
                        GroupClassDetailView(groupClass: gc)
                    } label: {
                        GroupClassRowView(groupClass: gc)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    Divider().padding(.leading)
                }
            }
        }
    }

    private func checkInToday() {
        let today = Date()
        let calendar = Calendar.current

        let alreadyChecked = (student.lessons ?? []).contains { lesson in
            calendar.isDate(lesson.date, inSameDayAs: today) && lesson.status == .completed
        }

        guard !alreadyChecked else { return }

        let lesson = Lesson(
            student: student,
            date: today,
            duration: 45,
            status: .completed
        )
        modelContext.insert(lesson)

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func exportStudentLessons() {
        let lessons = (student.lessons ?? []).sorted { $0.date > $1.date }
        guard !lessons.isEmpty else { return }
        if let url = CSVExporter.exportLessons(lessons) {
            exportURL = url
            showShareSheet = true
        }
    }
}

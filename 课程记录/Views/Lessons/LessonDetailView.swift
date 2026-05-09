import SwiftUI

struct LessonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let lesson: Lesson
    @State private var showingEditForm = false

    var body: some View {
        List {
            Section("课程信息") {
                LabeledContent("学生") {
                    Text(lesson.student?.name ?? "未知")
                }
                if let gc = lesson.groupClass {
                    LabeledContent("集体课") {
                        Text(gc.name)
                    }
                }
                LabeledContent("日期") {
                    Text(lesson.date.fullDateString())
                }
                LabeledContent("时间") {
                    Text(lesson.date.timeString())
                }
                LabeledContent("时长") {
                    Text("\(lesson.duration)分钟")
                }
                LabeledContent("状态") {
                    StatusBadgeView(status: lesson.status)
                }
                if lesson.isRescheduled {
                    LabeledContent("调课") {
                        Text("由临时调课产生")
                            .foregroundColor(.orange)
                    }
                }
            }

            if let content = lesson.content, !content.isEmpty {
                Section("课堂内容") {
                    Text(content)
                }
            }

            Section {
                Button(role: .destructive) {
                    modelContext.delete(lesson)
                } label: {
                    Label("删除记录", systemImage: "trash")
                }
            }
        }
        .navigationTitle("课程详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("编辑") {
                    showingEditForm = true
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            LessonFormView(existingLesson: lesson)
        }
    }
}

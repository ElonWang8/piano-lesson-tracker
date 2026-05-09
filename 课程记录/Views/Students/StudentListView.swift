import SwiftUI
import SwiftData

struct StudentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Student.name) private var students: [Student]
    @State private var searchText = ""
    @State private var showingForm = false
    @State private var editingStudent: Student?

    var filteredStudents: [Student] {
        if searchText.isEmpty {
            return students
        }
        return students.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.phone ?? "").contains(searchText)
        }
    }

    var body: some View {
        Group {
            if students.isEmpty {
                EmptyStateView(
                    systemImage: "person.2.slash",
                    title: "还没有学生",
                    subtitle: "点击右上角 + 添加第一个学生"
                )
            } else {
                List {
                    ForEach(filteredStudents) { student in
                        NavigationLink {
                            StudentDetailView(student: student)
                        } label: {
                            StudentRowView(student: student)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteStudent(student)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "搜索学生姓名或手机号")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingStudent = nil
                    showingForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            StudentFormView(existingStudent: editingStudent)
        }
    }

    private func deleteStudent(_ student: Student) {
        modelContext.delete(student)
    }
}

import SwiftUI
import SwiftData

struct GroupClassListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GroupClass.name) private var groupClasses: [GroupClass]
    @State private var showingForm = false
    @State private var editingGroupClass: GroupClass?

    var body: some View {
        Group {
            if groupClasses.isEmpty {
                EmptyStateView(
                    systemImage: "person.3",
                    title: "还没有集体课",
                    subtitle: "点击右上角 + 创建集体课"
                )
            } else {
                List {
                    ForEach(groupClasses) { gc in
                        NavigationLink {
                            GroupClassDetailView(groupClass: gc)
                        } label: {
                            GroupClassRowView(groupClass: gc)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(gc)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingGroupClass = nil
                    showingForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            GroupClassFormView(existingGroupClass: editingGroupClass)
        }
    }
}

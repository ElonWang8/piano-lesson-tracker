import SwiftUI
import SwiftData

struct PaymentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Payment.date, order: .reverse) private var payments: [Payment]
    @State private var showingForm = false

    var body: some View {
        Group {
            if payments.isEmpty {
                EmptyStateView(
                    systemImage: "yensign.circle",
                    title: "暂无缴费记录"
                )
            } else {
                List {
                    let grouped = Dictionary(grouping: payments) { $0.student?.name ?? "未知" }
                    ForEach(grouped.keys.sorted(), id: \.self) { studentName in
                        Section(studentName) {
                            ForEach(grouped[studentName] ?? []) { payment in
                                PaymentRowView(payment: payment)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            modelContext.delete(payment)
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
        .navigationTitle("缴费记录")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            PaymentFormView()
        }
    }
}

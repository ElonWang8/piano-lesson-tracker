import SwiftUI

struct LessonContainerView: View {
    @State private var viewMode: LessonViewMode = .calendar
    @State private var showingForm = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $viewMode) {
                ForEach(LessonViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch viewMode {
            case .calendar:
                LessonCalendarView()
            case .list:
                LessonListView()
            }
        }
        .navigationTitle("课程记录")
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
            LessonFormView()
        }
    }
}

enum LessonViewMode: String, CaseIterable {
    case calendar = "日历"
    case list = "列表"
}

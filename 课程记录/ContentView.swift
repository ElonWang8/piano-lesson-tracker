import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ClassScheduleView()
            }
            .tabItem {
                Label("课程表", systemImage: "tablecells.fill")
            }
            .tag(0)

            NavigationStack {
                StudentTabView()
            }
            .tabItem {
                Label("学生", systemImage: "person.2.fill")
            }
            .tag(1)

            NavigationStack {
                LessonContainerView()
            }
            .tabItem {
                Label("课程", systemImage: "calendar")
            }
            .tag(2)

            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar.fill")
            }
            .tag(3)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
    }
}

struct StudentTabView: View {
    @State private var segment: StudentTabSegment = .individual

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $segment) {
                ForEach(StudentTabSegment.allCases, id: \.self) { seg in
                    Text(seg.rawValue).tag(seg)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch segment {
            case .individual:
                StudentListView()
            case .group:
                GroupClassListView()
            }
        }
        .navigationTitle("学生管理")
    }
}

enum StudentTabSegment: String, CaseIterable {
    case individual = "一对一学生"
    case group = "集体课"
}

#Preview {
    ContentView()
}

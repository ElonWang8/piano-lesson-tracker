import SwiftUI
import SwiftData

@main
struct 课程记录App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Student.self,
            Lesson.self,
            Payment.self,
            ScheduleSlot.self,
            ScheduleException.self,
            GroupClass.self
        ])
    }
}

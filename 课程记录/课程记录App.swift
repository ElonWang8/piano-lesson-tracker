import SwiftUI
import SwiftData

@main
struct 课程记录App: App {
    var container: ModelContainer

    init() {
        let schema = Schema([Student.self, Lesson.self, Payment.self,
                             ScheduleSlot.self, ScheduleException.self, GroupClass.self])
        do {
            let config = ModelConfiguration()
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            // 数据库迁移失败，删除旧数据重建
            let storeURL = URL.documentsDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            let config = ModelConfiguration()
            container = try! ModelContainer(for: schema, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

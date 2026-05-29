import Foundation
import SwiftData

enum AppLaunchOptions {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    static var shouldSeedSampleData: Bool {
        ProcessInfo.processInfo.arguments.contains("-seed-sample-data")
    }
}

@MainActor
enum ModelContainerFactory {
    static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            Diary.self,
            EntryDef.self,
            Entry.self,
            FieldDef.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: AppLaunchOptions.isUITesting
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            if AppLaunchOptions.shouldSeedSampleData {
                seedLegacySampleData(in: container.mainContext)
            }
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    static func seedLegacySampleData(in context: ModelContext) {
        let tracker = Diary.sampleData()
        tracker.name = "Mood Tracker"
        context.insert(tracker)
        do {
            try context.save()
        } catch {
            fatalError("Could not seed sample data: \(error)")
        }
    }
}

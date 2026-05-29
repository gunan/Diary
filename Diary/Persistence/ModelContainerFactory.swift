import Foundation
import SwiftData

enum AppLaunchOptions {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    static var shouldSeedSampleData: Bool {
        isUITesting && ProcessInfo.processInfo.arguments.contains("-seed-sample-data")
    }

    static var shouldResetStore: Bool {
        isUITesting && ProcessInfo.processInfo.arguments.contains("-reset-store")
    }

    static var shouldUseInMemoryStore: Bool {
        isUITesting || shouldResetStore
    }
}

@MainActor
enum ModelContainerFactory {
    typealias LegacyImporter = @MainActor (ModelContext) throws -> Void

    private static var schema: Schema {
        Schema([
            Diary.self,
            EntryDef.self,
            Entry.self,
            FieldDef.self,
            TrackerModel.self,
            FieldDefinitionModel.self,
            EntryModel.self,
            EntryValueModel.self,
            FieldSnapshotModel.self,
        ])
    }

    static func makeModelContainer(
        isStoredInMemoryOnly: Bool? = nil,
        importLegacyData: LegacyImporter = LegacyDiaryImporter.importIfNeeded
    ) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly ?? AppLaunchOptions.shouldUseInMemoryStore
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            if AppLaunchOptions.shouldSeedSampleData {
                seedLegacySampleData(in: container.mainContext)
            }
            do {
                try importLegacyData(container.mainContext)
            } catch {
                AppLog.persistenceError("Could not import legacy diaries: \(error.localizedDescription)")
            }
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    static func makeTestingContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(for: schema, configurations: [configuration])
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

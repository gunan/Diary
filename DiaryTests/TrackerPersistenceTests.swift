import Foundation
import SwiftData
import Testing
@testable import Diary

@MainActor
struct TrackerPersistenceTests {
    @Test func persistsTrackerWithStableFieldID() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let context = container.mainContext
        let fieldID = UUID()
        let tracker = TrackerModel(name: "Mood Tracker")
        tracker.fields.append(FieldDefinitionModel(
            fieldID: fieldID,
            name: "Energy",
            typeRaw: TrackerFieldType.number.rawValue,
            sortOrder: 0
        ))

        context.insert(tracker)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<TrackerModel>())
        #expect(fetched.count == 1)
        #expect(fetched[0].fields[0].fieldID == fieldID)
    }
}

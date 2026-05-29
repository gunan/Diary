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
        let fields = fetched[0].fields.sorted { $0.sortOrder < $1.sortOrder }
        #expect(fetched.count == 1)
        #expect(fields[0].fieldID == fieldID)
    }

    @Test func deletingTrackerCascadesToFieldsAndEntries() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let context = container.mainContext
        let tracker = TrackerModel(
            name: "Mood Tracker",
            fields: [
                FieldDefinitionModel(
                    name: "Mood",
                    typeRaw: TrackerFieldType.text.rawValue,
                    sortOrder: 0
                ),
            ],
            entries: [
                EntryModel(
                    values: [
                        EntryValueModel(
                            fieldID: UUID(),
                            typeRaw: TrackerFieldType.text.rawValue,
                            textValue: "Steady"
                        ),
                    ],
                    snapshots: [
                        FieldSnapshotModel(
                            fieldID: UUID(),
                            name: "Mood",
                            typeRaw: TrackerFieldType.text.rawValue,
                            sortOrder: 0
                        ),
                    ]
                ),
            ]
        )

        context.insert(tracker)
        try context.save()
        context.delete(tracker)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<TrackerModel>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<FieldDefinitionModel>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<EntryModel>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<EntryValueModel>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<FieldSnapshotModel>()).isEmpty)
    }

    @Test func roundTripsFieldDefinitionOptionsBoundsAndSortOrder() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let context = container.mainContext
        let tracker = TrackerModel(
            name: "Health Tracker",
            fields: [
                FieldDefinitionModel(
                    name: "Intensity",
                    typeRaw: TrackerFieldType.number.rawValue,
                    sortOrder: 2,
                    minValue: 1,
                    maxValue: 10
                ),
                FieldDefinitionModel(
                    name: "Tag",
                    typeRaw: TrackerFieldType.selector.rawValue,
                    sortOrder: 1,
                    options: ["work", "personal", "medicine"]
                ),
            ]
        )

        context.insert(tracker)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<TrackerModel>())
        let fields = fetched[0].fields.sorted { $0.sortOrder < $1.sortOrder }
        #expect(fields.map(\.name) == ["Tag", "Intensity"])
        #expect(fields[0].options == ["work", "personal", "medicine"])
        #expect(fields[1].minValue == 1)
        #expect(fields[1].maxValue == 10)
    }

    @Test func roundTripsEntrySnapshotsAndValueTypes() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let context = container.mainContext
        let textFieldID = UUID()
        let numberFieldID = UUID()
        let dateFieldID = UUID()
        let timeFieldID = UUID()
        let selectorFieldID = UUID()
        let unavailableFieldID = UUID()
        let date = Date(timeIntervalSince1970: 1_718_755_200)
        let tracker = TrackerModel(
            name: "Daily Tracker",
            entries: [
                EntryModel(
                    createdAt: Date(timeIntervalSince1970: 1_718_841_600),
                    values: [
                        EntryValueModel(
                            fieldID: textFieldID,
                            typeRaw: TrackerFieldType.text.rawValue,
                            textValue: "Clear"
                        ),
                        EntryValueModel(
                            fieldID: numberFieldID,
                            typeRaw: TrackerFieldType.number.rawValue,
                            numberValue: 8.5
                        ),
                        EntryValueModel(
                            fieldID: dateFieldID,
                            typeRaw: TrackerFieldType.date.rawValue,
                            dateValue: date
                        ),
                        EntryValueModel(
                            fieldID: timeFieldID,
                            typeRaw: TrackerFieldType.time.rawValue,
                            timeHour: 6,
                            timeMinute: 30
                        ),
                        EntryValueModel(
                            fieldID: selectorFieldID,
                            typeRaw: TrackerFieldType.selector.rawValue,
                            textValue: "work"
                        ),
                        EntryValueModel(
                            fieldID: unavailableFieldID,
                            typeRaw: TrackerFieldType.text.rawValue,
                            unavailableReason: "Skipped"
                        ),
                    ],
                    snapshots: [
                        FieldSnapshotModel(
                            fieldID: numberFieldID,
                            name: "Energy",
                            typeRaw: TrackerFieldType.number.rawValue,
                            sortOrder: 1
                        ),
                        FieldSnapshotModel(
                            fieldID: textFieldID,
                            name: "Mood",
                            typeRaw: TrackerFieldType.text.rawValue,
                            sortOrder: 0
                        ),
                    ]
                ),
            ]
        )

        context.insert(tracker)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<TrackerModel>())
        let entry = try #require(fetched[0].entries.first)
        let snapshots = entry.snapshots.sorted { $0.sortOrder < $1.sortOrder }
        let valuesByFieldID = Dictionary(uniqueKeysWithValues: entry.values.map { ($0.fieldID, $0) })

        #expect(snapshots.map(\.name) == ["Mood", "Energy"])
        #expect(valuesByFieldID[textFieldID]?.textValue == "Clear")
        #expect(valuesByFieldID[numberFieldID]?.numberValue == 8.5)
        #expect(valuesByFieldID[dateFieldID]?.dateValue == date)
        #expect(valuesByFieldID[timeFieldID]?.timeHour == 6)
        #expect(valuesByFieldID[timeFieldID]?.timeMinute == 30)
        #expect(valuesByFieldID[selectorFieldID]?.textValue == "work")
        #expect(valuesByFieldID[unavailableFieldID]?.unavailableReason == "Skipped")
    }

    @Test func sharedSchemaStoresLegacyAndV2RowsTogether() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let context = container.mainContext

        context.insert(Diary.sampleData())
        context.insert(TrackerModel(name: "Mood Tracker"))
        try context.save()

        let legacyRows = try context.fetch(FetchDescriptor<Diary>())
        let trackerRows = try context.fetch(FetchDescriptor<TrackerModel>())

        #expect(legacyRows.count == 1)
        #expect(trackerRows.count == 1)
        #expect(legacyRows[0].name == "Sample Diary")
        #expect(trackerRows[0].name == "Mood Tracker")
    }
}

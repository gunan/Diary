import Foundation
import SwiftData
import Testing
@testable import Diary

@MainActor
struct LegacyDiaryImporterTests {
    @Test func importsLegacyDiaryIntoTrackerModel() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let context = container.mainContext
        let diary = Diary.sampleData()
        diary.name = "Legacy Mood"
        context.insert(diary)
        try context.save()

        try LegacyDiaryImporter.importIfNeeded(in: context)

        let trackers = try context.fetch(FetchDescriptor<TrackerModel>())
        let tracker = try #require(trackers.first)
        let fields = tracker.fields.sorted { $0.sortOrder < $1.sortOrder }

        #expect(trackers.count == 1)
        #expect(tracker.name == "Legacy Mood")
        #expect(fields.contains { $0.name == "rating" })
        #expect(tracker.entries.count == 2)
    }

    @Test func importIsSkippedWhenTrackerRowsAlreadyExist() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let context = container.mainContext
        context.insert(Diary.sampleData())
        context.insert(TrackerModel(name: "Existing Tracker"))
        try context.save()

        try LegacyDiaryImporter.importIfNeeded(in: context)

        let trackers = try context.fetch(FetchDescriptor<TrackerModel>())
        #expect(trackers.count == 1)
        #expect(trackers[0].name == "Existing Tracker")
    }

    @Test func importCreatesFreshStableFieldIDsAndSnapshots() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let context = container.mainContext
        context.insert(Diary.sampleData())
        try context.save()

        try LegacyDiaryImporter.importIfNeeded(in: context)

        let tracker = try #require(try context.fetch(FetchDescriptor<TrackerModel>()).first)
        let fieldsByName = Dictionary(uniqueKeysWithValues: tracker.fields.map { ($0.name, $0.fieldID) })

        #expect(fieldsByName.values.allSatisfy { $0.uuidString.isEmpty == false })

        for entry in tracker.entries {
            let snapshotFieldIDsByName = Dictionary(uniqueKeysWithValues: entry.snapshots.map { ($0.name, $0.fieldID) })
            #expect(snapshotFieldIDsByName == fieldsByName)
        }
    }

    @Test func importPreservesRepresentativeValues() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let context = container.mainContext
        context.insert(Diary.sampleData())
        try context.save()

        try LegacyDiaryImporter.importIfNeeded(in: context)

        let tracker = try #require(try context.fetch(FetchDescriptor<TrackerModel>()).first)
        let fieldIDsByName = Dictionary(uniqueKeysWithValues: tracker.fields.map { ($0.name, $0.fieldID) })
        let entriesByDate = Dictionary(uniqueKeysWithValues: tracker.entries.map { ($0.createdAt, $0) })
        let firstEntry = try #require(entriesByDate.keys.min().flatMap { entriesByDate[$0] })
        let valuesByFieldID = Dictionary(uniqueKeysWithValues: firstEntry.values.map { ($0.fieldID, $0) })

        let titleFieldID = try #require(fieldIDsByName["Title"])
        let summaryFieldID = try #require(fieldIDsByName["Summary"])
        let ratingFieldID = try #require(fieldIDsByName["rating"])
        let tagsFieldID = try #require(fieldIDsByName["tags"])
        let dateFieldID = try #require(fieldIDsByName["date"])
        let timeFieldID = try #require(fieldIDsByName["time"])

        #expect(valuesByFieldID[titleFieldID]?.textValue == "Hello")
        #expect(valuesByFieldID[summaryFieldID]?.textValue == " World")
        #expect(valuesByFieldID[ratingFieldID]?.numberValue == 8.5)
        #expect(valuesByFieldID[tagsFieldID]?.textValue == "medicine")
        #expect(valuesByFieldID[dateFieldID]?.dateValue != nil)
        #expect(valuesByFieldID[timeFieldID]?.timeHour == 4)
        #expect(valuesByFieldID[timeFieldID]?.timeMinute == 30)
    }

    @Test func modelContainerFactorySeedsAndImportsForUITests() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let context = container.mainContext

        ModelContainerFactory.seedLegacySampleData(in: context)
        try LegacyDiaryImporter.importIfNeeded(in: context)

        let legacyRows = try context.fetch(FetchDescriptor<Diary>())
        let trackerRows = try context.fetch(FetchDescriptor<TrackerModel>())

        #expect(legacyRows.count == 1)
        #expect(trackerRows.count == 1)
        #expect(trackerRows[0].name == "Mood Tracker")
        #expect(trackerRows[0].entries.count == 2)
    }
}

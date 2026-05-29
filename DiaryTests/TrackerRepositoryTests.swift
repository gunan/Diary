import Foundation
import SwiftData
import Testing
@testable import Diary

@MainActor
struct TrackerRepositoryTests {
    @Test func createsTrackerWithFields() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let repository = TrackerRepository(context: container.mainContext)

        let tracker = try repository.createTracker(TrackerDraft(
            name: "Mood Tracker",
            fields: [
                TrackerFieldDraft(name: "Energy", type: .number, sortOrder: 0),
            ]
        ))

        #expect(tracker.name == "Mood Tracker")
        #expect(tracker.fields.count == 1)
        #expect(tracker.fields[0].name == "Energy")
    }

    @Test func createsEntryWithFieldSnapshots() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let repository = TrackerRepository(context: container.mainContext)
        let tracker = try repository.createTracker(TrackerDraft(
            name: "Mood Tracker",
            fields: [
                TrackerFieldDraft(name: "Energy", type: .number, sortOrder: 0),
            ]
        ))

        let entry = try repository.createEntry(
            trackerID: tracker.id,
            values: [tracker.fields[0].id: .number(8)]
        )

        #expect(entry.fieldSnapshots[0].name == "Energy")
        #expect(entry.displayRows()[0].value == "8.0")
    }

    @Test func fetchTrackersReturnsNewestCreatedFirst() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let repository = TrackerRepository(context: container.mainContext)
        let context = container.mainContext

        context.insert(TrackerModel(
            name: "Older Tracker",
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 1)
        ))
        context.insert(TrackerModel(
            name: "Newer Tracker",
            createdAt: Date(timeIntervalSince1970: 2),
            updatedAt: Date(timeIntervalSince1970: 2)
        ))
        try context.save()

        let trackers = try repository.fetchTrackers()

        #expect(trackers.map(\.name) == ["Newer Tracker", "Older Tracker"])
    }

    @Test func fieldsAndSnapshotsReturnSortedBySortOrder() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let repository = TrackerRepository(context: container.mainContext)
        let tracker = try repository.createTracker(TrackerDraft(
            name: "Mood Tracker",
            fields: [
                TrackerFieldDraft(name: "Second", type: .text, sortOrder: 1),
                TrackerFieldDraft(name: "First", type: .text, sortOrder: 0),
            ]
        ))

        let entry = try repository.createEntry(
            trackerID: tracker.id,
            values: [
                tracker.fields[0].id: .text("one"),
                tracker.fields[1].id: .text("two"),
            ]
        )

        #expect(tracker.fields.map(\.name) == ["First", "Second"])
        #expect(entry.fieldSnapshots.map(\.name) == ["First", "Second"])
        #expect(entry.displayRows().map(\.label) == ["First", "Second"])
    }

    @Test func timeValuesRoundTripThroughHourAndMinuteColumns() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let repository = TrackerRepository(context: container.mainContext)
        let tracker = try repository.createTracker(TrackerDraft(
            name: "Routine Tracker",
            fields: [
                TrackerFieldDraft(name: "Wake", type: .time, sortOrder: 0),
            ]
        ))

        let entry = try repository.createEntry(
            trackerID: tracker.id,
            values: [tracker.fields[0].id: .time(TimeOfDay(hour: 6, minute: 30))]
        )
        let storedValue = try #require(try container.mainContext.fetch(FetchDescriptor<EntryValueModel>()).first)

        #expect(storedValue.timeHour == 6)
        #expect(storedValue.timeMinute == 30)
        #expect(entry.values[tracker.fields[0].id] == .time(TimeOfDay(hour: 6, minute: 30)))
    }

    @Test func missingTrackerIDThrowsTrackerNotFound() throws {
        let container = try ModelContainerFactory.makeTestingContainer()
        let repository = TrackerRepository(context: container.mainContext)

        #expect(throws: TrackerRepositoryError.trackerNotFound) {
            try repository.createEntry(trackerID: TrackerID(), values: [:])
        }
    }
}

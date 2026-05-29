import Foundation
import Testing
@testable import Diary

struct TrackerDomainTests {
    @Test func fieldRenameKeepsStableID() {
        let fieldID = FieldID()
        var tracker = Tracker(
            id: TrackerID(),
            name: "Mood Tracker",
            fields: [
                TrackerFieldDefinition(id: fieldID, name: "Mood", type: .number, sortOrder: 0)
            ],
            entries: [],
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0)
        )

        tracker.renameField(id: fieldID, to: "Energy")

        #expect(tracker.fields[0].id == fieldID)
        #expect(tracker.fields[0].name == "Energy")
    }

    @Test func entryValueRendersFromSnapshotAfterRename() {
        let fieldID = FieldID()
        var tracker = Tracker(
            id: TrackerID(),
            name: "Mood Tracker",
            fields: [
                TrackerFieldDefinition(id: fieldID, name: "Mood", type: .number, sortOrder: 0)
            ],
            entries: [],
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0)
        )
        let snapshot = FieldSnapshot(
            id: tracker.fields[0].id,
            name: tracker.fields[0].name,
            type: tracker.fields[0].type,
            sortOrder: tracker.fields[0].sortOrder
        )
        let entry = TrackerEntry(
            id: EntryID(),
            createdAt: Date(timeIntervalSince1970: 10),
            fieldSnapshots: [snapshot],
            values: [fieldID: .number(7.5)]
        )

        tracker.renameField(id: fieldID, to: "Energy")

        #expect(tracker.fields[0].id == fieldID)
        #expect(tracker.fields[0].name == "Energy")
        #expect(entry.displayRows()[0].label == "Mood")
        #expect(entry.displayRows()[0].value == "7.5")
    }

    @Test func dateDisplayUsesFixedUTCCalendar() {
        let value = EntryValue.date(Date(timeIntervalSince1970: 60 * 60))

        #expect(value.displayValue == "1970-01-01")
    }

    @Test func timeOfDayDisplaysAsHourMinute() {
        let value = EntryValue.time(TimeOfDay(hour: 9, minute: 5))

        #expect(value.displayValue == "09:05")
    }

    @Test func invalidTimeOfDayDecodeThrows() {
        let invalidHourData = Data(#"{"hour":99,"minute":5}"#.utf8)
        let invalidMinuteData = Data(#"{"hour":9,"minute":-4}"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(TimeOfDay.self, from: invalidHourData)
        }
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(TimeOfDay.self, from: invalidMinuteData)
        }
    }

    @Test func displayRowsUseStableFieldIDTieBreaker() {
        let laterFieldID = FieldID(UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!)
        let earlierFieldID = FieldID(UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!)
        let entry = TrackerEntry(
            id: EntryID(),
            createdAt: Date(timeIntervalSince1970: 0),
            fieldSnapshots: [
                FieldSnapshot(id: laterFieldID, name: "Later", type: .text, sortOrder: 0),
                FieldSnapshot(id: earlierFieldID, name: "Earlier", type: .text, sortOrder: 0)
            ],
            values: [
                laterFieldID: .text("second"),
                earlierFieldID: .text("first")
            ]
        )

        #expect(entry.displayRows() == [
            EntryDisplayRow(label: "Earlier", value: "first"),
            EntryDisplayRow(label: "Later", value: "second")
        ])
    }

    @Test func renameFieldUsesInjectedUpdatedAt() {
        let fieldID = FieldID()
        let injectedDate = Date(timeIntervalSince1970: 123)
        var tracker = Tracker(
            id: TrackerID(),
            name: "Mood Tracker",
            fields: [
                TrackerFieldDefinition(id: fieldID, name: "Mood", type: .number, sortOrder: 0)
            ],
            entries: [],
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0)
        )

        tracker.renameField(id: fieldID, to: "Energy", updatedAt: injectedDate)

        #expect(tracker.fields[0].name == "Energy")
        #expect(tracker.updatedAt == injectedDate)
    }
}

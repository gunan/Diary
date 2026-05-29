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
}

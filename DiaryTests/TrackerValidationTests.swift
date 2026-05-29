import Foundation
import Testing
@testable import Diary

struct TrackerValidationTests {
    @Test func emptyTrackerNameIsInvalid() {
        let draft = TrackerDraft(name: " ", fields: [])
        #expect(TrackerValidator.validateTracker(draft).contains(.emptyTrackerName))
    }

    @Test func numberValueRejectsText() {
        let field = TrackerFieldDefinition(name: "Energy", type: .number, sortOrder: 0)
        let result = TrackerValidator.validate(value: .text("high"), for: field)
        #expect(result == .wrongValueType(fieldName: "Energy"))
    }

    @Test func selectorRequiresKnownOption() {
        let field = TrackerFieldDefinition(
            name: "Tag",
            type: .selector,
            sortOrder: 0,
            options: ["Work", "Health"]
        )
        let result = TrackerValidator.validate(value: .selector("Travel"), for: field)
        #expect(result == .invalidSelectorOption(fieldName: "Tag", option: "Travel"))
    }
}

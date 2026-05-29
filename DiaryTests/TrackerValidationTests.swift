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

    @Test func duplicateFieldNameUsesTrimmedCaseInsensitiveName() {
        let draft = TrackerDraft(
            name: "Daily",
            fields: [
                TrackerFieldDraft(name: " Energy ", type: .number, sortOrder: 0),
                TrackerFieldDraft(name: "energy", type: .number, sortOrder: 1)
            ]
        )

        #expect(TrackerValidator.validateTracker(draft).contains(.duplicateFieldName("energy")))
    }

    @Test func emptyFieldNamesDoNotEmitDuplicateNameError() {
        let draft = TrackerDraft(
            name: "Daily",
            fields: [
                TrackerFieldDraft(name: " ", type: .text, sortOrder: 0),
                TrackerFieldDraft(name: "\n", type: .text, sortOrder: 1)
            ]
        )
        let errors = TrackerValidator.validateTracker(draft)

        #expect(errors.filter { $0 == .emptyFieldName }.count == 2)
        #expect(!errors.contains(.duplicateFieldName("")))
    }

    @Test func selectorRejectsBlankOptions() {
        let draft = TrackerDraft(
            name: "Daily",
            fields: [
                TrackerFieldDraft(name: "Tag", type: .selector, sortOrder: 0, options: ["Work", " "])
            ]
        )
        let errors = TrackerValidator.validateTracker(draft)

        #expect(errors.contains(.emptySelectorOption(fieldName: "Tag")))
    }

    @Test func selectorRequiresAtLeastOneNonEmptyOption() {
        let draft = TrackerDraft(
            name: "Daily",
            fields: [
                TrackerFieldDraft(name: "Tag", type: .selector, sortOrder: 0, options: [" "])
            ]
        )
        let errors = TrackerValidator.validateTracker(draft)

        #expect(errors.contains(.emptySelectorOption(fieldName: "Tag")))
        #expect(errors.contains(.selectorWithoutOptions(fieldName: "Tag")))
    }

    @Test func selectorValueValidationTrimsOptionAndValue() {
        let field = TrackerFieldDefinition(
            name: "Tag",
            type: .selector,
            sortOrder: 0,
            options: [" Work ", "Health"]
        )

        #expect(TrackerValidator.validate(value: .selector("\nWork "), for: field) == nil)
    }

    @Test func numberValueRejectsValuesOutsideBounds() {
        let field = TrackerFieldDefinition(
            name: "Energy",
            type: .number,
            sortOrder: 0,
            minValue: 1,
            maxValue: 10
        )

        #expect(TrackerValidator.validate(value: .number(0), for: field) == .numberBelowMinimum(fieldName: "Energy", minimum: 1))
        #expect(TrackerValidator.validate(value: .number(11), for: field) == .numberAboveMaximum(fieldName: "Energy", maximum: 10))
    }

    @Test func numberFieldRejectsInvalidRange() {
        let draft = TrackerDraft(
            name: "Daily",
            fields: [
                TrackerFieldDraft(name: "Energy", type: .number, sortOrder: 0, minValue: 10, maxValue: 1)
            ]
        )

        #expect(TrackerValidator.validateTracker(draft).contains(.invalidNumberRange(fieldName: "Energy", min: 10, max: 1)))
    }

    @Test func unavailableValueIsAllowedForAnyFieldType() {
        let field = TrackerFieldDefinition(name: "Energy", type: .number, sortOrder: 0)

        #expect(TrackerValidator.validate(value: .unavailable("legacy import"), for: field) == nil)
    }
}

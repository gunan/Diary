import Foundation
import Testing
@testable import Diary

struct EntryEditorValueParsingTests {
    @Test func dateValueNormalizesLocalCalendarDayToUTCMidnight() throws {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = TimeZone(secondsFromGMT: -8 * 60 * 60)!
        let selectedDate = try #require(localCalendar.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 18)))

        let normalizedDate = EntryEditorValueNormalizer.dateValue(from: selectedDate, calendar: localCalendar)

        #expect(EntryValue.date(normalizedDate).displayValue == "2026-01-02")
    }

    @Test func numberValueRejectsNonFiniteInput() {
        #expect(throws: EntryEditorError.invalidNumber("rating")) {
            _ = try EntryEditorValueNormalizer.numberValue(from: "nan", fieldName: "rating")
        }

        #expect(throws: EntryEditorError.invalidNumber("rating")) {
            _ = try EntryEditorValueNormalizer.numberValue(from: "inf", fieldName: "rating")
        }
    }

    @Test func numberValueAcceptsFiniteInput() throws {
        let value = try EntryEditorValueNormalizer.numberValue(from: "9", fieldName: "rating")

        #expect(value == 9)
    }
}

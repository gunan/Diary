import Foundation
import Testing
@testable import Diary

struct TrackerChartingTests {
    @Test func compatibleFieldsReturnsNumberFieldsSortedBySortOrderThenID() {
        let laterNumberID = FieldID(UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!)
        let earlierNumberID = FieldID(UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!)
        let firstNumberID = FieldID(UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!)
        let textID = FieldID(UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!)
        let fields = [
            TrackerFieldDefinition(id: laterNumberID, name: "Later", type: .number, sortOrder: 1),
            TrackerFieldDefinition(id: textID, name: "Notes", type: .text, sortOrder: 0),
            TrackerFieldDefinition(id: firstNumberID, name: "First", type: .number, sortOrder: 0),
            TrackerFieldDefinition(id: earlierNumberID, name: "Earlier", type: .number, sortOrder: 1)
        ]

        let compatible = TrackerChartAggregator.compatibleFields(fields)

        #expect(compatible.map(\.id) == [firstNumberID, earlierNumberID, laterNumberID])
    }

    @Test func dayPointsAverageSelectedNumberValuesAndIgnoreNonNumbers() {
        let calendar = Self.utcCalendar()
        let energyID = FieldID(UUID(uuidString: "11111111-1111-1111-1111-111111111111")!)
        let moodID = FieldID(UUID(uuidString: "22222222-2222-2222-2222-222222222222")!)
        let fields = [
            TrackerFieldDefinition(id: moodID, name: "Mood", type: .number, sortOrder: 0),
            TrackerFieldDefinition(id: energyID, name: "Energy", type: .number, sortOrder: 1)
        ]
        let entries = [
            Self.entry(day: 2026_05_25, values: [energyID: .number(2), moodID: .number(6)]),
            Self.entry(day: 2026_05_25, values: [energyID: .number(4), moodID: .text("great")]),
            Self.entry(day: 2026_05_26, values: [energyID: .unavailable("legacy"), moodID: .number(8)]),
            Self.entry(day: 2026_05_26, values: [moodID: .number(10)])
        ]

        let points = TrackerChartAggregator.points(
            entries: entries,
            fields: fields,
            selectedFieldIDs: [energyID, moodID],
            period: .last7Days,
            bucket: .day,
            calendar: calendar,
            now: Self.date(day: 2026_05_29)
        )

        #expect(points == [
            TrackerChartPoint(date: Self.date(day: 2026_05_25), fieldID: moodID, fieldName: "Mood", value: 6),
            TrackerChartPoint(date: Self.date(day: 2026_05_25), fieldID: energyID, fieldName: "Energy", value: 3),
            TrackerChartPoint(date: Self.date(day: 2026_05_26), fieldID: moodID, fieldName: "Mood", value: 9)
        ])
    }

    @Test func periodFilteringUsesStartOfCurrentDayForLastSevenAndThirtyDays() {
        let calendar = Self.utcCalendar()
        let fieldID = FieldID(UUID(uuidString: "11111111-1111-1111-1111-111111111111")!)
        let fields = [TrackerFieldDefinition(id: fieldID, name: "Score", type: .number, sortOrder: 0)]
        let now = Self.date(day: 2026_05_29, hour: 15)
        let entries = [
            Self.entry(day: 2026_05_22, hour: 23, values: [fieldID: .number(1)]),
            Self.entry(day: 2026_05_23, values: [fieldID: .number(2)]),
            Self.entry(day: 2026_04_29, values: [fieldID: .number(3)]),
            Self.entry(day: 2026_04_30, values: [fieldID: .number(4)])
        ]

        let last7Days = TrackerChartAggregator.points(
            entries: entries,
            fields: fields,
            selectedFieldIDs: [fieldID],
            period: .last7Days,
            bucket: .day,
            calendar: calendar,
            now: now
        )
        let last30Days = TrackerChartAggregator.points(
            entries: entries,
            fields: fields,
            selectedFieldIDs: [fieldID],
            period: .last30Days,
            bucket: .day,
            calendar: calendar,
            now: now
        )

        #expect(last7Days.map(\.date) == [Self.date(day: 2026_05_23)])
        #expect(last30Days.map(\.date) == [Self.date(day: 2026_04_30), Self.date(day: 2026_05_22), Self.date(day: 2026_05_23)])
    }

    @Test func weekAndMonthBucketsUseSuppliedCalendar() {
        let calendar = Self.utcCalendar()
        let fieldID = FieldID(UUID(uuidString: "11111111-1111-1111-1111-111111111111")!)
        let fields = [TrackerFieldDefinition(id: fieldID, name: "Score", type: .number, sortOrder: 0)]
        let entries = [
            Self.entry(day: 2026_04_30, values: [fieldID: .number(1)]),
            Self.entry(day: 2026_05_01, values: [fieldID: .number(3)]),
            Self.entry(day: 2026_05_03, values: [fieldID: .number(5)]),
            Self.entry(day: 2026_05_04, values: [fieldID: .number(7)])
        ]

        let weekly = TrackerChartAggregator.points(
            entries: entries,
            fields: fields,
            selectedFieldIDs: [fieldID],
            period: .last30Days,
            bucket: .week,
            calendar: calendar,
            now: Self.date(day: 2026_05_29)
        )
        let monthly = TrackerChartAggregator.points(
            entries: entries,
            fields: fields,
            selectedFieldIDs: [fieldID],
            period: .last30Days,
            bucket: .month,
            calendar: calendar,
            now: Self.date(day: 2026_05_29)
        )

        #expect(weekly == [
            TrackerChartPoint(date: Self.date(day: 2026_04_27), fieldID: fieldID, fieldName: "Score", value: 3),
            TrackerChartPoint(date: Self.date(day: 2026_05_04), fieldID: fieldID, fieldName: "Score", value: 7)
        ])
        #expect(monthly == [
            TrackerChartPoint(date: Self.date(day: 2026_04_01), fieldID: fieldID, fieldName: "Score", value: 1),
            TrackerChartPoint(date: Self.date(day: 2026_05_01), fieldID: fieldID, fieldName: "Score", value: 5)
        ])
    }

    @Test func allTimeIncludesOldEntriesAndKeepsDeterministicDateThenFieldOrder() {
        let calendar = Self.utcCalendar()
        let laterID = FieldID(UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!)
        let earlierID = FieldID(UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!)
        let unselectedID = FieldID(UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!)
        let fields = [
            TrackerFieldDefinition(id: laterID, name: "Later", type: .number, sortOrder: 1),
            TrackerFieldDefinition(id: unselectedID, name: "Hidden", type: .number, sortOrder: 0),
            TrackerFieldDefinition(id: earlierID, name: "Earlier", type: .number, sortOrder: 1)
        ]
        let entries = [
            Self.entry(day: 2024_01_01, values: [laterID: .number(4), earlierID: .number(2), unselectedID: .number(100)]),
            Self.entry(day: 2024_01_01, values: [laterID: .number(8), earlierID: .number(6)]),
            Self.entry(day: 2026_05_29, values: [earlierID: .number(10), laterID: .text("skip")])
        ]

        let points = TrackerChartAggregator.points(
            entries: entries,
            fields: fields,
            selectedFieldIDs: [laterID, earlierID],
            period: .allTime,
            bucket: .day,
            calendar: calendar,
            now: Self.date(day: 2026_05_29)
        )

        #expect(points == [
            TrackerChartPoint(date: Self.date(day: 2024_01_01), fieldID: earlierID, fieldName: "Earlier", value: 4),
            TrackerChartPoint(date: Self.date(day: 2024_01_01), fieldID: laterID, fieldName: "Later", value: 6),
            TrackerChartPoint(date: Self.date(day: 2026_05_29), fieldID: earlierID, fieldName: "Earlier", value: 10)
        ])
    }

    @Test func lastYearFiltersRelativeToStartOfCurrentDay() {
        let calendar = Self.utcCalendar()
        let fieldID = FieldID(UUID(uuidString: "11111111-1111-1111-1111-111111111111")!)
        let fields = [TrackerFieldDefinition(id: fieldID, name: "Score", type: .number, sortOrder: 0)]
        let entries = [
            Self.entry(day: 2025_05_28, hour: 23, values: [fieldID: .number(1)]),
            Self.entry(day: 2025_05_29, values: [fieldID: .number(2)]),
            Self.entry(day: 2026_05_29, values: [fieldID: .number(3)])
        ]

        let points = TrackerChartAggregator.points(
            entries: entries,
            fields: fields,
            selectedFieldIDs: [fieldID],
            period: .lastYear,
            bucket: .month,
            calendar: calendar,
            now: Self.date(day: 2026_05_29, hour: 12)
        )

        #expect(points == [
            TrackerChartPoint(date: Self.date(day: 2025_05_01), fieldID: fieldID, fieldName: "Score", value: 2),
            TrackerChartPoint(date: Self.date(day: 2026_05_01), fieldID: fieldID, fieldName: "Score", value: 3)
        ])
    }

    private static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    private static func entry(day: Int, hour: Int = 0, values: [FieldID: EntryValue]) -> TrackerEntry {
        TrackerEntry(
            id: EntryID(),
            createdAt: date(day: day, hour: hour),
            fieldSnapshots: [],
            values: values
        )
    }

    private static func date(day: Int, hour: Int = 0) -> Date {
        let year = day / 10_000
        let month = (day / 100) % 100
        let dayOfMonth = day % 100
        return DateComponents(
            calendar: utcCalendar(),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: dayOfMonth,
            hour: hour
        ).date!
    }
}

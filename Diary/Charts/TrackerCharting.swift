import Foundation

enum TrackerChartPeriod: String, CaseIterable, Identifiable {
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case lastYear = "Last Year"
    case allTime = "All Time"

    var id: String { rawValue }
}

enum TrackerChartBucket: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
}

enum TrackerChartStyle: String, CaseIterable, Identifiable {
    case bar = "Bar"
    case line = "Line"
    case scatter = "Scatter"

    var id: String { rawValue }
}

struct TrackerChartPoint: Identifiable, Equatable {
    var date: Date
    var fieldID: FieldID
    var fieldName: String
    var value: Double

    var id: String {
        "\(date.timeIntervalSinceReferenceDate)-\(fieldID.rawValue.uuidString)"
    }
}

enum TrackerChartAggregator {
    static func compatibleFields(_ fields: [TrackerFieldDefinition]) -> [TrackerFieldDefinition] {
        fields
            .filter { $0.type == .number }
            .sorted(by: fieldSort)
    }

    static func points(
        entries: [TrackerEntry],
        fields: [TrackerFieldDefinition],
        selectedFieldIDs: Set<FieldID>,
        period: TrackerChartPeriod,
        bucket: TrackerChartBucket,
        calendar: Calendar,
        now: Date
    ) -> [TrackerChartPoint] {
        let fieldsByID = Dictionary(uniqueKeysWithValues: compatibleFields(fields).map { ($0.id, $0) })
        let selectedFields = compatibleFields(fields).filter { selectedFieldIDs.contains($0.id) }
        guard !selectedFields.isEmpty else { return [] }

        let selectedIDs = Set(selectedFields.map(\.id))
        let startDate = periodStart(for: period, calendar: calendar, now: now)
        var groupedValues: [BucketKey: [Double]] = [:]

        for entry in entries where isIncluded(entry.createdAt, startDate: startDate, now: now) {
            let bucketDate = bucketStart(for: entry.createdAt, bucket: bucket, calendar: calendar)

            for (fieldID, value) in entry.values where selectedIDs.contains(fieldID) {
                guard case .number(let number) = value else { continue }
                groupedValues[BucketKey(date: bucketDate, fieldID: fieldID), default: []].append(number)
            }
        }

        return groupedValues
            .compactMap { key, values -> TrackerChartPoint? in
                guard let field = fieldsByID[key.fieldID], !values.isEmpty else { return nil }
                let total = values.reduce(0, +)
                return TrackerChartPoint(
                    date: key.date,
                    fieldID: key.fieldID,
                    fieldName: field.name,
                    value: total / Double(values.count)
                )
            }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date {
                    return lhs.date < rhs.date
                }

                guard let lhsField = fieldsByID[lhs.fieldID], let rhsField = fieldsByID[rhs.fieldID] else {
                    return lhs.fieldID.rawValue.uuidString < rhs.fieldID.rawValue.uuidString
                }

                return fieldSort(lhsField, rhsField)
            }
    }

    static func points(
        entries: [TrackerEntry],
        fields: [TrackerFieldDefinition],
        selectedFieldIDs: [FieldID],
        period: TrackerChartPeriod,
        bucket: TrackerChartBucket,
        calendar: Calendar,
        now: Date
    ) -> [TrackerChartPoint] {
        points(
            entries: entries,
            fields: fields,
            selectedFieldIDs: Set(selectedFieldIDs),
            period: period,
            bucket: bucket,
            calendar: calendar,
            now: now
        )
    }

    private static func fieldSort(_ lhs: TrackerFieldDefinition, _ rhs: TrackerFieldDefinition) -> Bool {
        if lhs.sortOrder == rhs.sortOrder {
            return lhs.id.rawValue.uuidString < rhs.id.rawValue.uuidString
        }
        return lhs.sortOrder < rhs.sortOrder
    }

    private static func periodStart(for period: TrackerChartPeriod, calendar: Calendar, now: Date) -> Date? {
        let today = calendar.startOfDay(for: now)

        switch period {
        case .last7Days:
            return calendar.date(byAdding: .day, value: -6, to: today)
        case .last30Days:
            return calendar.date(byAdding: .day, value: -29, to: today)
        case .lastYear:
            return calendar.date(byAdding: .year, value: -1, to: today)
        case .allTime:
            return nil
        }
    }

    private static func isIncluded(_ date: Date, startDate: Date?, now: Date) -> Bool {
        if let startDate, date < startDate {
            return false
        }

        return date <= now
    }

    private static func bucketStart(for date: Date, bucket: TrackerChartBucket, calendar: Calendar) -> Date {
        switch bucket {
        case .day:
            return calendar.startOfDay(for: date)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        case .month:
            return calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
        }
    }

    private struct BucketKey: Hashable {
        var date: Date
        var fieldID: FieldID
    }
}

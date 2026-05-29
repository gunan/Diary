import Foundation

struct TrackerID: Hashable, Codable, Identifiable {
    let rawValue: UUID
    var id: UUID { rawValue }

    init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

struct FieldID: Hashable, Codable, Identifiable {
    let rawValue: UUID
    var id: UUID { rawValue }

    init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

struct EntryID: Hashable, Codable, Identifiable {
    let rawValue: UUID
    var id: UUID { rawValue }

    init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

enum TrackerFieldType: String, Codable, CaseIterable, Identifiable {
    case text
    case number
    case date
    case time
    case selector

    var id: String { rawValue }
}

struct TrackerFieldDefinition: Identifiable, Hashable, Codable {
    var id: FieldID
    var name: String
    var type: TrackerFieldType
    var sortOrder: Int
    var options: [String]
    var minValue: Double?
    var maxValue: Double?

    init(
        id: FieldID = FieldID(),
        name: String,
        type: TrackerFieldType,
        sortOrder: Int,
        options: [String] = [],
        minValue: Double? = nil,
        maxValue: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.sortOrder = sortOrder
        self.options = options
        self.minValue = minValue
        self.maxValue = maxValue
    }
}

struct FieldSnapshot: Identifiable, Hashable, Codable {
    var id: FieldID
    var name: String
    var type: TrackerFieldType
    var sortOrder: Int
}

struct TimeOfDay: Hashable, Codable {
    var hour: Int
    var minute: Int
}

enum EntryValue: Hashable, Codable {
    case text(String)
    case number(Double)
    case date(Date)
    case time(TimeOfDay)
    case selector(String)
    case unavailable(String)

    var displayValue: String {
        switch self {
        case .text(let value), .selector(let value):
            return value
        case .number(let value):
            return String(value)
        case .date(let value):
            return EntryValueFormatters.date.string(from: value)
        case .time(let value):
            return String(format: "%02d:%02d", value.hour, value.minute)
        case .unavailable(let reason):
            return reason
        }
    }
}

enum EntryValueFormatters {
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct EntryDisplayRow: Equatable {
    var label: String
    var value: String
}

struct TrackerEntry: Identifiable, Hashable, Codable {
    var id: EntryID
    var createdAt: Date
    var fieldSnapshots: [FieldSnapshot]
    var values: [FieldID: EntryValue]

    func displayRows() -> [EntryDisplayRow] {
        fieldSnapshots
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
                }
                return $0.sortOrder < $1.sortOrder
            }
            .map { snapshot in
                EntryDisplayRow(
                    label: snapshot.name,
                    value: values[snapshot.id]?.displayValue ?? ""
                )
            }
    }
}

struct Tracker: Identifiable, Hashable, Codable {
    var id: TrackerID
    var name: String
    var fields: [TrackerFieldDefinition]
    var entries: [TrackerEntry]
    var createdAt: Date
    var updatedAt: Date

    mutating func renameField(id: FieldID, to name: String, updatedAt: Date = Date()) {
        guard let index = fields.firstIndex(where: { $0.id == id }) else { return }
        fields[index].name = name
        self.updatedAt = updatedAt
    }
}

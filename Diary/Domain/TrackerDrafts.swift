import Foundation

struct TrackerDraft: Equatable {
    var name: String
    var fields: [TrackerFieldDraft]
}

struct TrackerFieldDraft: Identifiable, Equatable {
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

struct EntryDraft {
    var trackerID: TrackerID
    var createdAt: Date
    var values: [FieldID: EntryValue]
}

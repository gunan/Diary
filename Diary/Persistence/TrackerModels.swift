import Foundation
import SwiftData

@Model
final class TrackerModel {
    @Attribute(.unique) var trackerID: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var fields: [FieldDefinitionModel]

    @Relationship(deleteRule: .cascade)
    var entries: [EntryModel]

    init(
        trackerID: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        fields: [FieldDefinitionModel] = [],
        entries: [EntryModel] = []
    ) {
        self.trackerID = trackerID
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.fields = fields
        self.entries = entries
    }
}

@Model
final class FieldDefinitionModel {
    @Attribute(.unique) var fieldID: UUID
    var name: String
    var typeRaw: String
    var sortOrder: Int
    var options: [String]
    var minValue: Double?
    var maxValue: Double?

    init(
        fieldID: UUID = UUID(),
        name: String,
        typeRaw: String,
        sortOrder: Int,
        options: [String] = [],
        minValue: Double? = nil,
        maxValue: Double? = nil
    ) {
        self.fieldID = fieldID
        self.name = name
        self.typeRaw = typeRaw
        self.sortOrder = sortOrder
        self.options = options
        self.minValue = minValue
        self.maxValue = maxValue
    }
}

@Model
final class EntryModel {
    @Attribute(.unique) var entryID: UUID
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var values: [EntryValueModel]

    @Relationship(deleteRule: .cascade)
    var snapshots: [FieldSnapshotModel]

    init(
        entryID: UUID = UUID(),
        createdAt: Date = Date(),
        values: [EntryValueModel] = [],
        snapshots: [FieldSnapshotModel] = []
    ) {
        self.entryID = entryID
        self.createdAt = createdAt
        self.values = values
        self.snapshots = snapshots
    }
}

@Model
final class EntryValueModel {
    @Attribute(.unique) var valueID: UUID
    var fieldID: UUID
    var typeRaw: String
    var textValue: String?
    var numberValue: Double?
    var dateValue: Date?
    var timeHour: Int?
    var timeMinute: Int?
    var unavailableReason: String?

    init(
        valueID: UUID = UUID(),
        fieldID: UUID,
        typeRaw: String,
        textValue: String? = nil,
        numberValue: Double? = nil,
        dateValue: Date? = nil,
        timeHour: Int? = nil,
        timeMinute: Int? = nil,
        unavailableReason: String? = nil
    ) {
        self.valueID = valueID
        self.fieldID = fieldID
        self.typeRaw = typeRaw
        self.textValue = textValue
        self.numberValue = numberValue
        self.dateValue = dateValue
        self.timeHour = timeHour
        self.timeMinute = timeMinute
        self.unavailableReason = unavailableReason
    }
}

@Model
final class FieldSnapshotModel {
    @Attribute(.unique) var snapshotID: UUID
    var fieldID: UUID
    var name: String
    var typeRaw: String
    var sortOrder: Int

    init(
        snapshotID: UUID = UUID(),
        fieldID: UUID,
        name: String,
        typeRaw: String,
        sortOrder: Int
    ) {
        self.snapshotID = snapshotID
        self.fieldID = fieldID
        self.name = name
        self.typeRaw = typeRaw
        self.sortOrder = sortOrder
    }
}

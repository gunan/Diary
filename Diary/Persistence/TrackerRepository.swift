import Foundation
import SwiftData

enum TrackerRepositoryError: Error, Equatable, LocalizedError {
    case trackerNotFound
    case entryNotFound
    case unknownField(FieldID)

    var errorDescription: String? {
        switch self {
        case .trackerNotFound:
            return "Tracker not found."
        case .entryNotFound:
            return "Entry not found."
        case .unknownField:
            return "Entry contains an unknown field."
        }
    }
}

@MainActor
final class TrackerRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchTrackers() throws -> [Tracker] {
        let descriptor = FetchDescriptor<TrackerModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(Self.domainTracker(from:))
    }

    func createTracker(_ draft: TrackerDraft) throws -> Tracker {
        let errors = TrackerValidator.validateTracker(draft)
        if let error = errors.first {
            throw error
        }

        let model = TrackerModel(name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines))
        model.fields = draft.fields.map {
            FieldDefinitionModel(
                fieldID: $0.id.rawValue,
                name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines),
                typeRaw: $0.type.rawValue,
                sortOrder: $0.sortOrder,
                options: $0.options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
                minValue: $0.minValue,
                maxValue: $0.maxValue
            )
        }
        context.insert(model)
        try context.save()
        return Self.domainTracker(from: model)
    }

    func updateTracker(id: TrackerID, with draft: TrackerDraft) throws -> Tracker {
        let errors = TrackerValidator.validateTracker(draft)
        if let error = errors.first {
            throw error
        }

        let trackerModel = try requireTrackerModel(id: id)
        let existingFieldsByID = Dictionary(uniqueKeysWithValues: trackerModel.fields.map { ($0.fieldID, $0) })
        let updatedFields = draft.fields
            .sorted(by: Self.fieldDraftSort)
            .map { fieldDraft in
                let model = existingFieldsByID[fieldDraft.id.rawValue] ?? FieldDefinitionModel(
                    fieldID: fieldDraft.id.rawValue,
                    name: fieldDraft.name,
                    typeRaw: fieldDraft.type.rawValue,
                    sortOrder: fieldDraft.sortOrder
                )
                model.name = fieldDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                model.typeRaw = fieldDraft.type.rawValue
                model.sortOrder = fieldDraft.sortOrder
                model.options = fieldDraft.options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                model.minValue = fieldDraft.minValue
                model.maxValue = fieldDraft.maxValue
                return model
            }

        trackerModel.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        trackerModel.fields = updatedFields
        trackerModel.updatedAt = Date()
        try context.save()
        return Self.domainTracker(from: trackerModel)
    }

    func createEntry(trackerID: TrackerID, values: [FieldID: EntryValue]) throws -> TrackerEntry {
        let trackerModel = try requireTrackerModel(id: trackerID)
        let domainFields = Self.domainFields(from: trackerModel)
        try Self.validate(values: values, for: domainFields)

        let entry = EntryModel(createdAt: Date())
        entry.snapshots = Self.snapshotModels(from: domainFields)
        entry.values = values.map { fieldID, value in
            Self.valueModel(fieldID: fieldID, value: value)
        }
        trackerModel.entries.append(entry)
        trackerModel.updatedAt = Date()
        try context.save()
        return Self.domainEntry(from: entry)
    }

    func updateEntry(trackerID: TrackerID, entryID: EntryID, values: [FieldID: EntryValue]) throws -> TrackerEntry {
        let trackerModel = try requireTrackerModel(id: trackerID)
        guard let entry = trackerModel.entries.first(where: { $0.entryID == entryID.rawValue }) else {
            throw TrackerRepositoryError.entryNotFound
        }

        let domainFields = Self.domainFields(from: trackerModel)
        try Self.validate(values: values, for: domainFields)

        let previousValues = entry.values
        let previousSnapshots = entry.snapshots

        entry.values = values.map { fieldID, value in
            Self.valueModel(fieldID: fieldID, value: value)
        }
        entry.snapshots = Self.snapshotModels(from: domainFields)
        trackerModel.updatedAt = Date()

        previousValues.forEach(context.delete)
        previousSnapshots.forEach(context.delete)

        try context.save()
        return Self.domainEntry(from: entry)
    }

    func deleteEntry(trackerID: TrackerID, entryID: EntryID) throws {
        let trackerModel = try requireTrackerModel(id: trackerID)
        guard let entryIndex = trackerModel.entries.firstIndex(where: { $0.entryID == entryID.rawValue }) else {
            throw TrackerRepositoryError.entryNotFound
        }

        let entry = trackerModel.entries.remove(at: entryIndex)
        context.delete(entry)
        trackerModel.updatedAt = Date()
        try context.save()
    }
}

private extension TrackerRepository {
    func requireTrackerModel(id: TrackerID) throws -> TrackerModel {
        let rawID = id.rawValue
        var descriptor = FetchDescriptor<TrackerModel>(
            predicate: #Predicate { $0.trackerID == rawID }
        )
        descriptor.fetchLimit = 1
        guard let tracker = try context.fetch(descriptor).first else {
            throw TrackerRepositoryError.trackerNotFound
        }
        return tracker
    }

    static func domainTracker(from model: TrackerModel) -> Tracker {
        Tracker(
            id: TrackerID(model.trackerID),
            name: model.name,
            fields: model.fields.map(domainField(from:)).sorted(by: fieldSort),
            entries: model.entries.map(domainEntry(from:)).sorted { $0.createdAt > $1.createdAt },
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }

    static func domainField(from model: FieldDefinitionModel) -> TrackerFieldDefinition {
        TrackerFieldDefinition(
            id: FieldID(model.fieldID),
            name: model.name,
            type: TrackerFieldType(rawValue: model.typeRaw) ?? .text,
            sortOrder: model.sortOrder,
            options: model.options,
            minValue: model.minValue,
            maxValue: model.maxValue
        )
    }

    static func domainFields(from trackerModel: TrackerModel) -> [TrackerFieldDefinition] {
        trackerModel.fields.map(domainField(from:)).sorted(by: fieldSort)
    }

    static func validate(values: [FieldID: EntryValue], for fields: [TrackerFieldDefinition]) throws {
        let knownFieldIDs = Set(fields.map(\.id))

        for fieldID in values.keys where !knownFieldIDs.contains(fieldID) {
            throw TrackerRepositoryError.unknownField(fieldID)
        }

        for field in fields {
            if let value = values[field.id], let error = TrackerValidator.validate(value: value, for: field) {
                throw error
            }
        }
    }

    static func snapshotModels(from fields: [TrackerFieldDefinition]) -> [FieldSnapshotModel] {
        fields.map {
            FieldSnapshotModel(
                fieldID: $0.id.rawValue,
                name: $0.name,
                typeRaw: $0.type.rawValue,
                sortOrder: $0.sortOrder
            )
        }
    }

    static func domainEntry(from model: EntryModel) -> TrackerEntry {
        let values = model.values
            .sorted { $0.valueID.uuidString < $1.valueID.uuidString }
            .reduce(into: [FieldID: EntryValue]()) { partialResult, valueModel in
                let fieldID = FieldID(valueModel.fieldID)
                if partialResult[fieldID] == nil {
                    partialResult[fieldID] = domainValue(from: valueModel)
                }
            }

        return TrackerEntry(
            id: EntryID(model.entryID),
            createdAt: model.createdAt,
            fieldSnapshots: model.snapshots.map {
                FieldSnapshot(
                    id: FieldID($0.fieldID),
                    name: $0.name,
                    type: TrackerFieldType(rawValue: $0.typeRaw) ?? .text,
                    sortOrder: $0.sortOrder
                )
            }
            .sorted { $0.sortOrder < $1.sortOrder },
            values: values
        )
    }

    static func domainValue(from model: EntryValueModel) -> EntryValue {
        if let reason = model.unavailableReason {
            return .unavailable(reason)
        }

        switch TrackerFieldType(rawValue: model.typeRaw) ?? .text {
        case .text:
            return .text(model.textValue ?? "")
        case .selector:
            return .selector(model.textValue ?? "")
        case .number:
            return .number(model.numberValue ?? 0)
        case .date:
            return .date(model.dateValue ?? Date(timeIntervalSince1970: 0))
        case .time:
            guard
                let hour = model.timeHour,
                let minute = model.timeMinute,
                (0...23).contains(hour),
                (0...59).contains(minute)
            else {
                return .unavailable("Invalid time")
            }
            return .time(TimeOfDay(hour: hour, minute: minute))
        }
    }

    static func valueModel(fieldID: FieldID, value: EntryValue) -> EntryValueModel {
        switch value {
        case .text(let text):
            return EntryValueModel(fieldID: fieldID.rawValue, typeRaw: TrackerFieldType.text.rawValue, textValue: text)
        case .selector(let option):
            return EntryValueModel(fieldID: fieldID.rawValue, typeRaw: TrackerFieldType.selector.rawValue, textValue: option)
        case .number(let number):
            return EntryValueModel(fieldID: fieldID.rawValue, typeRaw: TrackerFieldType.number.rawValue, numberValue: number)
        case .date(let date):
            return EntryValueModel(fieldID: fieldID.rawValue, typeRaw: TrackerFieldType.date.rawValue, dateValue: date)
        case .time(let time):
            return EntryValueModel(
                fieldID: fieldID.rawValue,
                typeRaw: TrackerFieldType.time.rawValue,
                timeHour: time.hour,
                timeMinute: time.minute
            )
        case .unavailable(let reason):
            return EntryValueModel(
                fieldID: fieldID.rawValue,
                typeRaw: TrackerFieldType.text.rawValue,
                unavailableReason: reason
            )
        }
    }

    static func fieldDraftSort(_ lhs: TrackerFieldDraft, _ rhs: TrackerFieldDraft) -> Bool {
        if lhs.sortOrder == rhs.sortOrder {
            return lhs.id.rawValue.uuidString < rhs.id.rawValue.uuidString
        }
        return lhs.sortOrder < rhs.sortOrder
    }

    static func fieldSort(_ lhs: TrackerFieldDefinition, _ rhs: TrackerFieldDefinition) -> Bool {
        if lhs.sortOrder == rhs.sortOrder {
            return lhs.id.rawValue.uuidString < rhs.id.rawValue.uuidString
        }
        return lhs.sortOrder < rhs.sortOrder
    }
}

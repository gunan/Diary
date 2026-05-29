import Foundation
import SwiftData

@MainActor
enum TrackerRepositoryError: Error, Equatable {
    case trackerNotFound
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

    func createEntry(trackerID: TrackerID, values: [FieldID: EntryValue]) throws -> TrackerEntry {
        let trackerModel = try requireTrackerModel(id: trackerID)
        let sortedFields = trackerModel.fields.sorted { $0.sortOrder < $1.sortOrder }
        let domainFields = sortedFields.map(Self.domainField(from:))

        for field in domainFields {
            if let value = values[field.id], let error = TrackerValidator.validate(value: value, for: field) {
                throw error
            }
        }

        let entry = EntryModel(createdAt: Date())
        entry.snapshots = domainFields.map {
            FieldSnapshotModel(
                fieldID: $0.id.rawValue,
                name: $0.name,
                typeRaw: $0.type.rawValue,
                sortOrder: $0.sortOrder
            )
        }
        entry.values = values.map { fieldID, value in
            Self.valueModel(fieldID: fieldID, value: value)
        }
        trackerModel.entries.append(entry)
        trackerModel.updatedAt = Date()
        try context.save()
        return Self.domainEntry(from: entry)
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
            fields: model.fields.map(domainField(from:)).sorted { $0.sortOrder < $1.sortOrder },
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

    static func domainEntry(from model: EntryModel) -> TrackerEntry {
        TrackerEntry(
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
            values: Dictionary(uniqueKeysWithValues: model.values.map {
                (FieldID($0.fieldID), domainValue(from: $0))
            })
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
            return .time(TimeOfDay(hour: model.timeHour ?? 0, minute: model.timeMinute ?? 0))
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
}

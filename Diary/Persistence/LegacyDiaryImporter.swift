import Foundation
import SwiftData

@MainActor
enum LegacyDiaryImporter {
    private static let unavailableReason = "Unavailable"

    static func importIfNeeded(in context: ModelContext) throws {
        if try !context.fetch(FetchDescriptor<TrackerModel>()).isEmpty {
            return
        }

        let legacyDiaries = try context.fetch(FetchDescriptor<Diary>())
        for diary in legacyDiaries {
            let tracker = TrackerModel(
                name: diary.name.isEmpty ? "Imported Tracker" : diary.name,
                createdAt: diary.creation_date,
                updatedAt: Date()
            )
            let fields = fieldDefinitions(from: diary)

            tracker.fields = fields
            tracker.entries = diary.getEntries().map { entryModel(from: $0, fields: fields) }
            context.insert(tracker)
        }

        try context.save()
    }

    private static func fieldDefinitions(from diary: Diary) -> [FieldDefinitionModel] {
        diary.getFieldNames().enumerated().map { index, name in
            let legacyField = diary.getFieldDef(name)
            return FieldDefinitionModel(
                fieldID: UUID(),
                name: name,
                typeRaw: mapLegacyFieldType(legacyField?.getType() ?? .custom).rawValue,
                sortOrder: index,
                options: legacyField?.options ?? [],
                minValue: legacyField?.minVal,
                maxValue: legacyField?.maxVal
            )
        }
    }

    private static func entryModel(from legacyEntry: Entry, fields: [FieldDefinitionModel]) -> EntryModel {
        EntryModel(
            createdAt: legacyEntry.date,
            values: fields.map { valueModel(from: legacyEntry, field: $0) },
            snapshots: fields.map {
                FieldSnapshotModel(
                    fieldID: $0.fieldID,
                    name: $0.name,
                    typeRaw: $0.typeRaw,
                    sortOrder: $0.sortOrder
                )
            }
        )
    }

    private static func valueModel(from legacyEntry: Entry, field: FieldDefinitionModel) -> EntryValueModel {
        let type = TrackerFieldType(rawValue: field.typeRaw) ?? .text

        switch type {
        case .number:
            guard let value = legacyEntry.numericFields[field.name] else {
                return unavailableValue(field: field)
            }
            return EntryValueModel(
                fieldID: field.fieldID,
                typeRaw: field.typeRaw,
                numberValue: value
            )
        case .date:
            guard let value = legacyEntry.dateTimeFields[field.name] else {
                return unavailableValue(field: field)
            }
            return EntryValueModel(
                fieldID: field.fieldID,
                typeRaw: field.typeRaw,
                dateValue: value
            )
        case .time:
            guard let value = legacyEntry.dateTimeFields[field.name] else {
                return unavailableValue(field: field)
            }
            let components = Calendar.current.dateComponents([.hour, .minute], from: value)
            guard let hour = components.hour, let minute = components.minute else {
                return unavailableValue(field: field)
            }
            return EntryValueModel(
                fieldID: field.fieldID,
                typeRaw: field.typeRaw,
                timeHour: hour,
                timeMinute: minute
            )
        case .selector, .text:
            return EntryValueModel(
                fieldID: field.fieldID,
                typeRaw: field.typeRaw,
                textValue: legacyEntry.textFields[field.name] ?? ""
            )
        }
    }

    private static func unavailableValue(field: FieldDefinitionModel) -> EntryValueModel {
        EntryValueModel(
            fieldID: field.fieldID,
            typeRaw: field.typeRaw,
            unavailableReason: unavailableReason
        )
    }

    private static func mapLegacyFieldType(_ type: FieldType) -> TrackerFieldType {
        switch type {
        case .custom:
            return .text
        case .selector:
            return .selector
        case .time:
            return .time
        case .date:
            return .date
        case .numeric:
            return .number
        }
    }
}

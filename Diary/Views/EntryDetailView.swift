import SwiftData
import SwiftUI

struct EntryDetailView: View {
    let entry: TrackerEntry

    init(entry: TrackerEntry) {
        self.entry = entry
    }

    init(entry: EntryModel) {
        self.entry = Self.domainEntry(from: entry)
    }

    var body: some View {
        List {
            Section("Entry") {
                LabeledContent("Created", value: entry.createdAt.formatted(date: .abbreviated, time: .shortened))
            }

            Section("Values") {
                ForEach(Array(entry.displayRows().enumerated()), id: \.offset) { _, row in
                    HStack {
                        Text(row.label)
                        Spacer()
                        Text(row.value)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
    }

    private static func domainEntry(from model: EntryModel) -> TrackerEntry {
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
            fieldSnapshots: model.snapshots
                .map {
                    FieldSnapshot(
                        id: FieldID($0.fieldID),
                        name: $0.name,
                        type: TrackerFieldType(rawValue: $0.typeRaw) ?? .text,
                        sortOrder: $0.sortOrder
                    )
                },
            values: values
        )
    }

    private static func domainValue(from model: EntryValueModel) -> EntryValue {
        if let reason = model.unavailableReason {
            return .unavailable(reason)
        }

        switch TrackerFieldType(rawValue: model.typeRaw) ?? .text {
        case .text:
            return .text(model.textValue ?? "")
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
        case .selector:
            return .selector(model.textValue ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        EntryDetailView(
            entry: TrackerEntry(
                id: EntryID(),
                createdAt: Date(),
                fieldSnapshots: [],
                values: [:]
            )
        )
    }
}

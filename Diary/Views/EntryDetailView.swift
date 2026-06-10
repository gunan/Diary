import SwiftData
import SwiftUI

struct EntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let staticEntry: TrackerEntry?
    private let entryModel: EntryModel?
    private let trackerModel: TrackerModel?

    @State private var isShowingEditor = false
    @State private var isShowingDeleteConfirmation = false
    @State private var deleteErrorMessage: String?

    init(entry: TrackerEntry) {
        staticEntry = entry
        entryModel = nil
        trackerModel = nil
    }

    init(entry: EntryModel, tracker: TrackerModel? = nil) {
        staticEntry = nil
        entryModel = entry
        trackerModel = tracker
    }

    private var entry: TrackerEntry {
        if let entryModel {
            return EntryModelMapper.domainEntry(from: entryModel)
        }

        return staticEntry ?? TrackerEntry(id: EntryID(), createdAt: Date(), fieldSnapshots: [], values: [:])
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
        .toolbar {
            if canMutateEntry {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isShowingEditor = true
                        } label: {
                            Label("Edit Entry", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            isShowingDeleteConfirmation = true
                        } label: {
                            Label("Delete Entry", systemImage: "trash")
                        }
                    } label: {
                        Label("Entry Actions", systemImage: "ellipsis.circle")
                    }
                    .accessibilityIdentifier("entry-actions-button")
                }
            }
        }
        .navigationDestination(isPresented: $isShowingEditor) {
            if let trackerModel, let entryModel {
                EntryEditorView(tracker: trackerModel, entry: entryModel)
            }
        }
        .confirmationDialog(
            "Delete Entry?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Entry", role: .destructive) {
                deleteEntry()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Could not delete entry", isPresented: deleteErrorIsPresented) {
            Button("OK", role: .cancel) {
                deleteErrorMessage = nil
            }
        } message: {
            Text(deleteErrorMessage ?? "")
        }
    }

    private var canMutateEntry: Bool {
        entryModel != nil && trackerModel != nil
    }

    private var deleteErrorIsPresented: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    deleteErrorMessage = nil
                }
            }
        )
    }

    private func deleteEntry() {
        guard let entryModel, let trackerModel else { return }

        do {
            try TrackerRepository(context: modelContext).deleteEntry(
                trackerID: TrackerID(trackerModel.trackerID),
                entryID: EntryID(entryModel.entryID)
            )
            dismiss()
        } catch {
            AppLog.persistenceError("Could not delete entry: \(error.localizedDescription)")
            deleteErrorMessage = error.localizedDescription
        }
    }
}

enum EntryModelMapper {
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

    static func domainValue(from model: EntryValueModel) -> EntryValue {
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

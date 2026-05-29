import SwiftData
import SwiftUI

struct TrackerEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let tracker: TrackerModel?

    @State private var trackerName = ""
    @State private var fields: [TrackerFieldDraft] = []
    @State private var fieldEditor: FieldEditorPresentation?
    @State private var validationMessages: [String] = []

    init(tracker: TrackerModel? = nil) {
        self.tracker = tracker
        _trackerName = State(initialValue: tracker?.name ?? "")
        _fields = State(initialValue: tracker?.fields.map(Self.fieldDraft(from:)).sorted(by: Self.fieldDraftSort) ?? [])
    }

    var body: some View {
        Form {
            Section {
                TextField("Tracker Name", text: $trackerName)
                    .textInputAutocapitalization(.words)
                    .accessibilityIdentifier("tracker-name-field")
            }

            Section("Fields") {
                if fields.isEmpty {
                    Text("No fields")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedFields) { field in
                        Button {
                            fieldEditor = FieldEditorPresentation(field: field, sortOrder: field.sortOrder)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(field.name)
                                        .foregroundStyle(.primary)
                                    Text(field.type.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .accessibilityIdentifier("field-row-\(accessibilityName(for: field))")
                    }
                    .onMove(perform: moveFields)
                    .onDelete(perform: deleteFields)
                }

                Button("Add Field") {
                    fieldEditor = FieldEditorPresentation(field: nil, sortOrder: nextSortOrder)
                }
                .accessibilityIdentifier("add-field-button")
            }

            if !validationMessages.isEmpty {
                Section {
                    ForEach(validationMessages, id: \.self) { message in
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle(tracker == nil ? "New Tracker" : "Edit Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveTracker()
                }
                .accessibilityIdentifier("save-tracker-button")
            }

            ToolbarItem(placement: .bottomBar) {
                EditButton()
            }
        }
        .sheet(item: $fieldEditor) { presentation in
            FieldEditorView(field: presentation.field, sortOrder: presentation.sortOrder) { field in
                if let index = fields.firstIndex(where: { $0.id == field.id }) {
                    fields[index] = field
                } else {
                    fields.append(field)
                }
                validationMessages = []
            }
        }
    }

    private var sortedFields: [TrackerFieldDraft] {
        fields.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    private var nextSortOrder: Int {
        (fields.map(\.sortOrder).max() ?? -1) + 1
    }

    private func saveTracker() {
        let draft = TrackerDraft(name: trackerName, fields: sortedFields)
        do {
            let repository = TrackerRepository(context: modelContext)
            if let tracker {
                _ = try repository.updateTracker(id: TrackerID(tracker.trackerID), with: draft)
            } else {
                _ = try repository.createTracker(draft)
            }
            dismiss()
        } catch {
            AppLog.persistenceError("Could not save tracker: \(error.localizedDescription)")
            validationMessages = [localizedDescription(for: error)]
        }
    }

    private func moveFields(from source: IndexSet, to destination: Int) {
        var reorderedFields = sortedFields
        reorderedFields.move(fromOffsets: source, toOffset: destination)
        fields = reorderedFields.enumerated().map { index, field in
            var field = field
            field.sortOrder = index
            return field
        }
    }

    private func deleteFields(at offsets: IndexSet) {
        var remainingFields = sortedFields
        remainingFields.remove(atOffsets: offsets)
        fields = remainingFields.enumerated().map { index, field in
            var field = field
            field.sortOrder = index
            return field
        }
    }

    private func accessibilityName(for field: TrackerFieldDraft) -> String {
        field.name
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    private static func fieldDraft(from model: FieldDefinitionModel) -> TrackerFieldDraft {
        TrackerFieldDraft(
            id: FieldID(model.fieldID),
            name: model.name,
            type: TrackerFieldType(rawValue: model.typeRaw) ?? .text,
            sortOrder: model.sortOrder,
            options: model.options,
            minValue: model.minValue,
            maxValue: model.maxValue
        )
    }

    private static func fieldDraftSort(_ lhs: TrackerFieldDraft, _ rhs: TrackerFieldDraft) -> Bool {
        if lhs.sortOrder == rhs.sortOrder {
            return lhs.id.rawValue.uuidString < rhs.id.rawValue.uuidString
        }
        return lhs.sortOrder < rhs.sortOrder
    }

    private func localizedDescription(for error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }
        return error.localizedDescription
    }
}

private struct FieldEditorPresentation: Identifiable {
    let id = UUID()
    let field: TrackerFieldDraft?
    let sortOrder: Int
}

private extension TrackerFieldType {
    var displayName: String {
        switch self {
        case .text:
            return "Text"
        case .number:
            return "Number"
        case .date:
            return "Date"
        case .time:
            return "Time"
        case .selector:
            return "Selector"
        }
    }
}

#Preview {
    NavigationStack {
        TrackerEditorView()
    }
    .modelContainer(TrackerPreviewData.container)
}

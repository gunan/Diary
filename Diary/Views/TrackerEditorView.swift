import SwiftData
import SwiftUI

struct TrackerEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var trackerName = ""
    @State private var fields: [TrackerFieldDraft] = []
    @State private var fieldEditor: FieldEditorPresentation?
    @State private var validationMessages: [String] = []

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
                        VStack(alignment: .leading, spacing: 4) {
                            Text(field.name)
                            Text(field.type.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button("Add Field") {
                    fieldEditor = FieldEditorPresentation(sortOrder: nextSortOrder)
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
        .navigationTitle("New Tracker")
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
        }
        .sheet(item: $fieldEditor) { presentation in
            FieldEditorView(sortOrder: presentation.sortOrder) { field in
                fields.append(field)
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
            _ = try TrackerRepository(context: modelContext).createTracker(draft)
            dismiss()
        } catch {
            validationMessages = [localizedDescription(for: error)]
        }
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

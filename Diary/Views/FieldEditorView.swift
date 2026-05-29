import SwiftUI

struct FieldEditorView: View {
    let sortOrder: Int
    let onSave: (TrackerFieldDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var fieldID = FieldID()
    @State private var fieldName = ""
    @State private var selectedType: TrackerFieldType = .text
    @State private var selectorOptions = [SelectorOptionDraft(text: "")]
    @State private var validationMessages: [String] = []

    init(
        field: TrackerFieldDraft? = nil,
        sortOrder: Int,
        onSave: @escaping (TrackerFieldDraft) -> Void
    ) {
        self.sortOrder = sortOrder
        self.onSave = onSave
        _fieldID = State(initialValue: field?.id ?? FieldID())
        _fieldName = State(initialValue: field?.name ?? "")
        _selectedType = State(initialValue: field?.type ?? .text)

        let options = field?.options ?? []
        _selectorOptions = State(initialValue: options.isEmpty ? [SelectorOptionDraft(text: "")] : options.map {
            SelectorOptionDraft(text: $0)
        })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Field Name", text: $fieldName)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("field-name-field")
                }

                Section("Type") {
                    ForEach(TrackerFieldType.allCases) { type in
                        Button {
                            selectedType = type
                        } label: {
                            HStack {
                                Text(type.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppBrand.accentColor)
                                }
                            }
                        }
                        .accessibilityIdentifier("field-type-\(type.rawValue)")
                        .accessibilityAddTraits(selectedType == type ? .isSelected : [])
                    }
                }

                if selectedType == .selector {
                    Section("Options") {
                        ForEach($selectorOptions) { $option in
                            TextField("Option", text: $option.text)
                        }

                        Button("Add Option") {
                            selectorOptions.append(SelectorOptionDraft(text: ""))
                        }
                    }
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
            .navigationTitle(fieldName.isEmpty ? "New Field" : "Edit Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveField()
                    }
                    .accessibilityIdentifier("save-field-button")
                }
            }
        }
    }

    private func saveField() {
        let trimmedName = fieldName.trimmingCharacters(in: .whitespacesAndNewlines)
        let options = selectorOptions.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
        let messages = validationMessages(fieldName: trimmedName, options: options)

        guard messages.isEmpty else {
            validationMessages = messages
            return
        }

        onSave(
            TrackerFieldDraft(
                id: fieldID,
                name: trimmedName,
                type: selectedType,
                sortOrder: sortOrder,
                options: selectedType == .selector ? options : []
            )
        )
        dismiss()
    }

    private func validationMessages(fieldName: String, options: [String]) -> [String] {
        var messages: [String] = []

        if fieldName.isEmpty {
            messages.append(TrackerValidationError.emptyFieldName.localizedDescription)
        }

        if selectedType == .selector {
            let messageFieldName = fieldName.isEmpty ? "Selector field" : fieldName
            if options.contains(where: \.isEmpty) {
                messages.append(
                    TrackerValidationError.emptySelectorOption(fieldName: messageFieldName).localizedDescription
                )
            }

            if options.allSatisfy(\.isEmpty) {
                messages.append(
                    TrackerValidationError.selectorWithoutOptions(fieldName: messageFieldName).localizedDescription
                )
            }
        }

        return messages
    }
}

private struct SelectorOptionDraft: Identifiable {
    let id = UUID()
    var text: String
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
    FieldEditorView(sortOrder: 0) { _ in }
}

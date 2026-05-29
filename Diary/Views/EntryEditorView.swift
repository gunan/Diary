import SwiftData
import SwiftUI

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let tracker: TrackerModel

    @State private var textValues: [FieldID: String] = [:]
    @State private var numberValues: [FieldID: String] = [:]
    @State private var dateValues: [FieldID: Date] = [:]
    @State private var timeValues: [FieldID: Date] = [:]
    @State private var selectorValues: [FieldID: String] = [:]
    @State private var validationMessage: String?
    @State private var savedEntry: TrackerEntry?

    private var trackerID: TrackerID {
        TrackerID(tracker.trackerID)
    }

    private var fields: [TrackerFieldDefinition] {
        tracker.fields
            .map {
                TrackerFieldDefinition(
                    id: FieldID($0.fieldID),
                    name: $0.name,
                    type: TrackerFieldType(rawValue: $0.typeRaw) ?? .text,
                    sortOrder: $0.sortOrder,
                    options: $0.options,
                    minValue: $0.minValue,
                    maxValue: $0.maxValue
                )
            }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
                }
                return $0.sortOrder < $1.sortOrder
            }
    }

    var body: some View {
        Form {
            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("entry-validation-message")
                }
            }

            Section("Values") {
                ForEach(fields) { field in
                    fieldControl(for: field)
                }
            }
        }
        .navigationTitle("New Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .accessibilityIdentifier("save-entry-button")
            }
        }
        .onAppear(perform: initializeDefaults)
        .navigationDestination(item: $savedEntry) { entry in
            EntryDetailView(entry: entry)
        }
    }

    @ViewBuilder
    private func fieldControl(for field: TrackerFieldDefinition) -> some View {
        switch field.type {
        case .text:
            TextField(field.name, text: textBinding(for: field.id))
                .accessibilityIdentifier("entry-text-\(accessibilityName(for: field))")
        case .number:
            TextField(field.name, text: numberBinding(for: field.id))
                .keyboardType(.decimalPad)
                .accessibilityIdentifier("entry-number-\(accessibilityName(for: field))")
        case .date:
            DatePicker(field.name, selection: dateBinding(for: field.id), displayedComponents: .date)
        case .time:
            DatePicker(field.name, selection: timeBinding(for: field.id), displayedComponents: .hourAndMinute)
        case .selector:
            Picker(field.name, selection: selectorBinding(for: field)) {
                ForEach(field.options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        }
    }

    private func initializeDefaults() {
        let now = Date()
        for field in fields {
            switch field.type {
            case .date:
                if dateValues[field.id] == nil {
                    dateValues[field.id] = now
                }
            case .time:
                if timeValues[field.id] == nil {
                    timeValues[field.id] = now
                }
            case .selector:
                if selectorValues[field.id] == nil {
                    selectorValues[field.id] = field.options.first ?? ""
                }
            case .text, .number:
                break
            }
        }
    }

    private func save() {
        validationMessage = nil

        do {
            let entry = try TrackerRepository(context: modelContext).createEntry(
                trackerID: trackerID,
                values: entryValues()
            )
            savedEntry = entry
        } catch {
            AppLog.persistenceError("Could not save entry: \(error.localizedDescription)")
            validationMessage = error.localizedDescription
        }
    }

    private func entryValues() throws -> [FieldID: EntryValue] {
        var values: [FieldID: EntryValue] = [:]
        let calendar = Calendar.current

        for field in fields {
            switch field.type {
            case .text:
                let text = textValues[field.id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !text.isEmpty {
                    values[field.id] = .text(text)
                }
            case .number:
                let numberText = numberValues[field.id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !numberText.isEmpty {
                    values[field.id] = try .number(EntryEditorValueNormalizer.numberValue(from: numberText, fieldName: field.name))
                }
            case .date:
                if let date = dateValues[field.id] {
                    values[field.id] = .date(EntryEditorValueNormalizer.dateValue(from: date, calendar: calendar))
                }
            case .time:
                if let date = timeValues[field.id] {
                    let components = calendar.dateComponents([.hour, .minute], from: date)
                    if let hour = components.hour, let minute = components.minute {
                        values[field.id] = .time(TimeOfDay(hour: hour, minute: minute))
                    }
                }
            case .selector:
                let selectedOption = selectorValues[field.id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !selectedOption.isEmpty {
                    values[field.id] = .selector(selectedOption)
                }
            }
        }

        return values
    }

    private func textBinding(for fieldID: FieldID) -> Binding<String> {
        Binding(
            get: { textValues[fieldID] ?? "" },
            set: { textValues[fieldID] = $0 }
        )
    }

    private func numberBinding(for fieldID: FieldID) -> Binding<String> {
        Binding(
            get: { numberValues[fieldID] ?? "" },
            set: { numberValues[fieldID] = $0 }
        )
    }

    private func dateBinding(for fieldID: FieldID) -> Binding<Date> {
        Binding(
            get: { dateValues[fieldID] ?? Date() },
            set: { dateValues[fieldID] = $0 }
        )
    }

    private func timeBinding(for fieldID: FieldID) -> Binding<Date> {
        Binding(
            get: { timeValues[fieldID] ?? Date() },
            set: { timeValues[fieldID] = $0 }
        )
    }

    private func selectorBinding(for field: TrackerFieldDefinition) -> Binding<String> {
        Binding(
            get: { selectorValues[field.id] ?? field.options.first ?? "" },
            set: { selectorValues[field.id] = $0 }
        )
    }

    private func accessibilityName(for field: TrackerFieldDefinition) -> String {
        field.name.lowercased()
    }
}

enum EntryEditorValueNormalizer {
    static func dateValue(from date: Date, calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return utcCalendar.date(from: components) ?? date
    }

    static func numberValue(from text: String, fieldName: String) throws -> Double {
        guard let number = Double(text), number.isFinite else {
            throw EntryEditorError.invalidNumber(fieldName)
        }
        return number
    }
}

enum EntryEditorError: LocalizedError, Equatable {
    case invalidNumber(String)

    var errorDescription: String? {
        switch self {
        case .invalidNumber(let fieldName):
            return "\"\(fieldName)\" needs a valid number."
        }
    }
}

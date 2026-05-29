import Foundation

enum TrackerValidationError: Equatable, LocalizedError {
    case emptyTrackerName
    case emptyFieldName
    case duplicateFieldName(String)
    case emptySelectorOption(fieldName: String)
    case selectorWithoutOptions(fieldName: String)
    case invalidNumberRange(fieldName: String, min: Double, max: Double)
    case wrongValueType(fieldName: String)
    case invalidSelectorOption(fieldName: String, option: String)
    case numberBelowMinimum(fieldName: String, minimum: Double)
    case numberAboveMaximum(fieldName: String, maximum: Double)

    var errorDescription: String? {
        switch self {
        case .emptyTrackerName:
            return "Tracker name is required."
        case .emptyFieldName:
            return "Field name is required."
        case .duplicateFieldName(let name):
            return "\"\(name)\" is already used."
        case .emptySelectorOption(let fieldName):
            return "\"\(fieldName)\" has an empty selector option."
        case .selectorWithoutOptions(let fieldName):
            return "\"\(fieldName)\" needs at least one option."
        case .invalidNumberRange(let fieldName, let min, let max):
            return "\"\(fieldName)\" minimum \(min) cannot be greater than maximum \(max)."
        case .wrongValueType(let fieldName):
            return "\"\(fieldName)\" has an incompatible value."
        case .invalidSelectorOption(let fieldName, let option):
            return "\"\(option)\" is not an option for \"\(fieldName)\"."
        case .numberBelowMinimum(let fieldName, let minimum):
            return "\"\(fieldName)\" must be at least \(minimum)."
        case .numberAboveMaximum(let fieldName, let maximum):
            return "\"\(fieldName)\" must be at most \(maximum)."
        }
    }
}

enum TrackerValidator {
    static func validateTracker(_ draft: TrackerDraft) -> [TrackerValidationError] {
        var errors: [TrackerValidationError] = []
        if draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyTrackerName)
        }

        var seenNames = Set<String>()
        for field in draft.fields {
            let name = field.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty {
                errors.append(.emptyFieldName)
            } else if seenNames.contains(name.lowercased()) {
                errors.append(.duplicateFieldName(name))
            }
            if !name.isEmpty {
                seenNames.insert(name.lowercased())
            }

            if field.type == .selector {
                let normalizedOptions = field.options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                if normalizedOptions.contains(where: { $0.isEmpty }) {
                    errors.append(.emptySelectorOption(fieldName: name))
                }
                if normalizedOptions.allSatisfy(\.isEmpty) {
                    errors.append(.selectorWithoutOptions(fieldName: name))
                }
            }

            if field.type == .number, let minValue = field.minValue, let maxValue = field.maxValue, minValue > maxValue {
                errors.append(.invalidNumberRange(fieldName: name, min: minValue, max: maxValue))
            }
        }
        return errors
    }

    static func validate(value: EntryValue, for field: TrackerFieldDefinition) -> TrackerValidationError? {
        if case .unavailable = value {
            return nil
        }

        switch (field.type, value) {
        case (.text, .text), (.date, .date), (.time, .time), (.selector, .selector), (.number, .number):
            break
        default:
            return .wrongValueType(fieldName: field.name)
        }

        if case .selector(let option) = value {
            let normalizedOption = option.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedOptions = field.options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if !normalizedOptions.contains(normalizedOption) {
                return .invalidSelectorOption(fieldName: field.name, option: option)
            }
        }

        if case .number(let value) = value {
            if let minValue = field.minValue, value < minValue {
                return .numberBelowMinimum(fieldName: field.name, minimum: minValue)
            }
            if let maxValue = field.maxValue, value > maxValue {
                return .numberAboveMaximum(fieldName: field.name, maximum: maxValue)
            }
        }

        return nil
    }
}

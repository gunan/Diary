//
//  Entry.swift
//  Diary
//
//  Created by Günhan Gülsoy on 8/9/25.
//

import Foundation
import SwiftData
import OrderedCollections


@Model
class EntryDef: Codable {
    var schema: OrderedDictionary<String, FieldDef> = [:]
    
    init() {
        self.schema = [:]
    }

    init(schema: OrderedDictionary<String, FieldDef>) {
        self.schema = schema
    }
    
    func addNewField(_ name: String, _ type: FieldType) {
        self.schema[name] = FieldDef(name, type)
    }
    
    func setField(_ name: String, _ fieldDef: FieldDef) {
        self.schema[name] = fieldDef
    }
    
    func deleteField(_ name: String) {
        self.schema.removeValue(forKey: name)
    }
    
    func getFieldNames() -> [String] {
        return Array(self.schema.keys)
    }
    
    func getFieldType(_ name: String) -> FieldType? {
        if self.schema[name] != nil {
            return self.schema[name]?.getType()
        }
        return nil
    }
    
    func getFieldDef(_ name: String) -> FieldDef? {
        return self.schema[name]
    }
    
    enum CodingKeys: String, CodingKey {
        case schema
    }
    
    required init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schema = try container.decode(OrderedDictionary<String, FieldDef>.self, forKey: .schema)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schema, forKey: .schema)
    }
}

@Model
class Entry: Codable {
    var def: EntryDef
    var date: Date
    var dateTimeFields: Dictionary<String, DateComponents> = [:]
    var textFields: Dictionary<String, String> = [:]
    
    init(schema: EntryDef, date: Date, fields: [Any]) {
        self.def = schema
        self.date = date
    }
    
    static func formatDate(_ date: DateComponents) -> String {
        let dateFormatter = DateComponentsFormatter()
        dateFormatter.allowedUnits = [.year, .month, .day]
        dateFormatter.zeroFormattingBehavior = .dropAll
        
        if let formattedDate = dateFormatter.string(from: date) {
            return formattedDate;
        } else {
            return "";
        }
    }
    
    static func formatTime(_ date: DateComponents) -> String {
        let dateFormatter = DateComponentsFormatter()
        dateFormatter.allowedUnits = [.hour, .minute]
        dateFormatter.zeroFormattingBehavior = .dropAll
        
        if let formattedTime = dateFormatter.string(from: date) {
            return formattedTime;
        } else {
            return "";
        }
    }
    
    func getDate() -> Date {
        return self.date
    }
    
    func getSchema() -> EntryDef {
        return self.def
    }
    
    func setField(name: String, value: Any) {
        if self.def.getFieldType(name)!.isDateTime() {
            self.dateTimeFields[name] = value as? DateComponents
        } else {
            self.textFields[name] = value as? String ?? ""
        }
    }
    
    func setDateField(name: String, value: DateComponents) {
        if self.def.getFieldType(name)!.isDateTime() {
            self.dateTimeFields[name] = value as DateComponents
        }
    }
    
    func setDateField(name: String, value: Date) {
        if self.def.getFieldType(name)!.isDateTime() {
            if self.def.getFieldType(name) == FieldType.date {
                self.dateTimeFields[name] = Calendar.current.dateComponents([.year, .month, .day], from: value);
            } else if self.def.getFieldType(name) == FieldType.time {
                self.dateTimeFields[name] = Calendar.current.dateComponents([.hour, .minute], from: value);
            }
        }
    }
    
    func getDateField(_ name: String) -> DateComponents? {
        if self.def.getFieldType(name)!.isDateTime() {
            return self.dateTimeFields[name]
        } else {
            return nil
        }
    }
    
    func getField(name: String) -> Any {
        if self.def.getFieldType(name)!.isDateTime() {
            return self.dateTimeFields[name] as Any;
        } else {
            return self.textFields[name] as Any;
        }
    }
    
    func getFieldAsString(_ name: String) -> String {
        if self.def.getFieldType(name) == nil {
            return "Invalid Field";
        } else {
            if self.def.getFieldType(name) == FieldType.date {
                return Entry.formatDate(self.dateTimeFields[name] ?? DateComponents(year: 1970, month: 1, day: 1));
            } else if self.def.getFieldType(name) == FieldType.time {
                return Entry.formatTime(self.dateTimeFields[name] ?? DateComponents(hour: 0, minute: 0));
            } else {
                return self.textFields[name] ?? "" as String;
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case def
        case date
        case dateTimeFields
        case textFields
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.def = try container.decode(EntryDef.self, forKey: .def)
        self.date = try container.decode(Date.self, forKey: .date)
        self.dateTimeFields = try container.decode(Dictionary.self, forKey: .dateTimeFields)
        self.textFields = try container.decode(Dictionary.self, forKey: .textFields)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(def, forKey: .def)
        try container.encode(date, forKey: .date)
        try container.encode(dateTimeFields, forKey: .dateTimeFields)
        try container.encode(textFields, forKey: .textFields)
    }
}

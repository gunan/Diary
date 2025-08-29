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
    var dateTimeFields: Dictionary<String, Date> = [:]
    var textFields: Dictionary<String, String> = [:]
    
    static var dateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    static var timeFormatter: DateFormatter = {
        var timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter
    }()
    
    init(schema: EntryDef, date: Date, fields: [Any]) {
        self.def = schema
        self.date = date
    }
    
    static func formatDate(_ date: Date?) -> String {
        if date == nil {
            return ""
        } else {
            return dateFormatter.string(from: date!);
        }
    }
    
    static func formatTime(_ date: Date?) -> String {
        if date == nil {
            return ""
        } else {
            return timeFormatter.string(from: date!);
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
            self.dateTimeFields[name] = value as? Date
        } else {
            self.textFields[name] = value as? String ?? ""
        }
    }
    
    func setDateField(name: String, value: Date) {
        if self.def.getFieldType(name)!.isDateTime() {
            self.dateTimeFields[name] = value
        }
    }
    
    func getDateField(_ name: String) -> Date? {
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
                return Entry.formatDate(self.dateTimeFields[name]);
            } else if self.def.getFieldType(name) == FieldType.time {
                return Entry.formatTime(self.dateTimeFields[name]);
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

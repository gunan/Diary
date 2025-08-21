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
    var fields: [String]
    
    init(schema: EntryDef, date: Date, fields: [Any]) {
        self.def = schema
        self.date = date
        self.fields = fields.map {String (describing: $0)}
    }
    
    func getDate() -> Date {
        return self.date
    }
    
    func getSchema() -> EntryDef {
        return self.def
    }
    
    func getFieldDict() -> OrderedDictionary<String, Any> {
        let fieldNames = self.def.getFieldNames()
        return OrderedDictionary<String, Any> (
            uniqueKeysWithValues: zip(fieldNames, self.fields.indices.map { self.fields[$0] }))
    }
    
    func getFields() -> [Any] {
        return self.fields
    }
    
    func setFields(values: [Any]) {
        self.fields = values.map { String(describing: $0) }
    }
    
    enum CodingKeys: String, CodingKey {
        case def
        case date
        case fields
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.def = try container.decode(EntryDef.self, forKey: .def)
        self.date = try container.decode(Date.self, forKey: .date)
        self.fields = try container.decode([String].self, forKey: .fields)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(def, forKey: .def)
        try container.encode(date, forKey: .date)
        try container.encode(fields, forKey: .fields)
    }
}

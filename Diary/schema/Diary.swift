//
//  Diary.swift
//  Diary
//
//  Created by Günhan Gülsoy on 8/9/25.
//

import Foundation
import SwiftData

@Model
class Diary: Codable {
    var creation_date: Date
    var name: String
    var schema: EntryDef
    
    @Relationship(deleteRule: .cascade)
    var entries: [Entry] = []
    
    init(name: String, schema: EntryDef) {
        self.creation_date = Date()
        self.name = name
        self.schema = schema
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case schema
        case entries
        case creation_date
    }
    
    init () {
        self.creation_date = Date()
        self.name = ""
        self.schema = EntryDef()
        self.entries = []
    }
    
    func addEntry(_ date: Date, _ fields: Dictionary<String, Any>) {
        self.entries.append(Entry(schema: self.schema, date: date, fields: fields))
    }
    
    func addEntry(_ entry: Entry) {
        self.entries.append(entry)
    }
    
    func getEntries() -> [Entry] {
        return self.entries.sorted { $0.date > $1.date }
    }
    
    func getFieldNames() -> [String] {
        return self.schema.getFieldNames()
    }
    
    func getFieldDef(_ fieldName: String) -> FieldDef? {
        return self.schema.getFieldDef(fieldName)
    }
    
    func getSchema() -> EntryDef {
        return self.schema
    }
    
    required init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.schema = try container.decode(EntryDef.self, forKey: .schema)
        self.entries = try container.decode([Entry].self, forKey: .entries)
        self.creation_date = try container.decode(Date.self, forKey: .creation_date)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(schema, forKey: .schema)
        try container.encode(entries, forKey: .entries)
        try container.encode(creation_date, forKey: .creation_date)
    }
    
    func newEntry() -> Entry {
        return Entry(schema: self.schema, date: Date(), fields: [:])
    }
}

extension Diary {
    static func sampleData() -> Diary {
        let entryDef: EntryDef = EntryDef()
        entryDef.addNewField("Title", FieldType.custom)
        entryDef.addNewField("Summary", FieldType.custom)
        entryDef.addNewField("date", FieldType.date)
        
        
        var selectorField: FieldDef = FieldDef("tags", FieldType.selector)
        selectorField.setOptions(["medicine", "work", "personal"])
        entryDef.setField("tags", selectorField)
        
        entryDef.addNewField("time", FieldType.time)
        
        var diary: Diary =  Diary(name: "Sample Diary", schema: entryDef)

        let fixedFormatter = DateFormatter()
        fixedFormatter.locale = Locale(identifier: "en_US_POSIX")
        fixedFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        fixedFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        timeFormatter.dateFormat = "HH:mm:ss"
        
        diary.addEntry(
            fixedFormatter.date(from: "2024-12-14")!,
            ["Title": "Hello",
             "Summary":" World",
             "date": Calendar.current.date(from:DateComponents(year: 2024, month: 12, day: 14)),
             "tags": "medicine",
             "time": Calendar.current.date(from:DateComponents(hour: 4, minute: 30))])
        diary.addEntry(
            fixedFormatter.date(from: "2024-12-15")!,
            ["Title": "Hello",
             "Summary":" World",
             "date": Calendar.current.date(from:DateComponents.init(year: 2024, month: 12, day: 15)),
             "tags": "work",
             "time": Calendar.current.date(from:DateComponents(hour: 6, minute: 30))])
        
        return diary
    }
}

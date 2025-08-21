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
    var name: String
    var schema: EntryDef
    var entries: [Entry] = []
    
    init(name: String, schema: EntryDef) {
        self.name = name
        self.schema = schema
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case schema
        case entries
    }
    
    init () {
        self.name = ""
        self.schema = EntryDef()
        self.entries = []
    }
    
    func addEntry(_ date: Date, _ fields: [Any]) {
        self.entries.append(Entry(schema: self.schema, date: date, fields: fields))
    }
    
    func getEntries() -> [Entry] {
        return self.entries
    }
    
    func getFieldNames() -> [String] {
        return self.schema.getFieldNames()
    }
    
    func getFieldDef(_ fieldName: String) -> FieldDef? {
        return self.schema.getFieldDef(fieldName)
    }
    
    required init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.schema = try container.decode(EntryDef.self, forKey: .schema)
        self.entries = try container.decode([Entry].self, forKey: .entries)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(schema, forKey: .schema)
        try container.encode(entries, forKey: .entries)
    }
}

extension Diary {
    static func sampleData() -> Diary {
        let entryDef: EntryDef = EntryDef()
        entryDef.addNewField("Title", FieldType.custom)
        entryDef.addNewField("Summary", FieldType.custom)
        
        var diary: Diary =  Diary(name: "Sample Diary", schema: entryDef)
        
        let isoDate = "2024-12-14T04:30:00+05:30"

        let fixedFormatter = DateFormatter()
        fixedFormatter.locale = Locale(identifier: "en_US_POSIX")
        fixedFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        fixedFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        diary.addEntry(fixedFormatter.date(from: "2024-12-14T04:30:00+05:30")!, ["Hello", "World"])
        diary.addEntry(fixedFormatter.date(from: "2024-12-15T04:30:00+05:30")!, ["Hello", "World"])
        
        return diary
    }
}

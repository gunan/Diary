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

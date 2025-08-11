//
//  Field.swift
//  Diary
//
//  Created by Günhan Gülsoy on 8/9/25.
//
import Foundation
import SwiftData


enum FieldType: CaseIterable, Identifiable {
    case custom
    case selector
    case time
    case date
    
    static func fromint(_ val: Int) -> FieldType {
        switch val {
        case 0:
            return .custom
        case 1:
            return .selector
        case 2:
            return .time
        case 3:
            return .date
        default:
            return .custom
        }
    }
    
    var id: Self { self }
    
    func toInt() -> Int {
        switch self {
        case .custom:
            return 0
        case .selector:
            return 1
        case .time:
            return 2
        case .date:
            return 3
        }
    }
    
    static func types() -> [String] {
        return ["custom", "selector", "time", "date"]
    }
    
    func toString() -> String {
        return FieldType.toString(self.toInt())
    }
    
    static func toString(_ val: Int) -> String {
        return FieldType.types()[val]
    }
    
    func isSelector() -> Bool {
        return self == .selector
    }
    
    static func isSelector(_ val: Int) -> Bool {
        return FieldType.fromint(val) == .selector
    }
}

@Model
class FieldDef: Codable {
    var name: String
    var type: Int = 0
    var options: [String] = []
    
    enum CodingKeys: String, CodingKey {
        case name
        case type
        case options
    }
    
    init(_ from: FieldDef) {
        self.name = from.name
        self.type = from.type
        self.options = from.options
    }
    
    init(_ name: String, _ fieldType: FieldType = FieldType.custom) {
        self.name = name
        self.type = fieldType.toInt()
    }
    
    required init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decode(Int.self, forKey: .type)
        self.options = try container.decode([String].self, forKey: .options)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(options, forKey: .options)
    }
    
    func getName() -> String {
        return self.name
    }
    
    func getType() -> FieldType {
        return FieldType.fromint(self.type)
    }
    
    func setName(_ name: String) {
        self.name = name
    }
    
    func setType(_ type: FieldType) {
        self.type = type.toInt()
    }
    
    func setOptions(_ options: [String]) {
        self.options = options
    }
    
    func getOptions() -> [String] {
        return self.options
    }
}


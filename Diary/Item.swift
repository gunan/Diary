//
//  Item.swift
//  Diary
//
//  Created by Günhan Gülsoy on 8/9/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

//
//  ShowEntryView.swift
//  Diary
//
//  Created by Günhan Gülsoy on 8/20/25.
//


import SwiftUI
import SwiftData
import OrderedCollections

struct ShowEntryView: View {
    @Bindable var entry: Entry
    
    let fields: OrderedDictionary<String, Any>
    let defaultValue: String = "No Value"
    
    init(entry: Entry) {
        self.entry = entry
        self.fields = entry.getFieldDict()
    }
    
    var body: some View {
        List {
            ForEach(fields.keys, id: \.self) { key in
                Section {
                    Text(key).bold()
                    Text("\(fields[key] ?? defaultValue)")
                }
            }
            
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(entry.getDate().ISO8601Format())
    }
}

#Preview {
    ShowEntryView(entry: Diary.sampleData().entries[0])
}

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
    
    let defaultValue: String = "No Value"
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(entry.def.getFieldNames(), id: \.self) { key in
                    Section {
                        Text(key).bold()
                        Text("\(entry.getFieldAsString(key))")
                    }
                }
                
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(entry.getDate().ISO8601Format())
        }
    }
}

#Preview {
    ShowEntryView(entry: Diary.sampleData().entries[0])
}

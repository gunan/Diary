//
//  ShowDiaryView.swift
//  Diary
//
//  Created by Günhan Gülsoy on 8/12/25.
//


import SwiftUI
import SwiftData

struct ShowDiaryView: View {
    @Bindable var diary: Diary
    
    // TODO add reminder function for the diary,
    // set a list of reminders for each day to send.

    var body: some View {
        List {
            Button(action: {
            }) {
                Text("Create New Entry")
            }
            
            Section(header: Text("Entries")) {
                ForEach(diary.getEntries(), id: \.self) { entry in
                    NavigationLink {
                        ShowEntryView(entry: entry)
                    } label: {
                        Text((entry.getDate().ISO8601Format()))
                    }
                    }
                }
            }
        .navigationTitle($diary.name)
        .listStyle(InsetGroupedListStyle())
    }
}

#Preview {
    ShowDiaryView(diary: Diary.sampleData())
}


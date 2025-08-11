//
//  DiaryListView.swift
//  Diary
//
//  Created by Günhan Gülsoy on 8/10/25.
//
import SwiftUI
import SwiftData

struct DiaryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var diaries: [Diary] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(diaries) { diary in
                    Text(diary.name)
                }.onTapGesture {
                    // TODO
                }
                
                NavigationLink("Add New Diary") {
                    CreateDiaryView()
                }
            }
            .navigationTitle("All Your Diaries")
        }
    }
}

#Preview {
    DiaryListView()
        .modelContainer(for: Diary.self, inMemory: true)
}
    

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
    @Query(sort: \Diary.creation_date) private var diaries: [Diary] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(diaries) { diary in
                        NavigationLink {
                            ShowDiaryView(diary: diary)
                        } label: {
                            Text(diary.name)
                        }
                    }
                }
                
                NavigationLink("Add New Diary") {
                    CreateDiaryView()
                }
                .buttonStyle(.borderedProminent)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("All Your Diaries")
        }
    }
}

#Preview {
    DiaryListView()
        .modelContainer(SampleDiaryList.shared.modelContainer)
}
    

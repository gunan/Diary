//
//  DiaryApp.swift
//  Diary
//
//  Created by Günhan Gülsoy on 8/9/25.
//

import SwiftUI
import SwiftData

@main
struct DiaryApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Diary.self,
            EntryDef.self,
            Entry.self,
            FieldDef.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            CreateDiaryView()
        }
        .modelContainer(sharedModelContainer)
    }
}

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
    var sharedModelContainer: ModelContainer = ModelContainerFactory.makeModelContainer()

    var body: some Scene {
        WindowGroup {
            DiaryListView()
        }
        .modelContainer(sharedModelContainer)
    }
}

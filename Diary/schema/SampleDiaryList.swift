//
//  SampleDiaryList.swift
//  Diary
//
//  Created by Günhan Gülsoy on 8/20/25.
//

import Foundation
import SwiftData


@MainActor
class SampleDiaryList {
    static let shared = SampleDiaryList()


    let modelContainer: ModelContainer


    var context: ModelContext {
        modelContainer.mainContext
    }


    private init() {
        let schema = Schema([
            Diary.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)


        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])


            insertSampleData()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }


    private func insertSampleData() {
        context.insert(Diary.sampleData())
    }
}

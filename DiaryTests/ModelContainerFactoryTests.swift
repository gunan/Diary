import Foundation
import SwiftData
import Testing
@testable import Diary

@MainActor
struct ModelContainerFactoryTests {
    @Test func modelContainerContinuesWhenLegacyImportFails() throws {
        let container = ModelContainerFactory.makeModelContainer(
            isStoredInMemoryOnly: true,
            importLegacyData: { _ in throw ImportProbeError.failed }
        )
        let context = container.mainContext

        context.insert(TrackerModel(name: "Still Usable"))
        try context.save()

        let trackers: [TrackerModel] = try context.fetch(FetchDescriptor<TrackerModel>())
        #expect(trackers.map { $0.name } == ["Still Usable"])
    }

    private enum ImportProbeError: Error {
        case failed
    }
}

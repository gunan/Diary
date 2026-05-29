import SwiftData
import SwiftUI

struct TrackerListView: View {
    @Query(sort: \TrackerModel.createdAt, order: .reverse) private var trackers: [TrackerModel]

    var body: some View {
        NavigationStack {
            Group {
                if trackers.isEmpty {
                    ContentUnavailableView(
                        AppBrand.emptyTitle,
                        systemImage: "list.bullet.rectangle",
                        description: Text(AppBrand.emptyMessage)
                    )
                } else {
                    List(trackers) { tracker in
                        NavigationLink {
                            TrackerDetailView(trackerID: TrackerID(tracker.trackerID))
                        } label: {
                            TrackerRow(tracker: tracker)
                        }
                        .accessibilityIdentifier("tracker-row-\(tracker.trackerID.uuidString)")
                    }
                }
            }
            .navigationTitle("Trackers")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        TrackerEditorView()
                    } label: {
                        Label("New Tracker", systemImage: "plus")
                    }
                    .accessibilityIdentifier("new-tracker-button")
                }
            }
        }
        .tint(AppBrand.accentColor)
    }
}

private struct TrackerRow: View {
    let tracker: TrackerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tracker.name)
                .font(.headline)

            Text(fieldCountText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var fieldCountText: String {
        let count = tracker.fields.count
        return count == 1 ? "1 field" : "\(count) fields"
    }
}

#Preview {
    TrackerListView()
        .modelContainer(TrackerPreviewData.container)
}

@MainActor
enum TrackerPreviewData {
    static let trackerID = TrackerID(UUID(uuidString: "7B7F0DE6-6F23-43C7-93AE-9173AFAE9B7E")!)

    static let container: ModelContainer = {
        do {
            let container = try ModelContainerFactory.makeTestingContainer()
            let context = container.mainContext
            let moodFieldID = UUID(uuidString: "2C3B5C3E-B98E-4BB7-A5F4-91CC99A76D4C")!
            let noteFieldID = UUID(uuidString: "FD8D29E6-76D1-493D-8EDB-633D52B4070F")!
            let tracker = TrackerModel(
                trackerID: trackerID.rawValue,
                name: "Mood Tracker",
                createdAt: Date(timeIntervalSince1970: 1_724_000_000),
                updatedAt: Date(timeIntervalSince1970: 1_724_003_600),
                fields: [
                    FieldDefinitionModel(
                        fieldID: moodFieldID,
                        name: "Mood",
                        typeRaw: TrackerFieldType.selector.rawValue,
                        sortOrder: 0,
                        options: ["Calm", "Focused", "Tired"]
                    ),
                    FieldDefinitionModel(
                        fieldID: noteFieldID,
                        name: "Note",
                        typeRaw: TrackerFieldType.text.rawValue,
                        sortOrder: 1
                    ),
                ],
                entries: [
                    EntryModel(
                        createdAt: Date(timeIntervalSince1970: 1_724_003_600),
                        values: [
                            EntryValueModel(
                                fieldID: moodFieldID,
                                typeRaw: TrackerFieldType.selector.rawValue,
                                textValue: "Focused"
                            ),
                            EntryValueModel(
                                fieldID: noteFieldID,
                                typeRaw: TrackerFieldType.text.rawValue,
                                textValue: "Planning the day"
                            ),
                        ],
                        snapshots: [
                            FieldSnapshotModel(
                                fieldID: moodFieldID,
                                name: "Mood",
                                typeRaw: TrackerFieldType.selector.rawValue,
                                sortOrder: 0
                            ),
                            FieldSnapshotModel(
                                fieldID: noteFieldID,
                                name: "Note",
                                typeRaw: TrackerFieldType.text.rawValue,
                                sortOrder: 1
                            ),
                        ]
                    ),
                ]
            )

            context.insert(tracker)
            try context.save()
            return container
        } catch {
            fatalError("Could not create tracker preview container: \(error)")
        }
    }()
}

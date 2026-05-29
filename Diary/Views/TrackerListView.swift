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

struct TrackerEditorView: View {
    var body: some View {
        ContentUnavailableView(
            "New tracker editor",
            systemImage: "plus.square.on.square",
            description: Text("Tracker creation will be added in the next task.")
        )
        .navigationTitle("New Tracker")
    }
}

#Preview {
    TrackerListView()
        .modelContainer(SampleDiaryList.shared.modelContainer)
}

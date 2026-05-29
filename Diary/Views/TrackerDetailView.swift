import SwiftData
import SwiftUI

struct TrackerDetailView: View {
    let trackerID: TrackerID

    @Query private var trackers: [TrackerModel]

    init(trackerID: TrackerID) {
        self.trackerID = trackerID
        let rawTrackerID = trackerID.rawValue
        _trackers = Query(filter: #Predicate<TrackerModel> { tracker in
            tracker.trackerID == rawTrackerID
        })
    }

    var body: some View {
        Group {
            if let tracker {
                TrackerDetailContent(tracker: tracker)
            } else {
                ContentUnavailableView(
                    "Tracker unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This tracker could not be found.")
                )
            }
        }
        .navigationTitle(tracker?.name ?? "Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppBrand.accentColor)
    }

    private var tracker: TrackerModel? {
        trackers.first
    }
}

private struct TrackerDetailContent: View {
    let tracker: TrackerModel

    @State private var isShowingEntryEditor = false

    private var sortedFields: [FieldDefinitionModel] {
        tracker.fields.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.name < $1.name
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    private var recentEntries: [EntryModel] {
        tracker.entries.sorted { $0.createdAt > $1.createdAt }.prefix(5).map { $0 }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Button {
                        isShowingEntryEditor = true
                    } label: {
                        Label("New Entry", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("new-entry-button")

                    NavigationLink {
                        TrackerChartsView(tracker: tracker)
                    } label: {
                        Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("insights-button")
                }
                .controlSize(.large)
            }

            Section("Summary") {
                LabeledContent("Fields", value: "\(tracker.fields.count)")
                LabeledContent("Entries", value: "\(tracker.entries.count)")
            }

            if sortedFields.isEmpty {
                Section("Fields") {
                    Text("Add fields to define what this tracker captures.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Fields") {
                    ForEach(sortedFields) { field in
                        LabeledContent(field.name, value: field.typeRaw.capitalized)
                    }
                }
            }

            if recentEntries.isEmpty {
                Section("Recent Entries") {
                    Text("No entries yet.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Recent Entries") {
                    ForEach(recentEntries) { entry in
                        NavigationLink {
                            EntryDetailView(entry: entry)
                        } label: {
                            Text(entry.createdAt, format: .dateTime.month().day().year().hour().minute())
                        }
                    }
                }
            }
        }
        .navigationDestination(isPresented: $isShowingEntryEditor) {
            EntryEditorView(tracker: tracker)
        }
    }
}

private struct TrackerPlaceholderDestination: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(message)
        )
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TrackerDetailView(trackerID: TrackerPreviewData.trackerID)
    }
    .modelContainer(TrackerPreviewData.container)
}

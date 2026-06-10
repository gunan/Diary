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
        .toolbar {
            if let tracker {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        TrackerEditorView(tracker: tracker)
                    } label: {
                        Label("Edit Tracker", systemImage: "pencil")
                    }
                    .accessibilityIdentifier("edit-tracker-button")
                }
            }
        }
    }

    private var tracker: TrackerModel? {
        trackers.first
    }
}

private struct TrackerDetailContent: View {
    @Environment(\.modelContext) private var modelContext

    let tracker: TrackerModel

    @State private var isShowingEntryEditor = false
    @State private var entryBeingEdited: EntryModel?
    @State private var entryDeleteError: String?

    private var sortedFields: [FieldDefinitionModel] {
        tracker.fields.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.name < $1.name
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    private var entries: [EntryModel] {
        tracker.entries.sorted { $0.createdAt > $1.createdAt }
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

            if entries.isEmpty {
                Section("Entries") {
                    Text("No entries yet.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Entries") {
                    ForEach(entries) { entry in
                        NavigationLink {
                            EntryDetailView(entry: entry, tracker: tracker)
                        } label: {
                            EntryRow(entry: entry)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                delete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                entryBeingEdited = entry
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(AppBrand.accentColor)
                        }
                        .accessibilityIdentifier("entry-row")
                        .accessibilityLabel(EntryRow.accessibilityLabel(for: entry))
                    }
                }
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
        }
        .navigationDestination(isPresented: $isShowingEntryEditor) {
            EntryEditorView(tracker: tracker)
        }
        .navigationDestination(item: $entryBeingEdited) { entry in
            EntryEditorView(tracker: tracker, entry: entry)
        }
        .alert("Could not delete entry", isPresented: deleteErrorIsPresented) {
            Button("OK", role: .cancel) {
                entryDeleteError = nil
            }
        } message: {
            Text(entryDeleteError ?? "")
        }
    }

    private var deleteErrorIsPresented: Binding<Bool> {
        Binding(
            get: { entryDeleteError != nil },
            set: { isPresented in
                if !isPresented {
                    entryDeleteError = nil
                }
            }
        )
    }

    private func delete(_ entry: EntryModel) {
        do {
            try TrackerRepository(context: modelContext).deleteEntry(
                trackerID: TrackerID(tracker.trackerID),
                entryID: EntryID(entry.entryID)
            )
        } catch {
            AppLog.persistenceError("Could not delete entry: \(error.localizedDescription)")
            entryDeleteError = error.localizedDescription
        }
    }
}

private struct EntryRow: View {
    let entry: EntryModel

    private var domainEntry: TrackerEntry {
        EntryModelMapper.domainEntry(from: entry)
    }

    private var summary: String? {
        Self.summary(for: domainEntry)
    }

    static func accessibilityLabel(for entry: EntryModel) -> String {
        let domainEntry = EntryModelMapper.domainEntry(from: entry)
        let createdAt = entry.createdAt.formatted(date: .abbreviated, time: .shortened)
        guard let summary = summary(for: domainEntry) else {
            return createdAt
        }

        return "\(createdAt), \(summary)"
    }

    private static func summary(for entry: TrackerEntry) -> String? {
        let rows = entry.displayRows()
            .filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { "\($0.label): \($0.value)" }

        guard !rows.isEmpty else { return nil }
        return rows.joined(separator: " | ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.createdAt, format: .dateTime.month().day().year().hour().minute())
                .font(.headline)

            if let summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
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

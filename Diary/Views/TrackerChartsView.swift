import Charts
import SwiftUI

struct TrackerChartsView: View {
    let tracker: TrackerModel

    @State private var selectedFieldIDs: Set<FieldID>
    @State private var period: TrackerChartPeriod = .last30Days
    @State private var bucket: TrackerChartBucket = .day
    @State private var chartStyle: TrackerChartStyle = .line
    @State private var now = Date()

    init(tracker: TrackerModel) {
        self.tracker = tracker

        let domainTracker = Self.domainTracker(from: tracker)
        let compatibleFields = TrackerChartAggregator.compatibleFields(domainTracker.fields)
        _selectedFieldIDs = State(initialValue: Set(compatibleFields.map(\.id)))
    }

    private var domainTracker: Tracker {
        Self.domainTracker(from: tracker)
    }

    private var compatibleFields: [TrackerFieldDefinition] {
        TrackerChartAggregator.compatibleFields(domainTracker.fields)
    }

    private var compatibleFieldIDs: Set<FieldID> {
        Set(compatibleFields.map(\.id))
    }

    private var chartPoints: [TrackerChartPoint] {
        TrackerChartAggregator.points(
            entries: domainTracker.entries,
            fields: domainTracker.fields,
            selectedFieldIDs: selectedFieldIDs,
            period: period,
            bucket: bucket,
            calendar: .current,
            now: now
        )
    }

    private var markUnit: Calendar.Component {
        switch bucket {
        case .day:
            return .day
        case .week:
            return .weekOfYear
        case .month:
            return .month
        }
    }

    var body: some View {
        List {
            if compatibleFields.isEmpty {
                emptyNumericFieldsSection
            } else {
                fieldSelectionSection
                controlsSection
                chartSection
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppBrand.accentColor)
        .onAppear {
            now = Date()
            reconcileSelection()
        }
        .onChange(of: compatibleFieldIDs) { _, _ in
            reconcileSelection()
        }
    }

    private var emptyNumericFieldsSection: some View {
        Section {
            ContentUnavailableView(
                "No chartable fields",
                systemImage: "number",
                description: Text("Add a number field to chart tracker trends.")
            )
        }
    }

    private var fieldSelectionSection: some View {
        Section("Fields") {
            ForEach(compatibleFields) { field in
                Toggle(field.name, isOn: fieldBinding(for: field))
                    .accessibilityIdentifier(accessibilityIdentifier(for: field))
            }
        }
    }

    private var controlsSection: some View {
        Section("Options") {
            Picker("Period", selection: $period) {
                ForEach(TrackerChartPeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .accessibilityIdentifier("chart-period-picker")

            Picker("Bucket", selection: $bucket) {
                ForEach(TrackerChartBucket.allCases) { bucket in
                    Text(bucket.rawValue).tag(bucket)
                }
            }
            .accessibilityIdentifier("chart-bucket-picker")

            Picker("Style", selection: $chartStyle) {
                ForEach(TrackerChartStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .accessibilityIdentifier("chart-style-picker")
        }
    }

    private var chartSection: some View {
        Section("Chart") {
            if chartPoints.isEmpty {
                ContentUnavailableView(
                    "No chart data",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Select a field with entries in this period.")
                )
                .frame(minHeight: 220)
            } else {
                chart
                    .frame(minHeight: 280)
                    .chartLegend(position: .bottom, alignment: .leading)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5))
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .accessibilityIdentifier("tracker-chart")
            }
        }
    }

    @ViewBuilder
    private var chart: some View {
        switch chartStyle {
        case .bar:
            Chart(chartPoints) { point in
                BarMark(
                    x: .value("Date", point.date, unit: markUnit),
                    y: .value("Average", point.value)
                )
                .foregroundStyle(by: .value("Field", point.fieldName))
                .position(by: .value("Field", point.fieldName))
            }
        case .line:
            Chart(chartPoints) { point in
                LineMark(
                    x: .value("Date", point.date, unit: markUnit),
                    y: .value("Average", point.value)
                )
                .foregroundStyle(by: .value("Field", point.fieldName))
                .symbol(by: .value("Field", point.fieldName))

                PointMark(
                    x: .value("Date", point.date, unit: markUnit),
                    y: .value("Average", point.value)
                )
                .foregroundStyle(by: .value("Field", point.fieldName))
                .symbol(by: .value("Field", point.fieldName))
            }
        case .scatter:
            Chart(chartPoints) { point in
                PointMark(
                    x: .value("Date", point.date, unit: markUnit),
                    y: .value("Average", point.value)
                )
                .foregroundStyle(by: .value("Field", point.fieldName))
                .symbol(by: .value("Field", point.fieldName))
            }
        }
    }

    private func fieldBinding(for field: TrackerFieldDefinition) -> Binding<Bool> {
        Binding(
            get: {
                selectedFieldIDs.contains(field.id)
            },
            set: { isSelected in
                if isSelected {
                    selectedFieldIDs.insert(field.id)
                } else {
                    selectedFieldIDs.remove(field.id)
                }
            }
        )
    }

    private func reconcileSelection() {
        selectedFieldIDs.formIntersection(compatibleFieldIDs)

        if selectedFieldIDs.isEmpty, let firstField = compatibleFields.first {
            selectedFieldIDs.insert(firstField.id)
        }
    }

    private func accessibilityIdentifier(for field: TrackerFieldDefinition) -> String {
        "chart-field-\(field.name.lowercased())"
    }

    private static func domainTracker(from model: TrackerModel) -> Tracker {
        Tracker(
            id: TrackerID(model.trackerID),
            name: model.name,
            fields: model.fields.map(domainField(from:)).sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return lhs.id.rawValue.uuidString < rhs.id.rawValue.uuidString
                }
                return lhs.sortOrder < rhs.sortOrder
            },
            entries: model.entries.map(domainEntry(from:)).sorted { $0.createdAt > $1.createdAt },
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }

    private static func domainField(from model: FieldDefinitionModel) -> TrackerFieldDefinition {
        TrackerFieldDefinition(
            id: FieldID(model.fieldID),
            name: model.name,
            type: TrackerFieldType(rawValue: model.typeRaw) ?? .text,
            sortOrder: model.sortOrder,
            options: model.options,
            minValue: model.minValue,
            maxValue: model.maxValue
        )
    }

    private static func domainEntry(from model: EntryModel) -> TrackerEntry {
        let values = model.values
            .sorted { $0.valueID.uuidString < $1.valueID.uuidString }
            .reduce(into: [FieldID: EntryValue]()) { partialResult, valueModel in
                let fieldID = FieldID(valueModel.fieldID)
                if partialResult[fieldID] == nil {
                    partialResult[fieldID] = domainValue(from: valueModel)
                }
            }

        return TrackerEntry(
            id: EntryID(model.entryID),
            createdAt: model.createdAt,
            fieldSnapshots: model.snapshots.map {
                FieldSnapshot(
                    id: FieldID($0.fieldID),
                    name: $0.name,
                    type: TrackerFieldType(rawValue: $0.typeRaw) ?? .text,
                    sortOrder: $0.sortOrder
                )
            }
            .sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return lhs.id.rawValue.uuidString < rhs.id.rawValue.uuidString
                }
                return lhs.sortOrder < rhs.sortOrder
            },
            values: values
        )
    }

    private static func domainValue(from model: EntryValueModel) -> EntryValue {
        if let reason = model.unavailableReason {
            return .unavailable(reason)
        }

        switch TrackerFieldType(rawValue: model.typeRaw) ?? .text {
        case .text:
            return .text(model.textValue ?? "")
        case .number:
            return .number(model.numberValue ?? 0)
        case .date:
            return .date(model.dateValue ?? Date(timeIntervalSince1970: 0))
        case .time:
            guard
                let hour = model.timeHour,
                let minute = model.timeMinute,
                (0...23).contains(hour),
                (0...59).contains(minute)
            else {
                return .unavailable("Invalid time")
            }
            return .time(TimeOfDay(hour: hour, minute: minute))
        case .selector:
            return .selector(model.textValue ?? "")
        }
    }
}

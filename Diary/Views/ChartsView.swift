//
//  ChartsView.swift
//  Diary
//

import SwiftUI
import SwiftData
import Charts

enum TimePeriod: String, CaseIterable, Identifiable {
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case lastYear = "Last Year"
    case allTime = "All Time"
    var id: Self { self }
}

enum Aggregation: String, CaseIterable, Identifiable {
    case perDay = "Day"
    case perWeek = "Week"
    case perMonth = "Month"
    var id: Self { self }
}

enum ChartType: String, CaseIterable, Identifiable {
    case bar = "Bar"
    case line = "Line"
    case scatter = "Scatter"
    var id: Self { self }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let field: String
    let value: Double
}

struct ChartsView: View {
    @Bindable var diary: Diary
    
    @State private var selectedFields: Set<String> = []
    @State private var timePeriod: TimePeriod = .last30Days
    @State private var aggregation: Aggregation = .perDay
    @State private var chartType: ChartType = .line
    
    // Check if a field only contains numerical data or can be parsed as Double
    // For simplicity, we just allow selecting any `custom` field and parse it.
    var availableFields: [String] {
        diary.getSchema().getFieldNames().filter { name in
            diary.getSchema().getFieldType(name) == .custom
        }
    }
    
    var chartData: [ChartDataPoint] {
        if selectedFields.isEmpty { return [] }
        
        // 1. Filter entries by time period
        let now = Date()
        let calendar = Calendar.current
        var startDate: Date?
        
        switch timePeriod {
        case .last7Days:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -30, to: now)
        case .lastYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)
        case .allTime:
            startDate = nil
        }
        
        var filteredEntries = diary.getEntries()
        if let start = startDate {
            filteredEntries = filteredEntries.filter { $0.date >= start }
        }
        
        // 2. Group by aggregation
        // We will bucket by the start of the day, week, or month
        var buckets: [String: [Date: [Double]]] = [:] // field -> (bucketDate -> values)
        for field in selectedFields {
            buckets[field] = [:]
        }
        
        for entry in filteredEntries {
            var bucketDate: Date
            let entryDate = entry.date
            switch aggregation {
            case .perDay:
                bucketDate = calendar.startOfDay(for: entryDate)
            case .perWeek:
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entryDate)
                bucketDate = calendar.date(from: components) ?? entryDate
            case .perMonth:
                let components = calendar.dateComponents([.year, .month], from: entryDate)
                bucketDate = calendar.date(from: components) ?? entryDate
            }
            
            for field in selectedFields {
                let valStr = entry.getFieldAsString(field)
                if let val = Double(valStr) {
                    if buckets[field]![bucketDate] == nil {
                        buckets[field]![bucketDate] = []
                    }
                    buckets[field]![bucketDate]!.append(val)
                }
            }
        }
        
        // 3. Average the buckets
        var dataPoints: [ChartDataPoint] = []
        for field in selectedFields {
            for (date, values) in buckets[field]! {
                let average = values.reduce(0, +) / Double(values.count)
                dataPoints.append(ChartDataPoint(date: date, field: field, value: average))
            }
        }
        
        // Sort by date so lines connect properly
        return dataPoints.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Fields to Chart")) {
                    if availableFields.isEmpty {
                        Text("No numerical/custom fields available").foregroundColor(.secondary)
                    } else {
                        ForEach(availableFields, id: \.self) { field in
                            Toggle(isOn: Binding(
                                get: { selectedFields.contains(field) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedFields.insert(field)
                                    } else {
                                        selectedFields.remove(field)
                                    }
                                }
                            )) {
                                Text(field)
                            }
                        }
                    }
                }
                
                Section(header: Text("Chart Settings")) {
                    Picker("Time Period", selection: $timePeriod) {
                        ForEach(TimePeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    Picker("Aggregation", selection: $aggregation) {
                        ForEach(Aggregation.allCases) { agg in
                            Text(agg.rawValue).tag(agg)
                        }
                    }
                    Picker("Chart Type", selection: $chartType) {
                        ForEach(ChartType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                if !chartData.isEmpty {
                    Section(header: Text("Chart")) {
                        Chart(chartData) { point in
                            switch chartType {
                            case .bar:
                                BarMark(
                                    x: .value("Date", point.date),
                                    y: .value("Value", point.value)
                                )
                                .foregroundStyle(by: .value("Field", point.field))
                            case .line:
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Value", point.value)
                                )
                                .foregroundStyle(by: .value("Field", point.field))
                                .symbol(by: .value("Field", point.field))
                            case .scatter:
                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("Value", point.value)
                                )
                                .foregroundStyle(by: .value("Field", point.field))
                            }
                        }
                        .frame(height: 300)
                        .padding(.vertical)
                    }
                } else if !selectedFields.isEmpty {
                    Section {
                        Text("No numerical data available for the selected fields and time period.")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Charts")
            .onAppear {
                if let first = availableFields.first, selectedFields.isEmpty {
                    selectedFields.insert(first)
                }
            }
        }
    }
}

#Preview {
    ChartsView(diary: Diary.sampleData())
}

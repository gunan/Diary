//
//  CreateEntryView.swift
//  Diary
//
//  Created by Günhan Gülsoy on 8/20/25.
//



import SwiftUI
import SwiftData
import OrderedCollections

struct CreateEntryView: View {
    @Bindable var diary: Diary
    @State var entry: Entry
    
    let fieldNames: [String]
    let defaultValue: String = "No Value"
    let schema: EntryDef;
    
    init(diary: Diary) {
        self.diary = diary
        self.entry = diary.newEntry()
        self.fieldNames = diary.getFieldNames()
        self.schema = diary.getSchema()
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach (self.fieldNames, id: \.self) { key in
                    Section {
                        Text(key).bold()
                        switch self.schema.getFieldType(key)! {
                        case FieldType.custom:
                            TextField("Please fill in", text: binding(for: key))
                        case FieldType.date:
                            DatePicker(key, selection: dateBinding(for: key), displayedComponents: .date)
                        case FieldType.time:
                            DatePicker(key, selection: dateBinding(for: key), displayedComponents: .hourAndMinute)
                        case FieldType.selector:
                            Picker(key, selection: binding(for: key)) {
                                ForEach(
                                    self.schema.getFieldDef(key)!.getOptions(), id: \.self) { option in
                                        Text(option)
                                    }
                            }
                        default:
                            Text("Invalid Field Type")
                        }
                    }
                }
                
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(Date().ISO8601Format())
        }
    }
    
    private func binding(for name: String) -> Binding<String> {
        return Binding<String>(
            get: {
                return self.entry.getFieldAsString(name)
            },
            set: { newValue in
                self.entry.setField(name: name, value: newValue)
            }
        )
    }
    
    private func dateBinding(for name: String) -> Binding<Date> {
        return Binding<Date>(
            get: {
                let dateComponents = self.entry.getDateField(name)
                if dateComponents != nil {
                    return Calendar.current.date(from:dateComponents!) ?? Date();
                } else {
                    return Date()
                }
            },
            set: { newValue in
                self.entry.setDateField(name: name, value: newValue)
            }
        )
    }
}

#Preview {
    CreateEntryView(diary: Diary.sampleData())
}

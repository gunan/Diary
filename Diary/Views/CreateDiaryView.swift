//
//  CreateDiaryView.swift
//  Diary
//
//  Created by Günhan Gülsoy on 8/9/25.
//


import SwiftUI
import SwiftData

struct CreateDiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @Query private var diaries: [Diary] = []
    
    // Whether to show a new field modal or not.
    @State private var showNewFieldEditor: Bool = false
    
    @State private var tempFieldDef: FieldDef = FieldDef("", .custom)
    
    @State private var editingField: Bool = false
    @State private var editingFieldName: String = ""
    @State private var editFieldViewTitle: String = "Add New Field"
    
    
    @State private var newDiary: Diary = Diary()
    
    // TODO add reminder function for the diary,
    // set a list of reminders for each day to send.

    var body: some View {
        List {
            Section(header: Text("Diary Name")) {
                TextField("Diary Name", text: $newDiary.name)
            }
            Section(header: Text("Fields")) {
                ForEach(newDiary.getFieldNames(), id: \.self) { fieldName in
                    let field: FieldDef = newDiary.getFieldDef(fieldName)!
                    HStack {
                        Text(fieldName)
                        Spacer()
                        Text(FieldType.toString(field.type))
                            .font(.caption)
                    }.swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            editingField = true
                            tempFieldDef = FieldDef(field)
                            editingFieldName = fieldName
                            editFieldViewTitle = "Edit Field"
                            showNewFieldEditor.toggle()
                        } label: {
                            Label("Edit", systemImage: "rectangle.and.pencil.and.ellipsis")
                        }.tint(.blue)
                        
                        Button {
                            withAnimation {
                                newDiary.schema.deleteField(fieldName)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }.tint(.red)
                    }
                }
                    
                
                Button(action: {
                    tempFieldDef = FieldDef("", .custom)
                    editFieldViewTitle = "Add New Field"
                    showNewFieldEditor.toggle()
                }) {
                    Text("Add New Field")
                }
            }
            
            Section(header: Text("")) {
                Button("Save Diary") {
                    modelContext.insert(newDiary)
                    dismiss()
                }
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .navigationTitle("New Diary")
        .listStyle(InsetGroupedListStyle())
        .sheet(isPresented: $showNewFieldEditor) {
            NavigationStack {
                EditFieldModalView(editingField: $tempFieldDef)
                    .navigationTitle(editFieldViewTitle)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showNewFieldEditor = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            
                            Button("Save") {
                                if editingField {
                                    if editingFieldName != tempFieldDef.name {
                                        newDiary.schema.deleteField(editingFieldName)
                                        newDiary.schema.setField(tempFieldDef.name, tempFieldDef)
                                    } else {
                                        newDiary.schema.setField(tempFieldDef.name, tempFieldDef)
                                    }
                                    editingFieldName = ""
                                }
                                if !editingField && !tempFieldDef.name.isEmpty {
                                    newDiary.schema.setField(tempFieldDef.name, tempFieldDef)
                                }
                                
                                editingField = false
                                showNewFieldEditor = false
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    CreateDiaryView()
        .modelContainer(for: Diary.self, inMemory: true)
}

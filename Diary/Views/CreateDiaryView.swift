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
    @State private var name: String = ""
    @Query private var fields: [FieldDef] = []
    
    @State private var newFieldName: String = ""
    @State private var newFieldType: FieldType = .custom
    @State private var showNewFieldEditor: Bool = false
    
    @State private var tempFieldDef: FieldDef = FieldDef("", .custom)
    
    @State private var editingField: Bool = false
    @State private var editFieldViewTitle: String = "Add New Field"
    
    // TODO add reminder function for the diary,
    // set a list of reminders for each day to send.

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Diary Name")) {
                    TextField("Diary Name", text: $name)
                }
                Section(header: Text("Fields")) {
                    ForEach(fields) { field in
                        HStack {
                            Text(field.name)
                            Spacer()
                            Text(FieldType.toString(field.type))
                                .font(.caption)
                        }.swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                editingField = true
                                tempFieldDef = field
                                editFieldViewTitle = "Edit Field"
                                showNewFieldEditor.toggle()
                            } label: {
                                Label("Edit", systemImage: "rectangle.and.pencil.and.ellipsis")
                            }.tint(.blue)
                            
                            Button {
                                deleteField(field)
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
            }
            .navigationTitle("New Diary")
            .listStyle(InsetGroupedListStyle())
        }
        .sheet(isPresented: $showNewFieldEditor) {
            NavigationStack {
                EditfieldModalView(editingField: $tempFieldDef)
                    .navigationTitle(editFieldViewTitle)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showNewFieldEditor = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            
                            Button("Save") {
                                if !editingField && !tempFieldDef.name.isEmpty {
                                    modelContext.insert(
                                        tempFieldDef
                                    )
                                }
                                editingField = false
                                showNewFieldEditor = false
                            }
                        }
                    }
            }
        }
    }


    func deleteField(_ f: FieldDef) {
        withAnimation {
            modelContext.delete(f)
        }
    }

}

#Preview {
    CreateDiaryView()
        .modelContainer(for: FieldDef.self, inMemory: true)
}

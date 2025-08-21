//
//  NewFieldModalView.swift
//  Diary
//
//  Created by Günhan Gülsoy on 8/10/25.
//

import SwiftUI
import SwiftData

struct EditFieldModal: View {
    @Binding var editingField: FieldDef

    @State private var newSelectionName: String = ""
    
    var body: some View {
        List {
            Section(header: Text("Field Name")) {
                TextField("Field Name", text: $editingField.name)
            }
            Section(header: Text("Field Type")) {
                Picker("Field Type",
                       selection: $editingField.type) {
                    ForEach(FieldType.allCases) { ft in
                        Text(ft.toString()).tag(ft.toInt())
                    }
                }
                
                if (FieldType.isSelector(editingField.type)) {
                    ForEach(editingField.options, id: \.self) { selection in
                        Text(selection)
                    }
                    HStack {
                        TextField("New Option", text: $newSelectionName)
                        Button(action: {
                            withAnimation {
                                editingField.options.append(newSelectionName)
                                newSelectionName = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newSelectionName.isEmpty)
                    }
                }
            }
        }.listStyle(InsetGroupedListStyle())
    }
}

#Preview {
    
    let editingField = FieldDef("", .custom)
    EditFieldModal(editingField: .constant(editingField))
}

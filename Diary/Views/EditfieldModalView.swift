//
//  NewFieldModalView.swift
//  Diary
//
//  Created by Günhan Gülsoy on 8/10/25.
//

import SwiftUI
import SwiftData

struct EditfieldModalView: View {
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
                    Text("custom").tag(0)
                    Text("selector").tag(1)
                    Text("date").tag(2)
                    Text("time").tag(3)
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
    EditfieldModalView(editingField: .constant(editingField))
}

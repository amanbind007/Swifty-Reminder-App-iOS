//
//  AddNewListView.swift
//  RemindersApp
//
//  Created by Mohammad Azam on 1/20/23.
//

import SwiftUI

struct AddNewListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedColor: Color = .yellow
    
    let onSave: (String, UIColor) -> Void
    
    private var isFormValid: Bool {
        !name.isEmpty
    }
    
    var body: some View {
        VStack {
            VStack {
                Image(systemName: "line.3.horizontal.circle.fill")
                    .foregroundColor(selectedColor)
                    .font(.system(size: 100))
                TextField("List Name", text: $name)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(30)
            .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
            
            ColorPickerView(selectedColor: $selectedColor)
            
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New List")
                        .font(.headline)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // save the list
                        onSave(name, UIColor(selectedColor))
                        
                        dismiss()
                    }.disabled(!isFormValid)
                }
            }
    }
}

struct AddNewListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddNewListView(onSave: { _, _ in })
        }
    }
}

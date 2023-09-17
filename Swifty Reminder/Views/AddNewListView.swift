//
//  AddNewListView.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 16/09/23.
//

import SwiftUI

struct AddNewListView: View {
    
    @State var selectedColor : Color = .red
    @State var name : String = ""
    @Environment(\.dismiss) private var dismiss
    @State var onSave: (String, UIColor)-> Void
    
    private var isFormValid : Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    
    var body: some View {
        VStack{
            VStack{
                Image(systemName: "line.3.horizontal.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(selectedColor)
                
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .autocorrectionDisabled()
                
            }
            .padding(30)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            ColorPickerView(selectedColor: $selectedColor)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .principal){
                Text("New List")
                    .font(.headline)
            }
            ToolbarItem(placement: .navigationBarLeading){
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                }

            }
            ToolbarItem(placement: .navigationBarTrailing){
                Button {
                    onSave(name, UIColor(selectedColor))
                    dismiss()
                } label: {
                    Text("Done")
                }
                .disabled(isFormValid)

            }
        }
    }
}

struct AddNewListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddNewListView(onSave: {(_, _) in })
        }
        
    }
}

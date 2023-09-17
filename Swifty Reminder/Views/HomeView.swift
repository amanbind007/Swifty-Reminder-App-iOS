//
//  ContentView.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 15/09/23.
//

import SwiftUI

struct HomeView: View {
    
    @FetchRequest(sortDescriptors: []) private var myListResult: FetchedResults<MyList>
    @State var isPresented: Bool = false
    
    
    var body: some View {
        NavigationStack {
            
            VStack{
                
                MyListView(myLists: myListResult)
                    .padding()
                    
                
                Button {
                    isPresented = true
                } label: {
                    Text("Add List")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(.subheadline)
                }
                .padding()

            }.sheet(isPresented: $isPresented) {
                NavigationStack{
                    AddNewListView { name, color in
                        //Code to save
                        do {
                            try ReminderService.saveMyList(name, color)
                        }
                        catch{
                            print(error)
                        }
                        
                        
                        
                    }
                }
                
            }
            
        }
        
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, CoreDataProvider.shared.persistentContainer.viewContext )
    }
}

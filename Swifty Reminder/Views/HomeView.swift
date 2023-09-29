//
//  ContentView.swift
//  RemindersApp
//
//  Created by Mohammad Azam on 1/19/23.
//

import SwiftUI

struct HomeView: View {
    
    @FetchRequest(sortDescriptors: [])
    private var myListResults: FetchedResults<MyList>
    
    @FetchRequest(sortDescriptors: [])
    private var searchResults: FetchedResults<Reminder>
    
    @State var search: String = ""
    @State private var isPresented: Bool = false
    @State private var searching: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView{
                    MyListView(myLists: myListResults)
                    
                    //Spacer()
                    
                    Button {
                        isPresented = true
                    } label: {
                        Text("Add List")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.headline)
                    }.padding()
                }
            }
            .onChange(of: search, perform: { searchTerm in
                
                searching = !searchTerm.trimmingCharacters(in: .whitespaces).isEmpty ? true : false
                
                searchResults.nsPredicate = ReminderService.getRemindersBySearchTerm(searchTerm).predicate
            })
            .overlay(alignment: .center, content: {
                ReminderListView(reminders: searchResults)
                    .opacity(searching ? 1.0 : 0.0)
            })
            .sheet(isPresented: $isPresented) {
                NavigationView {
                    AddNewListView { name, color in
                        do {
                            try ReminderService.saveMyList(name, color)
                        } catch {
                            print(error)
                        }
                    }
                }
            }
            .padding()
            
        }
        .searchable(text: $search)
        
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, CoreDataProvider.shared.persistentContainer.viewContext)
    }
}

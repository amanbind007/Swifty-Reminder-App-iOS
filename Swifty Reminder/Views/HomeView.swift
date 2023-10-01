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
    
    private var reminderStats = ReminderStatsBuilder()
    @State private var reminderStatsValues = ReminderStatsValue()
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView{
                    
                    HStack{
                        
                        VStack{
                            ReminderStatsView(icon: "calendar.badge.exclamationmark", title: "Today", count: reminderStatsValues.todayCount)
                            ReminderStatsView(icon: "calendar", title: "Scheduled", count: reminderStatsValues.sheduledCount)
                        }
                        VStack{
                            ReminderStatsView(icon: "tray.full.fill", title: "All", count: reminderStatsValues.allCount)
                            ReminderStatsView(icon: "checkmark.circle.fill", title: "completed", count: reminderStatsValues.completedCount)
                            
                        }
                    }
                    
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
            .listStyle(.plain)
            .onChange(of: search, perform: { searchTerm in
                
                searching = !searchTerm.trimmingCharacters(in: .whitespaces).isEmpty ? true : false
                
                searchResults.nsPredicate = ReminderService.getRemindersBySearchTerm(searchTerm).predicate
            })
            .overlay(alignment: .center, content: {
                ReminderListView(reminders: searchResults)
                    .opacity(searching ? 1.0 : 0.0)
            })
            .onAppear(perform: {
                reminderStatsValues = reminderStats.build(myListResults: myListResults)
            })
            .padding()
            .navigationTitle("Reminders")
            
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

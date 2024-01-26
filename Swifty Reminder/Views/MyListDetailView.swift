//
//  MyListDetailView.swift
//  RemindersApp
//
//  Created by Mohammad Azam on 1/21/23.
//

import SwiftUI

struct MyListDetailView: View {
    let myList: MyList
    @State private var openAddReminder: Bool = false
    @State private var title: String = ""
    
    @FetchRequest(sortDescriptors: [])
    private var reminderResults: FetchedResults<Reminder>
    
    private var isFormValid: Bool {
        !title.isEmpty
    }
    
    init(myList: MyList) {
        self.myList = myList
        _reminderResults = FetchRequest(fetchRequest: ReminderService.getRemindersByList(myList: myList))
    }
    
    var body: some View {
        VStack {
            // Display List of Reminders
            ReminderListView(reminders: reminderResults)
            
            HStack {
                Image(systemName: "plus.circle.fill")
                Button("New Reminder") {
                    openAddReminder = true
                }
            }.foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }.alert("New Reminder", isPresented: $openAddReminder) {
            TextField("", text: $title)
            Button("Cancel", role: .cancel) {}
            Button("Done") {
                if isFormValid {
                    do {
                        try ReminderService.saveReminderToMyList(myList: myList, reminderTitle: title)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}

struct MyListDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MyListDetailView(myList: PreviewData.myList)
    }
}

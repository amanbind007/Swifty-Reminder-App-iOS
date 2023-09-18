//
//  MyListDetailView.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 18/09/23.
//

import SwiftUI

struct MyListDetailView: View {
    
    @State var openAddReminder = false
    @State var title : String = ""
    @FetchRequest(sortDescriptors: []) var reminderResults : FetchedResults<Reminder>
    
    let myList: MyList

    private var isFormValid : Bool {
        return title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    
    init(myList: MyList){
        self.myList = myList
        _reminderResults = FetchRequest(fetchRequest: ReminderService.getRemindersByList(myList: myList))
    }
    
    var body: some View {
        
        VStack{
            
            //Displaying Reminders Here
            ReminderListView(reminders: reminderResults)
            
            HStack{
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                Button("Add Reminder") {
                    openAddReminder = true
                }
            }
            
             
        }
        .alert("New Reminder", isPresented: $openAddReminder) {
            TextField("Enter Title", text: $title)
            Button("Cancel", role: .cancel) {}
            Button("Done") {
                if isFormValid {
                    //Save reminder to list
                    
                    do{
                        try ReminderService.saveReminderToMyList(myList: myList, reminderTitle: title)
                    }
                    catch{
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

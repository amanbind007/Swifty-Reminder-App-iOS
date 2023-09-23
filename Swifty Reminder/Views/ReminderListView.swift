//
//  ReminderListView.swift
//  RemindersApp
//
//  Created by Mohammad Azam on 1/22/23.
//

import SwiftUI

struct ReminderListView: View {
    
    let reminders: FetchedResults<Reminder>
    
    private func reminderCheckChanged(reminder: Reminder){
        var editConfig = ReminderEditConfig(reminder: reminder)
        editConfig.isCompleted = !reminder.isCompleted
        
        do{
            let _ = try ReminderService.updateReminder(reminder: reminder, editConfig: editConfig)
        }catch{
            print(error.localizedDescription)
        }
    }
    
    var body: some View {
        List(reminders) { reminder in
            ReminderCellView(reminder: reminder){ event in
                
                switch event {
                case .onSelect(let reminder):
                    print("Item Selected")
                    
                case .onCheckChanged(let reminder):
                    reminderCheckChanged(reminder: reminder)
                    
                case .onInfo:
                    print("Info Selected")
                }
                
                
            }
        }
    }
}

/*
struct ReminderListView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderListView()
    }
} */

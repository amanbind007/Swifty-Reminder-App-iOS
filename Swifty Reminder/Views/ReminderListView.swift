//
//  ReminderListView.swift
//  RemindersApp
//
//  Created by Mohammad Azam on 1/22/23.
//

import SwiftUI

struct ReminderListView: View {
    
    @State private var selectedReminder: Reminder?
    @State private var showReminderDetailView: Bool = false
    let reminders: FetchedResults<Reminder>
    
    private func reminderCheckChanged(reminder: Reminder, isCompleted: Bool){
        var editConfig = ReminderEditConfig(reminder: reminder)
        editConfig.isCompleted = isCompleted
        
        do{
            let _ = try ReminderService.updateReminder(reminder: reminder, editConfig: editConfig)
        }catch{
            print(error.localizedDescription)
            
        }
    }
    
    private func isReminderSelected(_ reminder: Reminder)->Bool{
        selectedReminder?.objectID == reminder.objectID
    }
    
    var body: some View {
        VStack{
            List(reminders) { reminder in
                ReminderCellView(reminder: reminder, isSelected: isReminderSelected(reminder)){ event in
                    
                    switch event {
                    case .onSelect(let reminder):
                        selectedReminder = reminder
                        
                    case .onCheckChanged(let reminder, let isCompleted):
                        reminderCheckChanged(reminder: reminder, isCompleted: isCompleted)
                        
                    case .onInfo:
                        showReminderDetailView = true
                    }
                }
                
                
            }
        }
        .sheet(isPresented: $showReminderDetailView, content: {
            ReminderDetailView(reminder: Binding($selectedReminder)!)
        })
    }
}

/*
 struct ReminderListView_Previews: PreviewProvider {
 static var previews: some View {
 ReminderListView()
 }
 } */

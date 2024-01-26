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
    
    private func reminderCheckChanged(reminder: Reminder, isCompleted: Bool) {
        var editConfig = ReminderEditConfig(reminder: reminder)
        editConfig.isCompleted = isCompleted
        
        do {
            let _ = try ReminderService.updateReminder(reminder: reminder, editConfig: editConfig)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func isReminderSelected(_ reminder: Reminder) -> Bool {
        selectedReminder?.objectID == reminder.objectID
    }
    
    private func deleteReminder(_ indexSet: IndexSet) {
        indexSet.forEach { index in
            let reminder = reminders[index]
            do {
                try ReminderService.deleteReminder(reminder)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(reminders) { reminder in
                    ReminderCellView(reminder: reminder, isSelected: isReminderSelected(reminder)) { event in
                        
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
                .onDelete(perform: deleteReminder)
            }
        }
        .sheet(isPresented: $showReminderDetailView, content: {
            ReminderDetailView(reminder: Binding($selectedReminder)!)
        })
    }
}

struct ReminderListView_Previews: PreviewProvider {
    private struct ReminderListViewContainer: View {
        @FetchRequest(sortDescriptors: []) private var reminder: FetchedResults<Reminder>
        
        var body: some View {
            ReminderListView(reminders: reminder)
        }
    }
    
    static var previews: some View {
        ReminderListViewContainer()
            .environment(\.managedObjectContext, CoreDataProvider.shared.persistentContainer.viewContext)
    }
}

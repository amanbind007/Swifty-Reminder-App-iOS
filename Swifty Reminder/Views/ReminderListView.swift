//
//  ReminderListView.swift
//  RemindersApp
//
//  Created by Mohammad Azam on 1/22/23.
//

import SwiftUI

struct ReminderListView: View {
    
    let reminders: FetchedResults<Reminder>
    
    var body: some View {
        List(reminders) { reminder in
            ReminderCellView(reminder: reminder){ event in
                
                switch event {
                case .onSelect(let reminder):
                    print("Item Selected")
                    
                case .onCheckChanged(let reminder):
                    print("OnCheck Selected")
                    
                case .onInfo:
                    print("Info Selected")
                
                
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

//
//  ReminderListView.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 18/09/23.
//

import SwiftUI

struct ReminderListView: View {
    
    let reminders: FetchedResults<Reminder>
    
    var body: some View {
        
        ForEach(reminders) { reminder in
            ReminderCellView(reminder: reminder)
        }
        
        
    }
}

//struct ReminderListView_Previews: PreviewProvider {
//    static var previews: some View {
//        ReminderListView()
//    }
//}

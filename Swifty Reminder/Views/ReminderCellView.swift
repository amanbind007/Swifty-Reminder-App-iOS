//
//  ReminderCellView.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 18/09/23.
//

import SwiftUI

struct ReminderCellView: View {
    let reminder: Reminder
    var body: some View {
        HStack{
            
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(reminder.isCompleted ? Color.green : Color.red)
            Text(reminder.title ?? "")
        }
    }
}

struct ReminderCellView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderCellView(reminder: PreviewData.reminder)
    }
}

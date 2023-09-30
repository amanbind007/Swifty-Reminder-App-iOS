//
//  ReminderStatsBuilder.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 30/09/23.
//

import Foundation
import SwiftUI


struct ReminderStatsValue{
    var todayCount: Int = 0
    var sheduledCount: Int = 0
    var allCount: Int = 0
    var completedCount : Int = 0
    
}

struct ReminderStatsBuilder {
    func build(myListResults: FetchedResults<MyList>)-> ReminderStatsValue{
        let remindersArray = myListResults.map {
            $0.remindersArray
        }
            .reduce([], +)
        
        return ReminderStatsValue()
    }
    
    func calculateScheduledCount(reminders: [Reminder])-> Int{
        return reminders.reduce(0) { result, reminder in
            let isToday = reminder.reminderDate?.isToday ?? false
            return (reminder.isCompleted && reminder.reminderDate != nil && reminder.reminderTime != nil) ? result+1 : result
        }
    }
    
    func calculateTodaysCount(reminders: [Reminder])-> Int{
        return reminders.reduce(0) { result, reminder in
            let isToday = reminder.reminderDate?.isToday ?? false
            return isToday ? result+1 : result
        }
    }
    
    func calculateCompletedCount(reminders: [Reminder])-> Int{
        return reminders.reduce(0) { result, reminder in
            return reminder.isCompleted ? result+1 : result
        }
    }
    
    
    func calculateAllCount(reminders: [Reminder])-> Int{
        return reminders.reduce(0) { result, reminder in
            return !reminder.isCompleted ? result+1 : result
        }
    }
}

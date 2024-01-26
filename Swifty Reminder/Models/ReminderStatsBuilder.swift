//
//  ReminderStatsBuilder.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 30/09/23.
//

import Foundation
import SwiftUI

enum ReminderStatType {
    case today
    case all
    case scheduled
    case completed
}

struct ReminderStatsValues {
    var todayCount: Int = 0
    var scheduledCount: Int = 0
    var allCount: Int = 0
    var completedCount: Int = 0
}

struct ReminderStatsBuilder {
    func build(myListResults: FetchedResults<MyList>) -> ReminderStatsValues {
        let remindersArray = myListResults.map {
            $0.remindersArray
        }.reduce([], +)
           
        let todaysCount = calculateTodaysCount(reminders: remindersArray)
        let scheduledCount = calculateScheduledCount(reminders: remindersArray)
        let completedCount = calculateCompletedCount(reminders: remindersArray)
        let allCount = calculateAllCount(reminders: remindersArray)
        
        return ReminderStatsValues(todayCount: todaysCount, scheduledCount: scheduledCount, allCount: allCount, completedCount: completedCount)
    }
    
    private func calculateScheduledCount(reminders: [Reminder]) -> Int {
        return reminders.reduce(0) { result, reminder in
            ((reminder.reminderDate != nil || reminder.reminderTime != nil) && !reminder.isCompleted) ? result + 1 : result
        }
    }
    
    private func calculateTodaysCount(reminders: [Reminder]) -> Int {
        return reminders.reduce(0) { result, reminder in
            let isToday = reminder.reminderDate?.isToday ?? false
            return isToday ? result + 1 : result
        }
    }
    
    private func calculateCompletedCount(reminders: [Reminder]) -> Int {
        return reminders.reduce(0) { result, reminder in
            reminder.isCompleted ? result + 1 : result
        }
    }
    
    private func calculateAllCount(reminders: [Reminder]) -> Int {
        return reminders.reduce(0) { result, reminder in
            !reminder.isCompleted ? result + 1 : result
        }
    }
}

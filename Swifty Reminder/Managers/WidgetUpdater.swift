//
//  WidgetUpdater.swift
//  Swifty Reminder
//
//  Created by James Fehr on 17/10/26.
//

import CoreData
import Foundation
import WidgetKit

/// Saves a fresh snapshot of the reminders for the home screen widget and asks it to redraw.
enum WidgetUpdater {
    static func refresh() {
        let open = (try? ReminderService.viewContext.fetch(ReminderService.remindersByStatType(statType: .all))) ?? []

        let upcoming = open
            .sorted { lhs, rhs in
                // Soonest due first; reminders without a due date go last
                switch (lhs.dueDate, rhs.dueDate) {
                case let (l?, r?): return l < r
                case (_?, nil): return true
                default: return false
                }
            }
            .prefix(4)
            .map { reminder in
                WidgetSnapshot.Item(title: reminder.title ?? "",
                                    listName: reminder.list?.name ?? "",
                                    dueDate: reminder.dueDate,
                                    date: reminder.reminderDate,
                                    time: reminder.reminderTime)
            }

        let snapshot = WidgetSnapshot(openCount: open.count,
                                      todayCount: open.filter { $0.reminderDate?.isToday ?? false }.count,
                                      upcoming: Array(upcoming))
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

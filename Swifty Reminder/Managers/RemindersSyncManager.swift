//
//  RemindersSyncManager.swift
//  Swifty Reminder
//
//  Created by James Fehr on 17/10/26.
//

import CoreData
import EventKit
import Foundation
import SwiftUI
import UIKit

/// Copies this app's reminders into Apple's Reminders app, one way: changes made over there
/// are not brought back. Everything goes into a single "Scary Calendar" list, so the copies stay
/// in one place and never get mixed in with lists the user already has.
@MainActor
enum RemindersSyncManager {
    private static let eventStore = EKEventStore()

    private static let listTitle = "Scary Calendar"
    // Remembers which Reminders list is ours, so renaming it in Apple Reminders doesn't make a second one
    private static let listIdentifierKey = "RemindersSyncListIdentifier"

    private static var viewContext: NSManagedObjectContext {
        CoreDataProvider.shared.persistentContainer.viewContext
    }

    /// Creates or updates the reminder's copy in Apple Reminders. Call after saving the reminder.
    /// The first time, this asks for Reminders access.
    nonisolated static func updateAppleReminder(for reminder: Reminder) {
        let objectID = reminder.objectID
        Task { @MainActor in
            guard await hasAccess(askIfNeeded: true),
                  let reminder = try? viewContext.existingObject(with: objectID) as? Reminder,
                  !reminder.isDeleted else { return }
            push(reminder)
        }
    }

    /// Removes the reminder's copy from Apple Reminders. Call before deleting the reminder.
    nonisolated static func deleteAppleReminder(for reminder: Reminder) {
        guard let identifier = reminder.eventKitIdentifier else { return }
        Task { @MainActor in
            guard await hasAccess(askIfNeeded: false),
                  let appleReminder = eventStore.calendarItem(withIdentifier: identifier) as? EKReminder else { return }
            do {
                try eventStore.remove(appleReminder, commit: true)
            } catch {
                print("Couldn't remove reminder from Reminders: \(error.localizedDescription)")
            }
        }
    }

    /// Copies over any reminders that aren't in Apple Reminders yet, such as ones made before
    /// access was given. Never asks for access.
    nonisolated static func copyMissingReminders() {
        Task { @MainActor in
            guard await hasAccess(askIfNeeded: false) else { return }
            pushMissingReminders()
        }
    }

    /// Whether we're allowed to write to Apple Reminders. With askIfNeeded, shows the permission
    /// prompt if the user hasn't answered it yet, and copies everything over if they say yes.
    private static func hasAccess(askIfNeeded: Bool) async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if #available(iOS 17.0, *) {
            if status == .fullAccess { return true }
        } else if status == .authorized {
            return true
        }
        guard askIfNeeded, status == .notDetermined else { return false }

        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToReminders()
            } else {
                granted = try await eventStore.requestAccess(to: .reminder)
            }
            if granted {
                pushMissingReminders()
            }
            return granted
        } catch {
            print("Couldn't get Reminders access: \(error.localizedDescription)")
            return false
        }
    }

    private static func pushMissingReminders() {
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        request.predicate = NSPredicate(format: "eventKitIdentifier == nil")
        guard let reminders = try? viewContext.fetch(request) else { return }
        for reminder in reminders {
            push(reminder)
        }
    }

    /// Writes the reminder's title, notes, due date and completion to its copy in Apple Reminders,
    /// making the copy first if there isn't one (or it was deleted over there).
    private static func push(_ reminder: Reminder) {
        let appleReminder: EKReminder
        if let identifier = reminder.eventKitIdentifier,
           let existing = eventStore.calendarItem(withIdentifier: identifier) as? EKReminder {
            appleReminder = existing
        } else {
            guard let list = scaryList() else { return }
            appleReminder = EKReminder(eventStore: eventStore)
            appleReminder.calendar = list
        }

        appleReminder.title = reminder.title ?? ""
        appleReminder.notes = reminder.notes?.isEmpty == false ? reminder.notes : nil
        appleReminder.dueDateComponents = dueDateComponents(date: reminder.reminderDate, time: reminder.reminderTime)
        // Only when it changes, so the completion date over there isn't reset by other edits
        if appleReminder.isCompleted != reminder.isCompleted {
            appleReminder.isCompleted = reminder.isCompleted
        }

        do {
            try eventStore.save(appleReminder, commit: true)
        } catch {
            print("Couldn't save reminder to Reminders: \(error.localizedDescription)")
            return
        }

        if reminder.eventKitIdentifier != appleReminder.calendarItemIdentifier {
            reminder.eventKitIdentifier = appleReminder.calendarItemIdentifier
            do {
                try viewContext.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    /// Our list in Apple Reminders, made the first time it's needed (or again if it was deleted there).
    private static func scaryList() -> EKCalendar? {
        let defaults = UserDefaults.standard
        if let identifier = defaults.string(forKey: listIdentifierKey),
           let list = eventStore.calendar(withIdentifier: identifier) {
            return list
        }

        // Left over from before a reinstall
        if let list = eventStore.calendars(for: .reminder).first(where: { $0.title == listTitle && $0.allowsContentModifications }) {
            defaults.set(list.calendarIdentifier, forKey: listIdentifierKey)
            return list
        }

        // Prefer the account the user's own reminders go to (usually iCloud), then any other that takes it
        var sources = eventStore.sources.filter { $0.sourceType == .calDAV || $0.sourceType == .local }
        if let defaultSource = eventStore.defaultCalendarForNewReminders()?.source {
            sources.insert(defaultSource, at: 0)
        }

        for source in sources {
            let list = EKCalendar(for: .reminder, eventStore: eventStore)
            list.title = listTitle
            list.cgColor = UIColor(Color.pumpkin).cgColor
            list.source = source
            do {
                try eventStore.saveCalendar(list, commit: true)
                defaults.set(list.calendarIdentifier, forKey: listIdentifierKey)
                return list
            } catch {
                continue
            }
        }

        print("Couldn't make the \(listTitle) list in Reminders")
        return nil
    }

    /// The due date for Apple Reminders: the date at the time, or an all-day due date when there's
    /// no time. A time with no date goes on the next day that time comes round, like the notification.
    private static func dueDateComponents(date: Date?, time: Date?) -> DateComponents? {
        guard date != nil || time != nil else { return nil }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date ?? Date())
        guard let time else { return components }

        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        if date == nil, let dueDate = calendar.date(from: components), dueDate <= Date(),
           let nextDay = calendar.date(byAdding: .day, value: 1, to: dueDate) {
            components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextDay)
        }
        return components
    }
}

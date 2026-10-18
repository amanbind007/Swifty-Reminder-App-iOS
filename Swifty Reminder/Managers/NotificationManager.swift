//
//  NotificationManager.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 05/10/23.
//

import CoreData
import Foundation
import UserNotifications

enum NotificationManager {
    // Used when a reminder has no notes of its own
    private static let spookyLines = [
        "The spirits say it's time...",
        "Boo! Did you forget about this?",
        "Don't keep the ghosts waiting.",
        "The witching hour has arrived.",
        "Something is lurking on your to-do list...",
    ]

    // Bundled in Sounds/; one is picked at random for each reminder
    private static let spookySounds = [
        "witch_laugh.wav",
        "dracula.wav",
        "scream.wav",
    ]

    // Follow-ups after the reminder goes off, getting pushier (and louder) while it stays unfinished
    private static let nags: [(after: TimeInterval, sound: String, title: String, body: String)] = [
        (60 * 60, "witch_laugh.wav", "👻 Still haunting you", "It's overdue. Do it before it gets worse..."),
        (24 * 60 * 60, "dracula.wav", "👻👻 The ghost is getting restless", "A whole day overdue. Can you hear the chains rattling?"),
        (3 * 24 * 60 * 60, "scream.wav", "☠️ The spirits are furious", "Three days overdue! Finish it so it can rest in peace."),
    ]

    /// Schedules the reminder's notification, replacing any earlier one for the same reminder.
    /// Removes it instead when the reminder is completed, has no date or time, or is in the past.
    static func updateNotification(for reminder: Reminder) {
        let identifier = identifier(for: reminder)
        let notificationCenter = UNUserNotificationCenter.current()

        guard !reminder.isCompleted,
              let fireDate = fireDate(date: reminder.reminderDate, time: reminder.reminderTime) else {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers(for: reminder))
            return
        }

        scheduleNags(for: reminder, after: fireDate)

        let content = UNMutableNotificationContent()
        content.title = "👻 " + (reminder.title ?? "")
        if let body = reminder.notes, !body.isEmpty {
            content.body = body
        } else {
            content.body = spookyLines.randomElement() ?? ""
        }
        if let sound = spookySounds.randomElement() {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(sound))
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: fireDate.dateComponents, repeats: false)

        // Reusing the reminder's identifier replaces its pending notification instead of adding another
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if error != nil {
                // Handle any errors.
            }
            else {
                print("Reminder Added")
            }
        }
    }

    static func cancelNotification(for reminder: Reminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers(for: reminder))
    }

    private static func scheduleNags(for reminder: Reminder, after fireDate: Date) {
        let base = identifier(for: reminder)
        for (index, nag) in nags.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = nag.title + ": " + (reminder.title ?? "")
            content.body = nag.body
            content.sound = UNNotificationSound(named: UNNotificationSoundName(nag.sound))
            let nagDate = fireDate.addingTimeInterval(nag.after)
            let trigger = UNCalendarNotificationTrigger(dateMatching: nagDate.dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "\(base)-nag\(index + 1)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    /// The reminder's own notification followed by its nags
    private static func identifiers(for reminder: Reminder) -> [String] {
        let base = identifier(for: reminder)
        return [base] + nags.indices.map { "\(base)-nag\($0 + 1)" }
    }

    /// Schedules the alert for when a running timer ends, replacing any earlier one for it.
    static func scheduleTimerNotification(for timer: CountdownTimer) {
        guard let endDate = timer.endDate else { return }
        let secondsLeft = endDate.timeIntervalSinceNow
        guard secondsLeft > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏰ " + (timer.label.isEmpty ? "Time's up!" : timer.label)
        content.body = spookyLines.randomElement() ?? ""
        if let sound = spookySounds.randomElement() {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(sound))
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsLeft, repeats: false)
        let request = UNNotificationRequest(identifier: timer.notificationIdentifier,
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelTimerNotification(for timer: CountdownTimer) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [timer.notificationIdentifier])
    }

    private static func identifier(for reminder: Reminder) -> String {
        reminder.objectID.uriRepresentation().absoluteString
    }

    /// When the reminder should go off: its date at its time. A time with no date means the
    /// next time that time comes round. Returns nil when there's nothing in the future to schedule.
    private static func fireDate(date: Date?, time: Date?) -> Date? {
        guard date != nil || time != nil else { return nil }

        let calendar = Calendar.current
        let now = Date()
        var dateComponents = (date ?? now).dateComponents

        if let time {
            let timeComponents = time.dateComponents
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
        }

        guard var fireDate = calendar.date(from: dateComponents) else { return nil }
        if date == nil, fireDate <= now {
            fireDate = calendar.date(byAdding: .day, value: 1, to: fireDate) ?? fireDate
        }
        return fireDate > now ? fireDate : nil
    }
}

/// Lets reminder and timer alerts show up while the app is open too;
/// by default iOS only shows notifications when the app is in the background.
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresenter()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}

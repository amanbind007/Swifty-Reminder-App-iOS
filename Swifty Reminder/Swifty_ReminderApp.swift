//
//  Swifty_ReminderApp.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 15/09/23.
//

import SwiftUI
import UserNotifications

@main
struct Swifty_ReminderApp: App {
    init() {
        // Show reminder and timer alerts even while the app is open
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared

        // Schedule the request with the system.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in

            if granted {
                // request Notificaton
            }
            else {
                print(error?.localizedDescription as Any)
            }
        }

        // Copy any reminders that aren't in Apple's Reminders app yet (only once access has been given)
        RemindersSyncManager.copyMissingReminders()

        // Give the home screen widget something to show straight away
        WidgetUpdater.refresh()

        // Halloween theme: pumpkin-orange navigation titles
        let pumpkin = UIColor(Color.pumpkin)
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: pumpkin]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: pumpkin]
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, CoreDataProvider.shared.persistentContainer.viewContext)
                .overlay { BatFlyoverView() }
                .overlay { WitchBubbleView() }
                .overlay { SpiritSummonView() }
                .preferredColorScheme(.dark)
                .tint(Color.pumpkin)
        }
    }
}

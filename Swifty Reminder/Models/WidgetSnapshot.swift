//
//  WidgetSnapshot.swift
//  Swifty Reminder
//
//  Created by James Fehr on 17/10/26.
//

import Foundation

/// What the home screen widget shows. Shared by the app and the widget: the app saves one
/// into the App Group whenever reminders change, and the widget only ever reads it.
struct WidgetSnapshot: Codable {
    struct Item: Codable, Hashable {
        var title: String
        var listName: String
        /// When it's overdue from; nil for reminders with only a time
        var dueDate: Date?
        /// The reminder's own date and time, for the label
        var date: Date?
        var time: Date?
    }

    var openCount: Int
    var todayCount: Int
    /// Soonest due first
    var upcoming: [Item]

    /// Must match the App Groups entitlement of both the app and the widget
    static let appGroup = "group.com.amanbind.Swifty-Reminder"
    private static let storageKey = "widgetSnapshot"

    static let empty = WidgetSnapshot(openCount: 0, todayCount: 0, upcoming: [])

    static let placeholder = WidgetSnapshot(openCount: 4, todayCount: 2, upcoming: [
        Item(title: "Carve the pumpkin", listName: "Halloween",
             dueDate: Date().addingTimeInterval(-2 * 60 * 60), date: Date(), time: Date().addingTimeInterval(-2 * 60 * 60)),
        Item(title: "Buy candy", listName: "Shopping",
             dueDate: Date().addingTimeInterval(3 * 60 * 60), date: Date(), time: Date().addingTimeInterval(3 * 60 * 60)),
        Item(title: "Finish costume", listName: "Halloween", dueDate: nil, date: nil, time: nil),
    ])

    static func load() -> WidgetSnapshot? {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults(suiteName: Self.appGroup)?.set(data, forKey: Self.storageKey)
    }
}

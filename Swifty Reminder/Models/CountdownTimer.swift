//
//  CountdownTimer.swift
//  Swifty Reminder
//
//  Created by James Fehr on 17/10/26.
//

import Foundation

/// A countdown timer. It stores when it ends rather than ticking,
/// so it keeps counting while the app is closed.
struct CountdownTimer: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String
    var duration: TimeInterval
    /// When the timer goes off; nil while paused
    var endDate: Date?
    /// Time left at the moment it was paused
    var pausedRemaining: TimeInterval

    init(label: String, duration: TimeInterval, start: Date = Date()) {
        id = UUID()
        self.label = label
        self.duration = duration
        endDate = start.addingTimeInterval(duration)
        pausedRemaining = duration
    }

    var isPaused: Bool {
        endDate == nil
    }

    var notificationIdentifier: String {
        "timer-\(id.uuidString)"
    }

    func remaining(at date: Date) -> TimeInterval {
        guard let endDate else { return pausedRemaining }
        return max(0, endDate.timeIntervalSince(date))
    }

    func isFinished(at date: Date) -> Bool {
        remaining(at: date) <= 0
    }

    /// "1:05:00" or "04:59", rounding up so it shows 00:00 only once time is up
    static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.up))
        let hours = total / 3600
        let minutes = total / 60 % 60
        let secs = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, secs)
            : String(format: "%02d:%02d", minutes, secs)
    }
}

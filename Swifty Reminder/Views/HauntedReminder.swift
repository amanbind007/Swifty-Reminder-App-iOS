//
//  HauntedReminder.swift
//  Swifty Reminder
//
//  Created by James Fehr on 17/10/26.
//

import CoreData
import SwiftUI

/// How spooky an unfinished reminder gets the longer it's overdue
enum HauntLevel: Int, Comparable {
    case calm, flicker, shake, ghost

    init(overdueBy seconds: TimeInterval) {
        switch seconds {
        case ..<0: self = .calm
        case ..<(24 * 60 * 60): self = .flicker
        case ..<(3 * 24 * 60 * 60): self = .shake
        default: self = .ghost
        }
    }

    static func < (lhs: HauntLevel, rhs: HauntLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Reminder {
    /// When the reminder is due: its date at its time, or the end of its date if it has no time.
    /// Reminders with only a time aren't tied to a day, so they're never overdue.
    var dueDate: Date? {
        guard let reminderDate else { return nil }
        let calendar = Calendar.current
        guard let reminderTime else {
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: reminderDate))
        }
        var components = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        let time = calendar.dateComponents([.hour, .minute], from: reminderTime)
        components.hour = time.hour
        components.minute = time.minute
        return calendar.date(from: components)
    }

    func hauntLevel(at date: Date = Date()) -> HauntLevel {
        guard !isCompleted, let dueDate else { return .calm }
        return HauntLevel(overdueBy: date.timeIntervalSince(dueDate))
    }

    /// Keeps each row's flicker and shake out of step with the others
    var hauntSeed: Double {
        Double(abs(objectID.hashValue % 1000)) / 100
    }
}

/// Flickers like a failing light once overdue, and shivers every few seconds after a day
struct Haunted: ViewModifier {
    let level: HauntLevel
    let seed: Double

    @ViewBuilder
    func body(content: Content) -> some View {
        if level == .calm {
            content
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                let t = context.date.timeIntervalSinceReferenceDate + seed
                content
                    .opacity(Self.flicker(t))
                    .offset(x: level >= .shake ? Self.shiver(t) : 0)
            }
        }
    }

    /// Mostly steady, with the odd stutter
    private static func flicker(_ t: Double) -> Double {
        switch t.truncatingRemainder(dividingBy: 3.7) {
        case 0..<0.07, 0.16..<0.22, 2.1..<2.15: return 0.3
        default: return 1
        }
    }

    /// A short, fading shake every few seconds
    private static func shiver(_ t: Double) -> CGFloat {
        let phase = t.truncatingRemainder(dividingBy: 2.9)
        guard phase < 0.45 else { return 0 }
        return CGFloat(sin(phase * 70) * 3 * (1 - phase / 0.45))
    }
}

/// The ghost that moves in once a reminder has been ignored for three days
struct GhostPerch: View {
    let seed: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate + seed
            Text("👻")
                .font(.title3)
                .offset(y: CGFloat(sin(t * 2.2) * 3))
                .rotationEffect(.degrees(sin(t * 1.3) * 8))
        }
    }
}

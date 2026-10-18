//
//  TimerStore.swift
//  Swifty Reminder
//
//  Created by James Fehr on 17/10/26.
//

import Foundation

/// The user's timers, saved between launches. Each running timer has a
/// notification scheduled for when it ends, so it goes off even if the app is closed.
final class TimerStore: ObservableObject {
    private static let storageKey = "countdownTimers"

    @Published private(set) var timers: [CountdownTimer] = [] {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode([CountdownTimer].self, from: data) {
            timers = saved
        }
    }

    func start(label: String, duration: TimeInterval) {
        let timer = CountdownTimer(label: label, duration: duration)
        timers.append(timer)
        NotificationManager.scheduleTimerNotification(for: timer)
    }

    func pause(_ timer: CountdownTimer) {
        guard let index = index(of: timer), let endDate = timers[index].endDate else { return }
        timers[index].pausedRemaining = max(0, endDate.timeIntervalSinceNow)
        timers[index].endDate = nil
        NotificationManager.cancelTimerNotification(for: timer)
    }

    func resume(_ timer: CountdownTimer) {
        guard let index = index(of: timer), timers[index].isPaused else { return }
        timers[index].endDate = Date().addingTimeInterval(timers[index].pausedRemaining)
        NotificationManager.scheduleTimerNotification(for: timers[index])
    }

    func restart(_ timer: CountdownTimer) {
        guard let index = index(of: timer) else { return }
        timers[index].endDate = Date().addingTimeInterval(timers[index].duration)
        timers[index].pausedRemaining = timers[index].duration
        NotificationManager.scheduleTimerNotification(for: timers[index])
    }

    func remove(atOffsets offsets: IndexSet) {
        offsets.forEach { NotificationManager.cancelTimerNotification(for: timers[$0]) }
        timers.remove(atOffsets: offsets)
    }

    private func index(of timer: CountdownTimer) -> Int? {
        timers.firstIndex { $0.id == timer.id }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(timers) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

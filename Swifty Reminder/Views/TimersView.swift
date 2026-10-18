//
//  TimersView.swift
//  Swifty Reminder
//
//  Created by James Fehr on 17/10/26.
//

import SwiftUI
import UIKit

struct TimersView: View {
    @StateObject private var store = TimerStore()
    @State private var duration: TimeInterval = 5 * 60
    @State private var label: String = ""

    private let presets: [TimeInterval] = [1 * 60, 5 * 60, 10 * 60, 25 * 60]

    var body: some View {
        List {
            Section("New Timer") {
                CountdownPicker(duration: $duration)
                    .frame(maxWidth: .infinity)

                HStack {
                    ForEach(presets, id: \.self) { preset in
                        Button("\(Int(preset / 60)) min") {
                            duration = preset
                        }
                        .buttonStyle(.borderless)
                        .font(.subheadline.bold())
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Color.pumpkin.opacity(duration == preset ? 0.35 : 0.12))
                        .clipShape(Capsule())
                    }
                }

                TextField("Label (optional)", text: $label)

                Button {
                    store.start(label: label, duration: duration)
                    WitchTaunter.shared.react(to: .timerStarted(label: label, minutes: Int(duration / 60)))
                    label = ""
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .disabled(duration < 60)
            }
            .listRowBackground(Color.cauldron)

            Section("Timers") {
                if store.timers.isEmpty {
                    Text("No timers yet")
                        .opacity(0.5)
                } else {
                    ForEach(store.timers) { timer in
                        TimerRow(timer: timer, store: store)
                    }
                    .onDelete(perform: store.remove(atOffsets:))
                }
            }
            .listRowBackground(Color.cauldron)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.midnight.ignoresSafeArea())
        .navigationTitle("Timers")
    }
}

private struct TimerRow: View {
    let timer: CountdownTimer
    @ObservedObject var store: TimerStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let remaining = timer.remaining(at: context.date)
            let finished = timer.isFinished(at: context.date)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.pumpkin.opacity(0.2), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: timer.duration > 0 ? remaining / timer.duration : 0)
                        .stroke(Color.pumpkin, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(CountdownTimer.clock(remaining))
                        .font(.title2.monospacedDigit())
                        .foregroundColor(finished ? .pumpkin : .boneWhite)
                    Text(subtitle(finished: finished))
                        .font(.caption)
                        .opacity(0.6)
                }

                Spacer()

                Button {
                    if finished {
                        store.restart(timer)
                    } else if timer.isPaused {
                        store.resume(timer)
                    } else {
                        store.pause(timer)
                    }
                } label: {
                    Image(systemName: finished ? "arrow.counterclockwise" : timer.isPaused ? "play.fill" : "pause.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color.pumpkin.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 4)
        }
    }

    private func subtitle(finished: Bool) -> String {
        let name = timer.label.isEmpty ? CountdownTimer.clock(timer.duration) + " timer" : timer.label
        if finished {
            return name + " · Time's up!"
        }
        return timer.isPaused ? name + " · Paused" : name
    }
}

/// The iPhone Clock app's hours-and-minutes wheel
private struct CountdownPicker: UIViewRepresentable {
    @Binding var duration: TimeInterval

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .countDownTimer
        picker.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        // Set after it's on screen; otherwise the first spin doesn't report a change (a UIKit quirk)
        let initial = duration
        DispatchQueue.main.async { picker.countDownDuration = initial }
        return picker
    }

    func updateUIView(_ picker: UIDatePicker, context: Context) {
        context.coordinator.parent = self
        if picker.countDownDuration != duration {
            picker.countDownDuration = duration
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject {
        var parent: CountdownPicker

        init(parent: CountdownPicker) {
            self.parent = parent
        }

        @objc func changed(_ picker: UIDatePicker) {
            parent.duration = picker.countDownDuration
        }
    }
}

struct TimersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TimersView()
        }
    }
}

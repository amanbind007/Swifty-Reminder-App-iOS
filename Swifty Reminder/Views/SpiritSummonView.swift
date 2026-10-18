//
//  SpiritSummonView.swift
//  Swifty Reminder
//
//  Created by James Fehr on 17/10/26.
//

import AVFoundation
import SwiftUI
import UIKit

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

// UIKit only reports shakes to the responder chain, so pass them on for SwiftUI to hear
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

/// Shake the phone and the spirits pick an unfinished reminder for you to do next.
struct SpiritSummonView: View {
    @State private var isShowing = false
    @State private var revealed = false
    @State private var chosen: Reminder?
    @State private var summonID = UUID()
    @State private var cackle: AVAudioPlayer?

    var body: some View {
        ZStack {
            if isShowing {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .onTapGesture(perform: close)
                    .transition(.opacity)

                card
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: isShowing)
        .animation(.easeIn(duration: 0.8), value: revealed)
        .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
            summon()
        }
    }

    private var card: some View {
        VStack(spacing: 16) {
            Text("🔮")
                .font(.system(size: 84))
                .shadow(color: Color.witchPurple.opacity(0.9), radius: revealed ? 34 : 10)

            if let chosen {
                Text(revealed ? "The spirits have chosen…" : "Summoning the spirits…")
                    .font(.headline)
                    .foregroundColor(.boneWhite.opacity(0.8))

                if revealed {
                    Text(chosen.title ?? "")
                        .font(.title.bold())
                        .foregroundColor(.pumpkin)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.pumpkin.opacity(0.6), radius: 10)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))

                    if let listName = chosen.list?.name {
                        Text("from \(listName)")
                            .font(.subheadline)
                            .foregroundColor(.boneWhite.opacity(0.6))
                    }

                    HStack(spacing: 12) {
                        Button("Not now", action: close)
                            .buttonStyle(.bordered)
                        Button("Done!") {
                            complete(chosen)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 6)
                }
            } else {
                Text("The spirits are pleased.\nNothing left to do!")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.boneWhite)
                Button("Close", action: close)
                    .buttonStyle(.bordered)
            }
        }
        .padding(28)
        .frame(maxWidth: 340)
        .background(Color.cauldron)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.pumpkin.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: Color.witchPurple.opacity(0.5), radius: 30)
        .padding(32)
    }

    private func summon() {
        guard !isShowing else { return }

        let open = (try? ReminderService.viewContext.fetch(ReminderService.remindersByStatType(statType: .all))) ?? []
        chosen = open.randomElement()
        revealed = false
        isShowing = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        playCackle()

        // Let the crystal ball glow for a moment before the answer appears
        let id = UUID()
        summonID = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            if summonID == id {
                revealed = true
            }
        }
    }

    private func complete(_ reminder: Reminder) {
        var editConfig = ReminderEditConfig(reminder: reminder)
        editConfig.isCompleted = true
        // Also cancels its notifications and updates Apple's Reminders app
        _ = try? ReminderService.updateReminder(reminder: reminder, editConfig: editConfig)
        close()
    }

    private func close() {
        isShowing = false
        revealed = false
        summonID = UUID()
    }

    private func playCackle() {
        // Mix with other audio and stay quiet when the ringer is on silent
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        guard let url = Bundle.main.url(forResource: "witch_laugh", withExtension: "wav") else { return }
        cackle = try? AVAudioPlayer(contentsOf: url)
        cackle?.volume = 0.7
        cackle?.play()
    }
}

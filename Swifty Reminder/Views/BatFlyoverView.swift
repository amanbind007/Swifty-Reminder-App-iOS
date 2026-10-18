//
//  BatFlyoverView.swift
//  Swifty Reminder
//
//  Created by James Fehr on 17/10/26.
//

import AVFoundation
import SwiftUI

/// A bat that flies across the screen every couple of minutes, squeaking as it goes.
struct BatFlyoverView: View {
    private struct Flight {
        let start: Date
        let frames: [UIImage]
        let squeaks: [AVAudioPlayer]
        let verticalPosition: CGFloat // 0 = top of the screen, 1 = bottom
        let mirrored: Bool
    }

    private static let interval: Duration = .seconds(120)
    private static let squeakCount = 9
    // When the squeaks play, in seconds from the start of the flight
    private static let squeakTimes: [TimeInterval] = [0.9, 2.8, 4.7]

    @Environment(\.scenePhase) private var scenePhase
    @State private var flight: Flight?

    var body: some View {
        GeometryReader { geo in
            if let flight {
                TimelineView(.animation) { context in
                    let index = Int(context.date.timeIntervalSince(flight.start) * BatFlightPath.fps)
                    ZStack {
                        if flight.frames.indices.contains(index) {
                            batFrame(flight.frames[index], rect: BatFlightPath.frames[index], in: geo.size, flight: flight)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .scaleEffect(x: flight.mirrored ? -1 : 1, y: 1)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.interval)
                if scenePhase == .active {
                    await fly()
                }
            }
        }
    }

    private func batFrame(_ image: UIImage, rect: CGRect, in size: CGSize, flight: Flight) -> some View {
        // The video's 16:9 frame spans the screen width, at a random height for each flight
        let bandWidth = size.width
        let bandHeight = bandWidth * 9 / 16
        let bandTop = flight.verticalPosition * max(0, size.height - bandHeight)

        return Image(uiImage: image)
            .resizable()
            .frame(width: rect.width * bandWidth, height: rect.height * bandHeight)
            // Orange glow so the black bat shows up against the dark background
            .shadow(color: Color.pumpkin.opacity(0.9), radius: 3)
            .shadow(color: Color.pumpkin.opacity(0.5), radius: 10)
            .position(x: rect.midX * bandWidth, y: bandTop + rect.midY * bandHeight)
    }

    @MainActor
    private func fly() async {
        let frames = await Self.loadFrames()
        guard frames.count == BatFlightPath.frames.count else { return }

        flight = Flight(
            start: Date(),
            frames: frames,
            squeaks: Self.playSqueaks(),
            verticalPosition: .random(in: 0.05...0.55),
            mirrored: .random()
        )
        try? await Task.sleep(for: .seconds(Double(frames.count) / BatFlightPath.fps))
        flight = nil
    }

    private static func loadFrames() async -> [UIImage] {
        await Task.detached(priority: .userInitiated) {
            (0..<BatFlightPath.frames.count).compactMap { i in
                Bundle.main.path(forResource: String(format: "bat_%03d", i), ofType: "png", inDirectory: "BatFlight")
                    .flatMap { UIImage(contentsOfFile: $0)?.preparingForDisplay() }
            }
        }.value
    }

    private static func playSqueaks() -> [AVAudioPlayer] {
        // Mix with other audio and stay quiet when the ringer is on silent
        try? AVAudioSession.sharedInstance().setCategory(.ambient)

        let picks = (0..<squeakCount).shuffled()
        return zip(squeakTimes, picks).compactMap { time, pick in
            guard let url = Bundle.main.url(forResource: "squeak_\(pick)", withExtension: "wav", subdirectory: "BatFlight"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
            player.volume = 0.6
            player.prepareToPlay()
            player.play(atTime: player.deviceCurrentTime + time + .random(in: -0.3...0.3))
            return player
        }
    }
}

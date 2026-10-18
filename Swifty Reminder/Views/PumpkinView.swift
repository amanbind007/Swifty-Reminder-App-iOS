//
//  PumpkinView.swift
//  Swifty Reminder
//
//  Created by James Fehr on 17/10/26.
//

import SwiftUI

// Shared with the widget, so this file only draws: no Core Data here.

/// A pumpkin inside a ring of the list's colour
struct PumpkinBadge: View {
    let color: Color
    var rot: Double = 0
    var lit: Bool = true

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                Circle()
                    .strokeBorder(color, lineWidth: max(1.5, size * 0.06))
                PumpkinView(rot: rot, lit: lit)
                    .padding(size * 0.14)
            }
            .frame(width: size, height: size)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// A little pumpkin drawn in code. `rot` runs from 0 (fresh) to 1 (mouldy, drooping, with a fly);
/// `lit` glows and flickers like a jack-o'-lantern with a candle inside.
struct PumpkinView: View {
    var rot: Double
    var lit: Bool

    @State private var flicker = false

    /// Fresh with 1–2 reminders left, going off from 3, fully rotten at 7 or more
    static func rot(forOpenCount count: Int) -> Double {
        min(1, max(0, Double(count - 2) / 5))
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let drooping = rot > 0.85

            ZStack {
                // Stem
                Capsule()
                    .fill(Self.stemColor(rot))
                    .frame(width: size * 0.12, height: size * 0.24)
                    .rotationEffect(.degrees(14))
                    .offset(x: size * 0.03, y: -size * 0.34)

                // Body: two shaded side ribs behind a brighter middle one
                Group {
                    Ellipse()
                        .fill(Self.skinColor(rot, brightness: 0.72))
                        .frame(width: size * 0.56, height: size * 0.68)
                        .offset(x: -size * 0.19)
                    Ellipse()
                        .fill(Self.skinColor(rot, brightness: 0.72))
                        .frame(width: size * 0.56, height: size * 0.68)
                        .offset(x: size * 0.19)
                    Ellipse()
                        .fill(Self.skinColor(rot))
                        .frame(width: size * 0.50, height: size * 0.74)
                }
                .offset(y: size * 0.08)

                rotSpots(size)

                face(size)
                    .offset(y: size * 0.10)

                if drooping {
                    Text("🪰")
                        .font(.system(size: size * 0.26))
                        .offset(x: flicker ? size * 0.44 : size * 0.32,
                                y: flicker ? -size * 0.42 : -size * 0.30)
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(x: drooping ? 1.06 : 1, y: drooping ? 0.86 : 1, anchor: .bottom)
            .shadow(color: lit ? Color.pumpkin.opacity(flicker ? 0.9 : 0.5) : .clear,
                    radius: lit ? size * (flicker ? 0.22 : 0.14) : 0)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true)) {
                flicker = true
            }
        }
    }

    private func face(_ size: CGFloat) -> some View {
        let carving = lit ? Color.candleGlow : Color(red: 0.16, green: 0.08, blue: 0.03)
        return ZStack {
            Triangle()
                .fill(carving)
                .frame(width: size * 0.14, height: size * 0.12)
                .offset(x: -size * 0.12, y: -size * 0.08)
            Triangle()
                .fill(carving)
                .frame(width: size * 0.14, height: size * 0.12)
                .offset(x: size * 0.12, y: -size * 0.08)
            JackMouth()
                .fill(carving)
                .frame(width: size * 0.38, height: size * 0.14)
                .offset(y: size * 0.10)
        }
        .shadow(color: lit ? Color.candleGlow.opacity(flicker ? 1 : 0.6) : .clear, radius: size * 0.06)
    }

    @ViewBuilder
    private func rotSpots(_ size: CGFloat) -> some View {
        if rot > 0.3 {
            spot(Color.black.opacity(0.35), diameter: size * 0.09, x: -size * 0.22, y: size * 0.24)
        }
        if rot > 0.5 {
            spot(Color.black.opacity(0.35), diameter: size * 0.07, x: size * 0.25, y: size * 0.02)
        }
        if rot > 0.7 {
            spot(Color.slimeGreen.opacity(0.75), diameter: size * 0.13, x: size * 0.17, y: size * 0.27)
            spot(Color.slimeGreen.opacity(0.6), diameter: size * 0.08, x: -size * 0.07, y: -size * 0.16)
        }
    }

    private func spot(_ color: Color, diameter: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
            .offset(x: x, y: y)
    }

    /// Orange when fresh, brown as it rots, sickly olive at the end
    private static func skinColor(_ rot: Double, brightness: Double = 1) -> Color {
        let fresh = (r: 1.00, g: 0.46, b: 0.09)
        let rotting = (r: 0.55, g: 0.36, b: 0.14)
        let mouldy = (r: 0.38, g: 0.40, b: 0.17)
        let t = min(max(rot, 0), 1)
        let (from, to, u) = t < 0.5 ? (fresh, rotting, t / 0.5) : (rotting, mouldy, (t - 0.5) / 0.5)
        return Color(red: (from.r + (to.r - from.r) * u) * brightness,
                     green: (from.g + (to.g - from.g) * u) * brightness,
                     blue: (from.b + (to.b - from.b) * u) * brightness)
    }

    /// Green when fresh, withering to dark brown
    private static func stemColor(_ rot: Double) -> Color {
        let t = min(max(rot, 0), 1)
        return Color(red: 0.30 - 0.12 * t, green: 0.48 - 0.36 * t, blue: 0.16 - 0.08 * t)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A grin with two teeth hanging from the top lip
private struct JackMouth: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        for (x, y) in [(0.30, 0.25), (0.30, 0.55), (0.42, 0.55), (0.42, 0.30),
                       (0.58, 0.30), (0.58, 0.55), (0.70, 0.55), (0.70, 0.25)] {
            path.addLine(to: CGPoint(x: rect.minX + w * x, y: rect.minY + h * y))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY),
                          control: CGPoint(x: rect.midX, y: rect.maxY + h * 0.6))
        path.closeSubpath()
        return path
    }
}

struct PumpkinView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 12) {
            PumpkinBadge(color: .pumpkin, rot: 0, lit: true)
            PumpkinBadge(color: .witchPurple, rot: 0, lit: false)
            PumpkinBadge(color: .slimeGreen, rot: 0.4, lit: false)
            PumpkinBadge(color: .bloodRed, rot: 0.75, lit: false)
            PumpkinBadge(color: .candleGlow, rot: 1, lit: false)
        }
        .frame(height: 60)
        .padding()
        .background(Color.midnight)
    }
}

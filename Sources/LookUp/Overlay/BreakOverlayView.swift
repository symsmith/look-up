import LookUpCore
import SwiftUI

struct BreakOverlayView: View {
    let model: OverlayModel

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                let elapsed = context.date.timeIntervalSince(model.startDate)
                ZStack {
                    NightBackground()
                    BreathingOrb(
                        level: Breathing.level(at: elapsed),
                        elapsed: elapsed,
                        diameter: min(geometry.size.width, geometry.size.height) * 0.62
                    )
                    MessageBlock(
                        message: model.message,
                        remaining: model.endDate.timeIntervalSince(context.date),
                        width: geometry.size.width
                    )
                    VStack {
                        Spacer()
                        SkipButton(action: model.onSkip)
                            .padding(.bottom, geometry.size.height * 0.08)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
    }
}

private enum Palette {
    static let night = Color(red: 0.04, green: 0.05, blue: 0.07)
    static let indigo = Color(red: 0.09, green: 0.09, blue: 0.14)
    static let deepTeal = Color(red: 0.05, green: 0.08, blue: 0.09)
    static let teal = Color(red: 0.62, green: 0.80, blue: 0.80)
    static let periwinkle = Color(red: 0.62, green: 0.64, blue: 0.82)
    static let violet = Color(red: 0.66, green: 0.60, blue: 0.80)
}

private struct NightBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.night, Palette.indigo, Palette.deepTeal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.88)
            RadialGradient(
                colors: [.clear, Palette.night.opacity(0.6)],
                center: .center,
                startRadius: 200,
                endRadius: 1400
            )
        }
    }
}

private struct BreathingOrb: View {
    let level: Double
    let elapsed: TimeInterval
    let diameter: CGFloat

    var body: some View {
        ZStack {
            glow(Palette.violet, size: 1.5, opacity: 0.08 + 0.07 * level)
            glow(Palette.periwinkle, size: 1.1, opacity: 0.10 + 0.08 * level)
            glow(Palette.teal, size: 0.85, opacity: 0.14 + 0.12 * level)
            glow(.white, size: 0.3, opacity: 0.03 + 0.05 * level)
            ring
        }
        .scaleEffect(0.65 + 0.35 * level)
        .allowsHitTesting(false)
    }

    private func glow(_ color: Color, size: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(RadialGradient(
                colors: [color.opacity(opacity), color.opacity(opacity * 0.35), .clear],
                center: .center,
                startRadius: 0,
                endRadius: diameter * size / 2
            ))
            .frame(width: diameter * size, height: diameter * size)
    }

    private var ring: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    colors: [Palette.teal.opacity(0.5), .clear, Palette.violet.opacity(0.45), .clear, Palette.teal.opacity(0.5)],
                    center: .center
                ),
                lineWidth: 1.2
            )
            .frame(width: diameter * 0.92, height: diameter * 0.92)
            .rotationEffect(.degrees(elapsed * 3))
            .opacity(0.25 + 0.25 * level)
    }
}

private struct MessageBlock: View {
    let message: String
    let remaining: TimeInterval
    let width: CGFloat

    var body: some View {
        Text(message)
            .font(.system(size: min(44, max(34, width * 0.027)), weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.35), radius: 14, y: 2)
            .frame(maxWidth: width * 0.7)
            .fixedSize(horizontal: false, vertical: true)
            .overlay(alignment: .bottom) {
                Text(Self.format(remaining))
                    .font(.system(size: 16, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
                    .alignmentGuide(.bottom) { $0[.top] - 28 }
            }
    }

    private static func format(_ remaining: TimeInterval) -> String {
        let seconds = Int(max(0, remaining).rounded(.up))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private struct SkipButton: View {
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text("Skip")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .padding(.horizontal, 18)
                .padding(.vertical, 7)
                .background(Capsule().strokeBorder(.white.opacity(isHovering ? 0.35 : 0.15)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(isHovering ? 0.9 : 0.4))
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.2), value: isHovering)
    }
}

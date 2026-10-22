import Foundation

public enum Breathing {
    public static let inhale: TimeInterval = 4
    public static let hold: TimeInterval = 1
    public static let exhale: TimeInterval = 5
    public static var cycle: TimeInterval { inhale + hold + exhale }

    public enum Stage: Equatable, Sendable { case inhale, hold, exhale }

    public static func level(at elapsed: TimeInterval) -> Double {
        let t = phase(at: elapsed)
        let value: Double
        switch stage(atPhase: t) {
        case .inhale:
            value = easeInOut(t / inhale)
        case .hold:
            value = 1
        case .exhale:
            value = 1 - easeInOut((t - inhale - hold) / exhale)
        }
        return min(max(value, 0), 1)
    }

    public static func stage(at elapsed: TimeInterval) -> Stage {
        stage(atPhase: phase(at: elapsed))
    }

    private static func phase(at elapsed: TimeInterval) -> TimeInterval {
        max(elapsed, 0).truncatingRemainder(dividingBy: cycle)
    }

    private static func stage(atPhase t: TimeInterval) -> Stage {
        if t < inhale { return .inhale }
        if t < inhale + hold { return .hold }
        return .exhale
    }

    private static func easeInOut(_ x: Double) -> Double {
        (1 - cos(.pi * x)) / 2
    }
}

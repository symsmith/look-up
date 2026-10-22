import Foundation

public enum Breathing {
    public static let inhale: TimeInterval = 4
    public static let hold: TimeInterval = 1
    public static let exhale: TimeInterval = 5
    public static var cycle: TimeInterval { inhale + hold + exhale }

    public static func level(at elapsed: TimeInterval) -> Double {
        let t = max(elapsed, 0).truncatingRemainder(dividingBy: cycle)
        let value: Double
        if t < inhale {
            value = easeInOut(t / inhale)
        } else if t < inhale + hold {
            value = 1
        } else {
            value = 1 - easeInOut((t - inhale - hold) / exhale)
        }
        return min(max(value, 0), 1)
    }

    private static func easeInOut(_ x: Double) -> Double {
        (1 - cos(.pi * x)) / 2
    }
}

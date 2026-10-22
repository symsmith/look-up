import Foundation
import Testing
@testable import LookUpCore

struct BreathingTests {
    private let tolerance = 1e-9

    @Test func cycleIsTenSeconds() {
        #expect(Breathing.cycle == 10)
    }

    @Test func endpoints() {
        #expect(abs(Breathing.level(at: 0)) < tolerance)
        #expect(abs(Breathing.level(at: Breathing.inhale) - 1) < tolerance)
        #expect(abs(Breathing.level(at: Breathing.inhale + Breathing.hold) - 1) < tolerance)
        #expect(abs(Breathing.level(at: Breathing.cycle - 1e-9)) < 1e-6)
    }

    @Test func midpoints() {
        #expect(abs(Breathing.level(at: Breathing.inhale / 2) - 0.5) < tolerance)
        let midExhale = Breathing.inhale + Breathing.hold + Breathing.exhale / 2
        #expect(abs(Breathing.level(at: midExhale) - 0.5) < tolerance)
    }

    @Test(arguments: [4.0, 4.25, 4.5, 4.75, 4.999])
    func holdPlateau(elapsed: TimeInterval) {
        #expect(Breathing.level(at: elapsed) == 1)
    }

    @Test(arguments: [0.0, 1.3, 4.5, 7.2, 9.9])
    func periodic(elapsed: TimeInterval) {
        let base = Breathing.level(at: elapsed)
        for k in 1...3 {
            #expect(abs(Breathing.level(at: elapsed + Double(k) * Breathing.cycle) - base) < 1e-6)
            #expect(Breathing.stage(at: elapsed + Double(k) * Breathing.cycle) == Breathing.stage(at: elapsed))
        }
    }

    @Test func risesMonotonicallyDuringInhale() {
        let samples = stride(from: 0.0, through: Breathing.inhale, by: 0.05).map(Breathing.level(at:))
        #expect(zip(samples, samples.dropFirst()).allSatisfy { $0 < $1 })
    }

    @Test func fallsMonotonicallyDuringExhale() {
        let start = Breathing.inhale + Breathing.hold
        let samples = stride(from: start, to: Breathing.cycle, by: 0.05).map(Breathing.level(at:))
        #expect(zip(samples, samples.dropFirst()).allSatisfy { $0 > $1 })
    }

    @Test func stageBoundaries() {
        #expect(Breathing.stage(at: 0) == .inhale)
        #expect(Breathing.stage(at: 3.999) == .inhale)
        #expect(Breathing.stage(at: 4) == .hold)
        #expect(Breathing.stage(at: 4.999) == .hold)
        #expect(Breathing.stage(at: 5) == .exhale)
        #expect(Breathing.stage(at: 9.999) == .exhale)
        #expect(Breathing.stage(at: 10) == .inhale)
    }

    @Test func negativeElapsedIsTreatedAsZero() {
        #expect(Breathing.level(at: -3) == Breathing.level(at: 0))
        #expect(Breathing.stage(at: -3) == .inhale)
    }

    @Test func staysInUnitRange() {
        for elapsed in stride(from: -5.0, through: 35.0, by: 0.01) {
            let level = Breathing.level(at: elapsed)
            #expect((0...1).contains(level))
        }
    }
}

import Foundation
import Testing
@testable import LookUpCore

private struct Harness {
    var scheduler: BreakScheduler
    var now = Date(timeIntervalSinceReferenceDate: 0)

    init(_ settings: BreakSettings = BreakSettings(interval: 60, duration: 10)) {
        scheduler = BreakScheduler(settings: settings, now: now)
    }

    var phase: SchedulerPhase { scheduler.phase }

    @discardableResult
    mutating func tick(_ seconds: Int, pause: PauseReason? = nil) -> [SchedulerEvent] {
        (0..<seconds).compactMap { _ in
            now += 1
            return scheduler.update(now: now, pauseReason: pause)
        }
    }

    @discardableResult
    mutating func jump(_ seconds: TimeInterval, pause: PauseReason? = nil) -> SchedulerEvent? {
        now += seconds
        return scheduler.update(now: now, pauseReason: pause)
    }

    mutating func apply(_ change: (inout BreakSettings) -> Void) -> SchedulerEvent? {
        var settings = scheduler.settings
        change(&settings)
        return scheduler.apply(settings, now: now)
    }

    mutating func startBreakNow() -> SchedulerEvent? {
        scheduler.startBreakNow(now: now)
    }

    mutating func skipBreak() -> SchedulerEvent? {
        scheduler.skipBreak(now: now)
    }

    mutating func restartCountdown() {
        scheduler.restartCountdown(now: now)
    }
}

struct BreakSchedulerTests {
    @Test func initialPhaseIsFullInterval() {
        #expect(Harness().phase == .working(remaining: 60))
    }

    @Test func initialPhaseWhenDisabled() {
        #expect(Harness(BreakSettings(isEnabled: false)).phase == .disabled)
    }

    @Test func countdownDecreases() {
        var h = Harness()
        #expect(h.tick(15).isEmpty)
        #expect(h.phase == .working(remaining: 45))
    }

    @Test func breakStartsAtInterval() {
        var h = Harness()
        #expect(h.tick(59).isEmpty)
        #expect(h.tick(1) == [.breakStarted])
        #expect(h.phase == .onBreak(remaining: 10))
    }

    @Test func breakEndsAfterDurationAndCountdownRestarts() {
        var h = Harness()
        h.tick(60)
        h.tick(4)
        #expect(h.phase == .onBreak(remaining: 6))
        #expect(h.tick(6) == [.breakEnded])
        #expect(h.phase == .working(remaining: 60))
        h.tick(1)
        #expect(h.phase == .working(remaining: 59))
    }

    @Test func pauseFreezesAndResumes() {
        var h = Harness()
        h.tick(20)
        #expect(h.tick(300, pause: .mediaPlaying).isEmpty)
        #expect(h.phase == .paused(.mediaPlaying, remaining: 40))
        h.tick(1, pause: .inCall)
        #expect(h.phase == .paused(.inCall, remaining: 40))
        h.tick(10)
        #expect(h.phase == .working(remaining: 30))
    }

    @Test func pauseDuringBreakDoesNotInterruptIt() {
        var h = Harness()
        h.tick(60)
        h.tick(5, pause: .inCall)
        #expect(h.phase == .onBreak(remaining: 5))
        #expect(h.tick(5, pause: .inCall) == [.breakEnded])
        #expect(h.phase == .paused(.inCall, remaining: 60))
    }

    @Test func sleepGapRestartsCountdown() {
        var h = Harness()
        h.tick(50)
        #expect(h.jump(BreakScheduler.maxTickGap + 1) == nil)
        #expect(h.phase == .working(remaining: 60))
    }

    @Test func gapAtThresholdCountsAsElapsed() {
        var h = Harness()
        h.tick(10)
        #expect(h.jump(BreakScheduler.maxTickGap) == nil)
        #expect(h.phase == .working(remaining: 20))
    }

    @Test func sleepGapWhilePausedRestartsCountdown() {
        var h = Harness()
        h.tick(50)
        h.jump(3600, pause: .mediaPlaying)
        #expect(h.phase == .paused(.mediaPlaying, remaining: 60))
    }

    @Test func largeGapDuringBreakEndsIt() {
        var h = Harness(BreakSettings(interval: 60, duration: 120))
        h.tick(60)
        h.tick(2)
        #expect(h.jump(BreakScheduler.maxTickGap + 1) == .breakEnded)
        #expect(h.phase == .working(remaining: 60))
    }

    @Test func negativeDeltaCountsAsZero() {
        var h = Harness()
        h.tick(10)
        #expect(h.jump(-120) == nil)
        #expect(h.phase == .working(remaining: 50))
        h.tick(1)
        #expect(h.phase == .working(remaining: 49))
    }

    @Test func intervalChangeRestartsCountdown() {
        var h = Harness()
        h.tick(30)
        #expect(h.apply { $0.interval = 300 } == nil)
        #expect(h.phase == .working(remaining: 300))
    }

    @Test func intervalChangeDuringBreakKeepsBreak() {
        var h = Harness()
        h.tick(62)
        #expect(h.apply { $0.interval = 300 } == nil)
        #expect(h.phase == .onBreak(remaining: 8))
        h.tick(8)
        #expect(h.phase == .working(remaining: 300))
    }

    @Test func messageChangeHasNoSchedulingEffect() {
        var h = Harness()
        h.tick(30)
        #expect(h.apply { $0.message = "Blink" } == nil)
        #expect(h.phase == .working(remaining: 30))
    }

    @Test func applyCountsTimeSinceLastUpdate() {
        var h = Harness()
        h.tick(30)
        h.now += 0.5
        #expect(h.apply { $0.message = "Blink" } == nil)
        #expect(h.phase == .working(remaining: 29.5))
    }

    @Test func longerDurationExtendsCurrentBreak() {
        var h = Harness()
        h.tick(64)
        #expect(h.apply { $0.duration = 30 } == nil)
        #expect(h.phase == .onBreak(remaining: 26))
        #expect(h.tick(25).isEmpty)
        #expect(h.tick(1) == [.breakEnded])
    }

    @Test func shorterDurationShortensCurrentBreak() {
        var h = Harness(BreakSettings(interval: 60, duration: 30))
        h.tick(65)
        #expect(h.apply { $0.duration = 10 } == nil)
        #expect(h.phase == .onBreak(remaining: 5))
    }

    @Test func durationShorterThanElapsedEndsBreak() {
        var h = Harness(BreakSettings(interval: 60, duration: 30))
        h.tick(75)
        #expect(h.apply { $0.duration = 10 } == .breakEnded)
        #expect(h.phase == .working(remaining: 60))
    }

    @Test func durationChangeOutsideBreakKeepsCountdown() {
        var h = Harness()
        h.tick(30)
        #expect(h.apply { $0.duration = 45 } == nil)
        #expect(h.phase == .working(remaining: 30))
        h.tick(30)
        #expect(h.phase == .onBreak(remaining: 45))
    }

    @Test func disablingStopsCountdown() {
        var h = Harness()
        h.tick(30)
        #expect(h.apply { $0.isEnabled = false } == nil)
        #expect(h.phase == .disabled)
        #expect(h.tick(600).isEmpty)
        #expect(h.phase == .disabled)
    }

    @Test func disablingDuringBreakEndsIt() {
        var h = Harness()
        h.tick(62)
        #expect(h.apply { $0.isEnabled = false } == .breakEnded)
        #expect(h.phase == .disabled)
    }

    @Test func enablingStartsFreshInterval() {
        var h = Harness()
        h.tick(30)
        _ = h.apply { $0.isEnabled = false }
        h.tick(100)
        #expect(h.apply { $0.isEnabled = true } == nil)
        #expect(h.phase == .working(remaining: 60))
    }

    @Test func startBreakNowFromWorking() {
        var h = Harness()
        h.tick(10)
        #expect(h.startBreakNow() == .breakStarted)
        #expect(h.phase == .onBreak(remaining: 10))
        #expect(h.startBreakNow() == nil)
        #expect(h.tick(10) == [.breakEnded])
        #expect(h.phase == .working(remaining: 60))
    }

    @Test func startBreakNowWhilePaused() {
        var h = Harness()
        h.tick(10, pause: .mediaPlaying)
        #expect(h.startBreakNow() == .breakStarted)
        #expect(h.tick(10, pause: .mediaPlaying) == [.breakEnded])
        #expect(h.phase == .paused(.mediaPlaying, remaining: 60))
    }

    @Test func startBreakNowFromDisabledReturnsToDisabled() {
        var h = Harness(BreakSettings(isEnabled: false, interval: 60, duration: 10))
        #expect(h.startBreakNow() == .breakStarted)
        #expect(h.phase == .onBreak(remaining: 10))
        #expect(h.apply { $0.message = "Blink" } == nil)
        #expect(h.tick(10) == [.breakEnded])
        #expect(h.phase == .disabled)
    }

    @Test func enablingDuringManualBreakResumesAfterIt() {
        var h = Harness(BreakSettings(isEnabled: false, interval: 60, duration: 10))
        _ = h.startBreakNow()
        h.tick(3)
        #expect(h.apply { $0.isEnabled = true } == nil)
        #expect(h.phase == .onBreak(remaining: 7))
        #expect(h.tick(7) == [.breakEnded])
        #expect(h.phase == .working(remaining: 60))
    }

    @Test func skipBreakEndsItWithFreshCountdown() {
        var h = Harness()
        h.tick(63)
        #expect(h.skipBreak() == .breakEnded)
        #expect(h.phase == .working(remaining: 60))
        #expect(h.skipBreak() == nil)
    }

    @Test func restartCountdownResetsInterval() {
        var h = Harness()
        h.tick(40)
        h.restartCountdown()
        #expect(h.phase == .working(remaining: 60))
    }

    @Test func restartCountdownWhilePausedResetsInterval() {
        var h = Harness()
        h.tick(40)
        h.tick(10, pause: .inCall)
        #expect(h.phase == .paused(.inCall, remaining: 20))
        h.restartCountdown()
        #expect(h.phase == .paused(.inCall, remaining: 60))
    }

    @Test func restartCountdownHasNoEffectDuringBreak() {
        var h = Harness()
        h.tick(63)
        h.restartCountdown()
        #expect(h.phase == .onBreak(remaining: 7))
    }

    @Test func restartCountdownHasNoEffectWhenDisabled() {
        var h = Harness(BreakSettings(isEnabled: false))
        h.tick(10)
        h.restartCountdown()
        #expect(h.phase == .disabled)
    }
}

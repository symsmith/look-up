import Foundation

public enum SchedulerPhase: Equatable, Sendable {
    case disabled
    case working(remaining: TimeInterval)
    case paused(PauseReason, remaining: TimeInterval)
    case onBreak(remaining: TimeInterval)
}

public enum SchedulerEvent: Equatable, Sendable {
    case breakStarted
    case breakEnded
}

public struct BreakScheduler: Sendable {
    public static let maxTickGap: TimeInterval = 30

    public private(set) var settings: BreakSettings
    private var pauseReason: PauseReason?
    private var isOnBreak = false
    private var remaining: TimeInterval
    private var lastUpdate: Date

    public init(settings: BreakSettings, now: Date) {
        self.settings = settings
        remaining = settings.interval
        lastUpdate = now
    }

    public var phase: SchedulerPhase {
        let shown = max(0, remaining)
        if isOnBreak { return .onBreak(remaining: shown) }
        if !settings.isEnabled { return .disabled }
        if let pauseReason { return .paused(pauseReason, remaining: shown) }
        return .working(remaining: shown)
    }

    public mutating func update(now: Date, pauseReason: PauseReason?) -> SchedulerEvent? {
        self.pauseReason = pauseReason
        elapse(until: now)
        if isOnBreak, remaining <= 0 {
            endBreak()
            return .breakEnded
        }
        if !isOnBreak, isCounting, remaining <= 0 {
            startBreak()
            return .breakStarted
        }
        return nil
    }

    public mutating func apply(_ newSettings: BreakSettings, now: Date) -> SchedulerEvent? {
        elapse(until: now)
        let old = settings
        settings = newSettings
        if isOnBreak {
            remaining += newSettings.duration - old.duration
            if remaining <= 0 || (old.isEnabled && !newSettings.isEnabled) {
                endBreak()
                return .breakEnded
            }
        } else if newSettings.interval != old.interval || newSettings.isEnabled != old.isEnabled {
            remaining = newSettings.interval
        }
        return nil
    }

    public mutating func startBreakNow(now: Date) -> SchedulerEvent? {
        elapse(until: now)
        guard !isOnBreak else { return nil }
        startBreak()
        return .breakStarted
    }

    public mutating func skipBreak(now: Date) -> SchedulerEvent? {
        elapse(until: now)
        guard isOnBreak else { return nil }
        endBreak()
        return .breakEnded
    }

    public mutating func restartCountdown(now: Date) {
        elapse(until: now)
        if !isOnBreak {
            remaining = settings.interval
        }
    }

    private var isCounting: Bool {
        settings.isEnabled && pauseReason == nil
    }

    private mutating func elapse(until now: Date) {
        let delta = max(0, now.timeIntervalSince(lastUpdate))
        lastUpdate = now
        if delta > Self.maxTickGap {
            remaining = isOnBreak ? 0 : settings.interval
        } else if isOnBreak || isCounting {
            remaining -= delta
        }
    }

    private mutating func startBreak() {
        isOnBreak = true
        remaining = settings.duration
    }

    private mutating func endBreak() {
        isOnBreak = false
        remaining = settings.interval
    }
}

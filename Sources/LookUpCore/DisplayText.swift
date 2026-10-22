import Foundation

public enum DisplayText {
    public static func status(for phase: SchedulerPhase) -> String {
        switch phase {
        case .disabled:
            "Breaks disabled"
        case .working(let remaining):
            remaining < 60 ? "Next break in less than a minute" : "Next break in \(Int((remaining / 60).rounded(.up))) min"
        case .paused(.mediaPlaying, _):
            "Paused — media playing"
        case .paused(.inCall, _):
            "Paused — in a call"
        case .onBreak:
            "On a break"
        }
    }

    public static func symbol(for phase: SchedulerPhase) -> String {
        switch phase {
        case .disabled: "eye.slash"
        case .paused: "pause.circle"
        case .working, .onBreak: "eye"
        }
    }

    public static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let minutes = total / 60
        let rest = total % 60
        switch (minutes, rest) {
        case (0, _): return "\(rest) seconds"
        case (1, 0): return "1 minute"
        case (_, 0): return "\(minutes) minutes"
        default: return "\(minutes) min \(rest) sec"
        }
    }
}

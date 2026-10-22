public enum PauseReason: Equatable, Sendable {
    case mediaPlaying
    case inCall
}

public protocol ActivityDetecting {
    func currentPauseReason() -> PauseReason?
}

public struct PowerAssertion: Equatable, Sendable {
    public var pid: Int32
    public var processName: String
    public var type: String
    public var name: String

    public init(pid: Int32, processName: String, type: String, name: String) {
        self.pid = pid
        self.processName = processName
        self.type = type
        self.name = name
    }
}

public enum ActivityClassifier {
    static let displaySleepTypes: Set<String> = ["PreventUserIdleDisplaySleep", "NoDisplaySleepAssertion"]
    static let keepAwakeUtilities: Set<String> = ["caffeinate", "amphetamine", "keepingyouawake", "lungo", "theine"]

    public static func pauseReason(
        assertions: [PowerAssertion],
        ownPID: Int32,
        microphoneInUse: Bool,
        cameraInUse: Bool
    ) -> PauseReason? {
        if microphoneInUse || cameraInUse || assertions.contains(where: isCall) {
            return .inCall
        }
        if assertions.contains(where: { isMediaPlayback($0, ownPID: ownPID) }) {
            return .mediaPlaying
        }
        return nil
    }

    private static func isCall(_ assertion: PowerAssertion) -> Bool {
        assertion.name.lowercased().contains("webrtc")
    }

    private static func isMediaPlayback(_ assertion: PowerAssertion, ownPID: Int32) -> Bool {
        assertion.pid != ownPID
            && displaySleepTypes.contains(assertion.type)
            && !keepAwakeUtilities.contains(assertion.processName.lowercased())
    }
}

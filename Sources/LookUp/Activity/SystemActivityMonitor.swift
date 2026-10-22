import Darwin
import LookUpCore

final class SystemActivityMonitor: ActivityDetecting {
    private let ownPID = getpid()

    init() {}

    func currentPauseReason() -> PauseReason? {
        ActivityClassifier.pauseReason(
            assertions: PowerAssertionReader.current(),
            ownPID: ownPID,
            microphoneInUse: AudioInputProbe.isInUse(),
            cameraInUse: CameraProbe.isInUse()
        )
    }
}

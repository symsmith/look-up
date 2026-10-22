import Darwin
import LookUpCore

final class SystemActivityMonitor: ActivityDetecting {
    private let ownPID = getpid()

    func currentPauseReason() -> PauseReason? {
        ActivityClassifier.pauseReason(
            assertions: PowerAssertionReader.current(),
            ownPID: ownPID,
            microphoneInUse: AudioInputProbe.isInUse(excluding: ownPID),
            cameraInUse: CameraProbe.isInUse()
        )
    }
}

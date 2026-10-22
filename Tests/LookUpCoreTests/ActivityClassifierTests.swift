import Testing
@testable import LookUpCore

struct ActivityClassifierTests {
    private let ownPID: Int32 = 4242

    private let systemBaseline = [
        PowerAssertion(pid: 351, processName: "powerd", type: "PreventUserIdleSystemSleep", name: "Powerd - Prevent sleep while display is on"),
        PowerAssertion(pid: 351, processName: "powerd", type: "UserIsActive", name: "com.apple.powermanagement.lidopen"),
        PowerAssertion(pid: 410, processName: "WindowServer", type: "UserIsActive", name: "com.apple.iohideventsystem.queue.tickle serviceID:100000b15"),
        PowerAssertion(pid: 63343, processName: "bluetoothd", type: "UserIsActive", name: "Bluetooth LE HID Activity"),
        PowerAssertion(pid: 84849, processName: "Claude", type: "NoIdleSleepAssertion", name: "Electron"),
    ]

    private func reason(
        _ assertions: [PowerAssertion],
        microphoneInUse: Bool = false,
        cameraInUse: Bool = false
    ) -> PauseReason? {
        ActivityClassifier.pauseReason(
            assertions: systemBaseline + assertions,
            ownPID: ownPID,
            microphoneInUse: microphoneInUse,
            cameraInUse: cameraInUse
        )
    }

    @Test func emptyIsNil() {
        #expect(ActivityClassifier.pauseReason(assertions: [], ownPID: ownPID, microphoneInUse: false, cameraInUse: false) == nil)
    }

    @Test func idleSystemIsNil() {
        #expect(reason([]) == nil)
    }

    @Test func chromeVideoIsMediaPlaying() {
        let chrome = PowerAssertion(pid: 912, processName: "Google Chrome", type: "NoDisplaySleepAssertion", name: "Video Wake Lock")
        #expect(reason([chrome]) == .mediaPlaying)
    }

    @Test func screenWakeLockIsMediaPlaying() {
        let chrome = PowerAssertion(pid: 912, processName: "Google Chrome", type: "NoDisplaySleepAssertion", name: "Blink Wake Lock")
        #expect(reason([chrome]) == .mediaPlaying)
    }

    @Test func safariVideoIsMediaPlaying() {
        let safari = PowerAssertion(pid: 1530, processName: "Safari", type: "PreventUserIdleDisplaySleep", name: "com.apple.WebCore: HTMLMediaElement playback")
        #expect(reason([safari]) == .mediaPlaying)
    }

    @Test func webKitGPUProcessVideoIsMediaPlaying() {
        let gpu = PowerAssertion(pid: 1544, processName: "com.apple.WebKit.GPU", type: "PreventUserIdleDisplaySleep", name: "WebKit Media Playback")
        #expect(reason([gpu]) == .mediaPlaying)
    }

    @Test func chromeAudioOnlyIsNil() {
        let chrome = PowerAssertion(pid: 912, processName: "Google Chrome", type: "NoIdleSleepAssertion", name: "Playing audio")
        #expect(reason([chrome]) == nil)
    }

    @Test func safariAudioOnlyIsNil() {
        let safari = PowerAssertion(pid: 1530, processName: "Safari", type: "PreventUserIdleSystemSleep", name: "com.apple.WebCore: HTMLMediaElement playback")
        #expect(reason([safari]) == nil)
    }

    @Test func meetWebRTCIsInCall() {
        let chrome = PowerAssertion(pid: 912, processName: "Google Chrome", type: "NoIdleSleepAssertion", name: "WebRTC has active PeerConnections")
        #expect(reason([chrome]) == .inCall)
    }

    @Test func webRTCMatchIsCaseInsensitive() {
        let browser = PowerAssertion(pid: 913, processName: "Arc", type: "PreventUserIdleSystemSleep", name: "webrtc has active peerconnections")
        #expect(reason([browser]) == .inCall)
    }

    @Test func ownAssertionIsIgnored() {
        let own = PowerAssertion(pid: ownPID, processName: "Look Up", type: "PreventUserIdleDisplaySleep", name: "Look Up break")
        #expect(reason([own]) == nil)
    }

    @Test(arguments: ["caffeinate", "Amphetamine", "KeepingYouAwake", "Lungo", "Theine", "CAFFEINATE"])
    func keepAwakeUtilityIsIgnored(processName: String) {
        let utility = PowerAssertion(pid: 777, processName: processName, type: "PreventUserIdleDisplaySleep", name: "caffeinate command-line tool")
        #expect(reason([utility]) == nil)
    }

    @Test func keepAwakeUtilityDoesNotMaskRealPlayback() {
        let utility = PowerAssertion(pid: 777, processName: "caffeinate", type: "PreventUserIdleDisplaySleep", name: "caffeinate command-line tool")
        let chrome = PowerAssertion(pid: 912, processName: "Google Chrome", type: "NoDisplaySleepAssertion", name: "Video Wake Lock")
        #expect(reason([utility, chrome]) == .mediaPlaying)
    }

    @Test func microphoneIsInCall() {
        #expect(reason([], microphoneInUse: true) == .inCall)
    }

    @Test func cameraIsInCall() {
        #expect(reason([], cameraInUse: true) == .inCall)
    }

    @Test func callWinsOverMedia() {
        let video = PowerAssertion(pid: 912, processName: "Google Chrome", type: "NoDisplaySleepAssertion", name: "Video Wake Lock")
        let call = PowerAssertion(pid: 912, processName: "Google Chrome", type: "NoIdleSleepAssertion", name: "WebRTC has active PeerConnections")
        #expect(reason([video, call]) == .inCall)
        #expect(reason([video], microphoneInUse: true) == .inCall)
        #expect(reason([video], cameraInUse: true) == .inCall)
    }
}

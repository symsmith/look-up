# Look Up — Spec

A macOS menu bar app that applies the 20-20-20 rule: every N minutes, cover all screens with a calm breathing animation and a short message so the user looks away from the screen.

## Platform and stack

- macOS 14+ (uses `@Observable`, `MenuBarExtra`). Developed on macOS 26 / Xcode 26 / Swift 6.2.
- Swift Package Manager, Swift 6 language mode. No third-party dependencies.
- Targets:
  - `LookUpCore` (library): pure, UI-free logic. Everything here is unit tested.
  - `LookUp` (executable): AppKit/SwiftUI shell, system probes, overlay windows.
  - `LookUpCoreTests`: Swift Testing (`import Testing`).
- `scripts/build-app.sh` wraps the release binary into `build/LookUp.app` (with `Info.plist`, `LSUIElement = true`, ad-hoc signed). `make test`, `make app`, `make run`.

## User-facing behaviour

### Menu bar

- Icon: SF Symbol `eye` when active, `eye.slash` when disabled, `pause.circle` when paused.
- Native menu (`MenuBarExtra` with `.menu` style). Items, top to bottom:
  1. Status line (disabled item): `Next break in 12 min` / `Next break in less than a minute` / `Paused — media playing` / `Paused — in a call` / `On a break` / `Breaks disabled`.
  2. `Enabled` toggle (default on).
  3. `Break Interval` submenu: 5, 10, 15, 20, 25, 30, 45, 60 minutes (default 20). Checkmark on current value.
  4. `Break Duration` submenu: 10, 20, 30, 45 seconds, 1, 2 minutes (default 20 seconds).
  5. `Break Text…`: opens a native `NSAlert` with a text field, prefilled with the current text (default `Look at something far away`). Empty input restores the default.
  6. `Start Break Now`.
  7. Separator, `Quit Look Up` (⌘Q).
- Settings persist in `UserDefaults`.

### Break overlay

- One borderless window per screen, at `.screenSaver` level, joins all Spaces and full-screen apps.
- Content: dark vibrant background (blur of the desktop + deep gradient), a soft breathing orb (layered blurred circles that scale with the breathing curve), the break text centred in large rounded type, and a small remaining-seconds countdown. No breathing instructions are shown: the orb's slow motion is the only cue.
- Breathing curve: 4 s inhale, 1 s hold, 5 s exhale (10 s cycle), sine ease-in-out. Computed by a pure function of elapsed time, driven by `TimelineView(.animation)`.
- Fade in 0.6 s, fade out 0.6 s.
- `Esc` or a subtle `Skip` button ends the break early.
- The overlay closes itself when the scheduler emits `breakEnded`.

### Scheduling

- The countdown only runs while enabled and not paused. While paused, the countdown freezes; it resumes from where it stopped.
- When the countdown reaches 0, a break starts. When the break duration elapses, the break ends and a fresh full interval starts.
- A pause condition that appears during a break does not interrupt the break.
- Changing the interval restarts the countdown. Changing the duration during a break applies to the current break. Disabling during a break ends it. Enabling starts a fresh interval.
- `Start Break Now` works in every state. After a manual break, the next state follows the `Enabled` setting.
- Sleep / lock: a gap between two ticks larger than 30 s (machine slept) restarts the countdown. Screen unlock and display wake also restart it (the user was away).

### Pause detection ("is something more important happening?")

Polled every tick (1 s). All public APIs, no permission prompts.

- **In a call** (takes priority): any of
  - another process is capturing audio input (`kAudioHardwarePropertyProcessObjectList` + `kAudioProcessPropertyIsRunningInput`, CoreAudio, macOS 14+), so music on AirPods does not count;
  - a camera is running somewhere (`kCMIODevicePropertyDeviceIsRunningSomewhere`, CoreMediaIO);
  - a power assertion named like `WebRTC has active PeerConnections` (Chrome/Chromium during Google Meet and other WebRTC calls).
- **Media playing**: a process other than Look Up holds a `PreventUserIdleDisplaySleep` / `NoDisplaySleepAssertion` power assertion (`IOPMCopyAssertionsByProcess`). Browsers (YouTube, Netflix), QuickTime, IINA, VLC take this assertion during video playback. Known keep-awake utilities are ignored (`caffeinate`, `Amphetamine`, `KeepingYouAwake`, `Lungo`, `Theine`).
- Audio-only playback (music) does not pause breaks.

Known limits: a call app that does not use mic/camera is not detected; a non-video app holding a display-sleep assertion pauses breaks; "Hey Siri"-style always-on mic usage may count as a call on some hardware.

## Core interfaces (contract between tasks)

```swift
// LookUpCore
public struct BreakSettings: Equatable, Codable, Sendable {
    public var isEnabled: Bool          // true
    public var interval: TimeInterval   // 1200
    public var duration: TimeInterval   // 20
    public var message: String          // "Look at something far away"
    public static let `default`: BreakSettings
    public static let defaultMessage: String
    public static let intervalOptions: [TimeInterval]
    public static let durationOptions: [TimeInterval]
}

public enum PauseReason: Equatable, Sendable { case mediaPlaying, inCall }

public protocol ActivityDetecting { func currentPauseReason() -> PauseReason? }

public enum SchedulerPhase: Equatable, Sendable {
    case disabled
    case working(remaining: TimeInterval)
    case paused(PauseReason, remaining: TimeInterval)
    case onBreak(remaining: TimeInterval)
}

public enum SchedulerEvent: Equatable, Sendable { case breakStarted, breakEnded }

public struct BreakScheduler: Sendable {
    public static let maxTickGap: TimeInterval            // 30
    public private(set) var settings: BreakSettings
    public private(set) var phase: SchedulerPhase
    public init(settings: BreakSettings, now: Date)
    public mutating func update(now: Date, pauseReason: PauseReason?) -> SchedulerEvent?
    public mutating func apply(_ settings: BreakSettings, now: Date) -> SchedulerEvent?
    public mutating func startBreakNow(now: Date) -> SchedulerEvent?
    public mutating func skipBreak(now: Date) -> SchedulerEvent?
    public mutating func restartCountdown(now: Date)
}

public enum Breathing {
    public static let inhale: TimeInterval, hold: TimeInterval, exhale: TimeInterval
    public static var cycle: TimeInterval { get }
    public static func level(at elapsed: TimeInterval) -> Double   // 0...1
}

public struct PowerAssertion: Equatable, Sendable {
    public var pid: Int32; public var processName: String; public var type: String; public var name: String
}

public enum ActivityClassifier {
    public static func pauseReason(assertions: [PowerAssertion], ownPID: Int32,
                                   microphoneInUse: Bool, cameraInUse: Bool) -> PauseReason?
}

public struct SettingsStore {
    public init(defaults: UserDefaults)
    public func load() -> BreakSettings
    public func save(_ settings: BreakSettings)
}
```

```swift
// LookUp (app target)
@MainActor final class OverlayController {
    func show(message: String, endDate: Date, onSkip: @escaping @MainActor () -> Void)
    func hide()
    var isVisible: Bool { get }
}

final class SystemActivityMonitor: ActivityDetecting { init() }
```

`AppModel` (`@Observable @MainActor`) owns `BreakScheduler`, `SettingsStore`, `OverlayController`, `ActivityDetecting`. A 1 s `Timer` calls `scheduler.update(now:pauseReason:)` and maps events to `overlay.show/hide`.

## Testing

- Unit: `BreakScheduler` (all transitions, pause freeze, sleep gap, settings changes), `Breathing`, `ActivityClassifier`, `SettingsStore`.
- Manual: see `README.md`.

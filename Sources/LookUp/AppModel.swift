import AppKit
import LookUpCore
import Observation

@MainActor
@Observable
final class AppModel {
    private(set) var settings: BreakSettings
    private(set) var statusText: String
    private(set) var symbolName: String

    @ObservationIgnored private var scheduler: BreakScheduler
    @ObservationIgnored private let store: SettingsStore
    @ObservationIgnored private let overlay: OverlayController
    @ObservationIgnored private let activity: ActivityDetecting
    @ObservationIgnored private var isScreenLocked = false
    @ObservationIgnored private var isDisplayAsleep = false
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    init(store: SettingsStore = SettingsStore(), activity: ActivityDetecting = SystemActivityMonitor()) {
        let settings = store.load()
        let scheduler = BreakScheduler(settings: settings, now: .now)
        self.store = store
        self.activity = activity
        self.overlay = OverlayController()
        self.settings = settings
        self.scheduler = scheduler
        self.statusText = MenuText.status(for: scheduler.phase)
        self.symbolName = MenuText.symbol(for: scheduler.phase)
        startTimer()
        observeUserPresence()
        if CommandLine.arguments.contains("--preview-break") {
            startBreakNow()
        }
    }

    private var isUserAway: Bool { isScreenLocked || isDisplayAsleep }

    func update(_ change: (inout BreakSettings) -> Void) {
        var next = settings
        change(&next)
        if next.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            next.message = BreakSettings.defaultMessage
        }
        guard next != settings else { return }
        settings = next
        store.save(next)
        let now = Date.now
        handle(scheduler.apply(next, now: now), now: now)
        if overlay.isVisible { showOverlay(now: now) }
    }

    func startBreakNow() {
        let now = Date.now
        handle(scheduler.startBreakNow(now: now), now: now)
    }

    func skipBreak() {
        let now = Date.now
        handle(scheduler.skipBreak(now: now), now: now)
    }

    func editMessage() {
        DispatchQueue.main.async { [self] in
            guard let text = TextPrompt.ask(
                title: "Break Text",
                message: "Shown in the middle of the screen during a break.",
                initial: settings.message
            ) else { return }
            update { $0.message = text }
        }
    }

    private func tick() {
        guard !isUserAway else { return }
        let now = Date.now
        handle(scheduler.update(now: now, pauseReason: activity.currentPauseReason()), now: now)
    }

    private func handle(_ event: SchedulerEvent?, now: Date) {
        switch event {
        case .breakStarted: showOverlay(now: now)
        case .breakEnded: overlay.hide()
        case nil: break
        }
        refreshMenu()
    }

    private func refreshMenu() {
        let status = MenuText.status(for: scheduler.phase)
        let symbol = MenuText.symbol(for: scheduler.phase)
        if status != statusText { statusText = status }
        if symbol != symbolName { symbolName = symbol }
    }

    private func showOverlay(now: Date) {
        guard case .onBreak(let remaining) = scheduler.phase else { return }
        overlay.show(message: settings.message, endDate: now.addingTimeInterval(remaining)) { [weak self] in
            self?.skipBreak()
        }
    }

    private func startTimer() {
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    // Ticks stop while the screen is locked or asleep; the first tick after the user returns
    // sees a gap larger than BreakScheduler.maxTickGap, which ends any break and restarts the countdown.
    private func observeUserPresence() {
        let workspace = NSWorkspace.shared.notificationCenter
        let distributed = DistributedNotificationCenter.default()
        observe(workspace, NSWorkspace.screensDidSleepNotification) { $0.updatePresence { $0.isDisplayAsleep = true } }
        observe(workspace, NSWorkspace.screensDidWakeNotification) { $0.updatePresence { $0.isDisplayAsleep = false } }
        observe(distributed, Notification.Name("com.apple.screenIsLocked")) { $0.updatePresence { $0.isScreenLocked = true } }
        observe(distributed, Notification.Name("com.apple.screenIsUnlocked")) { $0.updatePresence { $0.isScreenLocked = false } }
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name, _ action: @escaping @MainActor (AppModel) -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                action(self)
            }
        }
        observers.append((center, token))
    }

    private func updatePresence(_ change: (AppModel) -> Void) {
        let wasAway = isUserAway
        change(self)
        guard wasAway, !isUserAway else { return }
        tick()
        scheduler.restartCountdown(now: .now)
        refreshMenu()
    }
}

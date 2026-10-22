import AppKit

@MainActor
final class OverlayController {
    private static let fadeDuration: TimeInterval = 0.6
    private static let escapeKeyCode: UInt16 = 53

    private let model = OverlayModel()
    private var windows: [OverlayWindow] = []
    private var keyMonitor: Any?

    var isVisible: Bool { !windows.isEmpty }

    init() {}

    func show(message: String, endDate: Date, onSkip: @escaping @MainActor () -> Void) {
        model.message = message
        model.endDate = endDate
        model.onSkip = onSkip
        guard !isVisible else { return }

        model.startDate = Date()
        windows = NSScreen.screens.map { OverlayWindow(screen: $0, model: model) }
        installKeyMonitor()

        NSApp.activate(ignoringOtherApps: true)
        for window in windows {
            window.alphaValue = 0
            window.orderFrontRegardless()
        }
        let mainWindow = windows.first { $0.screen == NSScreen.main } ?? windows.first
        mainWindow?.makeKeyAndOrderFront(nil)

        let shown = windows
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.fadeDuration
            shown.forEach { $0.animator().alphaValue = 1 }
        }
    }

    func hide() {
        guard isVisible else { return }
        let closing = windows
        windows = []
        removeKeyMonitor()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.fadeDuration
            closing.forEach { $0.animator().alphaValue = 0 }
        } completionHandler: {
            MainActor.assumeIsolated {
                closing.forEach { $0.orderOut(nil) }
            }
        }
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == Self.escapeKeyCode else { return event }
            MainActor.assumeIsolated { self?.model.onSkip() }
            return nil
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }
}

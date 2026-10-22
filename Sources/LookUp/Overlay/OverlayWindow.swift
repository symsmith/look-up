import AppKit
import SwiftUI

final class OverlayWindow: NSWindow {
    // Borderless windows refuse key status by default; without this, Esc and the Skip button never receive events.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init(screen: NSScreen, model: OverlayModel) {
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        setFrame(screen.frame, display: false)
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        appearance = NSAppearance(named: .darkAqua)
        contentView = Self.makeContent(model: model)
    }

    private static func makeContent(model: OverlayModel) -> NSView {
        let blur = NSVisualEffectView()
        blur.material = .fullScreenUI
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.appearance = NSAppearance(named: .darkAqua)

        let hosting = NSHostingView(rootView: BreakOverlayView(model: model))
        hosting.frame = blur.bounds
        hosting.autoresizingMask = [.width, .height]
        blur.addSubview(hosting)
        return blur
    }
}

import AppKit
import LookUpCore

@MainActor
enum TextPrompt {
    static func ask(title: String, message: String, initial: String) -> String? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let field = NSTextField(string: initial)
        field.frame = NSRect(x: 0, y: 0, width: 320, height: 24)
        field.placeholderString = BreakSettings.defaultMessage
        alert.accessoryView = field

        let previousApp = NSWorkspace.shared.frontmostApplication
        NSApp.activate(ignoringOtherApps: true)
        // NSAlert ignores initialFirstResponder and keeps the panel itself as first responder, so the field gets no caret.
        RunLoop.main.perform(inModes: [.modalPanel]) {
            MainActor.assumeIsolated { _ = alert.window.makeFirstResponder(field) }
        }
        let response = alert.runModal()
        previousApp?.activate()
        return response == .alertFirstButtonReturn ? field.stringValue : nil
    }
}

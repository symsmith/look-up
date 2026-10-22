import AppKit

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
        field.placeholderString = initial
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        NSApp.activate()
        return alert.runModal() == .alertFirstButtonReturn ? field.stringValue : nil
    }
}

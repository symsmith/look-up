import SwiftUI

@main
struct LookUpApp: App {
    var body: some Scene {
        MenuBarExtra("Look Up", systemImage: "eye") {
            Button("Quit Look Up") { NSApplication.shared.terminate(nil) }
        }
        .menuBarExtraStyle(.menu)
    }
}

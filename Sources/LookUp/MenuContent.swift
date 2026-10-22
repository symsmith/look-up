import LookUpCore
import SwiftUI

struct MenuContent: View {
    let model: AppModel

    var body: some View {
        Text(model.statusText)

        Divider()

        Toggle("Enabled", isOn: binding(\.isEnabled))

        Picker("Break Interval", selection: binding(\.interval)) {
            ForEach(BreakSettings.intervalOptions, id: \.self) { Text(MenuText.duration($0)).tag($0) }
        }

        Picker("Break Duration", selection: binding(\.duration)) {
            ForEach(BreakSettings.durationOptions, id: \.self) { Text(MenuText.duration($0)).tag($0) }
        }

        Button("Break Text…") { model.editMessage() }

        Divider()

        Button("Start Break Now") { model.startBreakNow() }

        Divider()

        Button("Quit Look Up") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<BreakSettings, Value>) -> Binding<Value> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { value in model.update { $0[keyPath: keyPath] = value } }
        )
    }
}

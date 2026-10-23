import SwiftUI

@main
struct LookUpApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            SettingsPanel(model: model)
        } label: {
            Image(nsImage: EyeIcon.image(for: model.statusIcon))
                .accessibilityLabel("Look Up")
        }
        .menuBarExtraStyle(.window)
    }
}

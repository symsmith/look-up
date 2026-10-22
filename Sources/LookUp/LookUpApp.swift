import SwiftUI

@main
struct LookUpApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            Image(systemName: model.symbolName)
                .accessibilityLabel("Look Up")
        }
        .menuBarExtraStyle(.menu)
    }
}

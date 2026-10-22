import LookUpCore
import SwiftUI

struct SettingsPanel: View {
    let model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Form {
                Toggle("Enabled", isOn: binding(\.isEnabled))
                Picker("Break interval", selection: binding(\.interval)) {
                    ForEach(BreakSettings.intervalOptions, id: \.self) { Text(DisplayText.duration($0)).tag($0) }
                }
                Picker("Break duration", selection: binding(\.duration)) {
                    ForEach(BreakSettings.durationOptions, id: \.self) { Text(DisplayText.duration($0)).tag($0) }
                }
                Section("Break text") {
                    TextField("Break text", text: binding(\.message), prompt: Text(BreakSettings.defaultMessage), axis: .vertical)
                        .labelsHidden()
                        .lineLimit(1...3)
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .fixedSize(horizontal: false, vertical: true)
            footer
        }
        .frame(width: 340)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("Look Up").font(.headline)
                Text(model.statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var footer: some View {
        HStack {
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
            Spacer()
            Button("Start Break Now") {
                dismiss()
                model.startBreakNow()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<BreakSettings, Value>) -> Binding<Value> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { value in model.update { $0[keyPath: keyPath] = value } }
        )
    }
}

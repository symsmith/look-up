import Foundation

public struct SettingsStore {
    public static let key = "breakSettings"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> BreakSettings {
        guard
            let data = defaults.data(forKey: Self.key),
            let settings = try? JSONDecoder().decode(BreakSettings.self, from: data)
        else { return .default }
        return settings
    }

    public func save(_ settings: BreakSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.key)
    }
}

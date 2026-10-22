import Foundation
import Testing
@testable import LookUpCore

struct SettingsStoreTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "SettingsStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func loadsDefaultsWhenEmpty() {
        let store = SettingsStore(defaults: makeDefaults())
        #expect(store.load() == .default)
        #expect(store.load().interval == 1200)
        #expect(store.load().duration == 20)
        #expect(store.load().isEnabled)
        #expect(store.load().message == "Look at something far away")
    }

    @Test func roundTrips() {
        let store = SettingsStore(defaults: makeDefaults())
        let settings = BreakSettings(isEnabled: false, interval: 600, duration: 45, message: "Blink")
        store.save(settings)
        #expect(store.load() == settings)
    }

    @Test func corruptDataFallsBackToDefaults() {
        let defaults = makeDefaults()
        defaults.set(Data("nope".utf8), forKey: SettingsStore.key)
        #expect(SettingsStore(defaults: defaults).load() == .default)
    }
}

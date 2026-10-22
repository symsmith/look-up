import Testing
@testable import LookUpCore

struct BreakSettingsTests {
    @Test func displayMessageFallsBackToDefaultWhenBlank() {
        #expect(BreakSettings(message: "").displayMessage == BreakSettings.defaultMessage)
        #expect(BreakSettings(message: "  \n ").displayMessage == BreakSettings.defaultMessage)
    }

    @Test func displayMessageTrimsWhitespace() {
        #expect(BreakSettings(message: "  Blink  ").displayMessage == "Blink")
    }
}

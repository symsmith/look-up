import Testing
@testable import LookUpCore

struct MenuTextTests {
    @Test func statusLines() {
        #expect(MenuText.status(for: .disabled) == "Breaks disabled")
        #expect(MenuText.status(for: .working(remaining: 1200)) == "Next break in 20 min")
        #expect(MenuText.status(for: .working(remaining: 719)) == "Next break in 12 min")
        #expect(MenuText.status(for: .working(remaining: 61)) == "Next break in 2 min")
        #expect(MenuText.status(for: .working(remaining: 60)) == "Next break in 1 min")
        #expect(MenuText.status(for: .working(remaining: 59)) == "Next break in less than a minute")
        #expect(MenuText.status(for: .paused(.mediaPlaying, remaining: 300)) == "Paused — media playing")
        #expect(MenuText.status(for: .paused(.inCall, remaining: 300)) == "Paused — in a call")
        #expect(MenuText.status(for: .onBreak(remaining: 10)) == "On a break")
    }

    @Test func symbols() {
        #expect(MenuText.symbol(for: .disabled) == "eye.slash")
        #expect(MenuText.symbol(for: .paused(.inCall, remaining: 1)) == "pause.circle")
        #expect(MenuText.symbol(for: .working(remaining: 1)) == "eye")
        #expect(MenuText.symbol(for: .onBreak(remaining: 1)) == "eye")
    }

    @Test func durations() {
        #expect(MenuText.duration(10) == "10 seconds")
        #expect(MenuText.duration(20) == "20 seconds")
        #expect(MenuText.duration(60) == "1 minute")
        #expect(MenuText.duration(120) == "2 minutes")
        #expect(MenuText.duration(1200) == "20 minutes")
        #expect(MenuText.duration(90) == "1 min 30 sec")
    }
}

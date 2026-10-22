import Testing
@testable import LookUpCore

struct DisplayTextTests {
    @Test func statusLines() {
        #expect(DisplayText.status(for: .disabled) == "Breaks disabled")
        #expect(DisplayText.status(for: .working(remaining: 1200)) == "Next break in 20 min")
        #expect(DisplayText.status(for: .working(remaining: 719)) == "Next break in 12 min")
        #expect(DisplayText.status(for: .working(remaining: 61)) == "Next break in 2 min")
        #expect(DisplayText.status(for: .working(remaining: 60)) == "Next break in 1 min")
        #expect(DisplayText.status(for: .working(remaining: 59)) == "Next break in less than a minute")
        #expect(DisplayText.status(for: .paused(.mediaPlaying, remaining: 300)) == "Paused — media playing")
        #expect(DisplayText.status(for: .paused(.inCall, remaining: 300)) == "Paused — in a call")
        #expect(DisplayText.status(for: .onBreak(remaining: 10)) == "On a break")
    }

    @Test func symbols() {
        #expect(DisplayText.symbol(for: .disabled) == "eye.slash")
        #expect(DisplayText.symbol(for: .paused(.inCall, remaining: 1)) == "pause.circle")
        #expect(DisplayText.symbol(for: .working(remaining: 1)) == "eye")
        #expect(DisplayText.symbol(for: .onBreak(remaining: 1)) == "eye")
    }

    @Test func durations() {
        #expect(DisplayText.duration(10) == "10 seconds")
        #expect(DisplayText.duration(20) == "20 seconds")
        #expect(DisplayText.duration(60) == "1 minute")
        #expect(DisplayText.duration(120) == "2 minutes")
        #expect(DisplayText.duration(1200) == "20 minutes")
        #expect(DisplayText.duration(90) == "1 min 30 sec")
    }
}

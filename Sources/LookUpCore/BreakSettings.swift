import Foundation

public struct BreakSettings: Equatable, Codable, Sendable {
    public var isEnabled: Bool
    public var interval: TimeInterval
    public var duration: TimeInterval
    public var message: String

    public init(
        isEnabled: Bool = true,
        interval: TimeInterval = 20 * 60,
        duration: TimeInterval = 20,
        message: String = BreakSettings.defaultMessage
    ) {
        self.isEnabled = isEnabled
        self.interval = interval
        self.duration = duration
        self.message = message
    }

    public var displayMessage: String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Self.defaultMessage : trimmed
    }

    public static let defaultMessage = "Look at something far away"
    public static let `default` = BreakSettings()
    public static let intervalOptions: [TimeInterval] = [5, 10, 15, 20, 25, 30, 45, 60].map { $0 * 60 }
    public static let durationOptions: [TimeInterval] = [10, 20, 30, 45, 60, 120]
}

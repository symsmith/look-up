import Foundation
import Observation

@MainActor @Observable
final class OverlayModel {
    var message = ""
    var startDate = Date()
    var endDate = Date()
    @ObservationIgnored var onSkip: @MainActor () -> Void = {}
}

import Foundation

/// Clears session-owned persisted state for analytics.
protocol SessionDataDelegating: AnyObject {
    func clearSessionData()
}

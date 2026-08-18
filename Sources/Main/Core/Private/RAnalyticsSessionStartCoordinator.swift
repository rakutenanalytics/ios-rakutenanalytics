import Foundation

/// Coordinates launch and resumed `_rem_launch` tracking until UIKit has restored its state.
final class RAnalyticsSessionStartCoordinator {
    static let shared = RAnalyticsSessionStartCoordinator()

    private var isInitialLaunchPending = false
    private var isResumedSessionStartPending = false
    private var stateRestorationExtensionCount = 0
    private var onTrackInitialLaunch: (() -> Void)?
    private var onTrackResumedSessionStart: (() -> Void)?

    private init() {}

    func configure(onTrackInitialLaunch: @escaping () -> Void,
                   onTrackResumedSessionStart: @escaping () -> Void) {
        self.onTrackInitialLaunch = onTrackInitialLaunch
        self.onTrackResumedSessionStart = onTrackResumedSessionStart
    }

    func scheduleInitialLaunch() {
        isInitialLaunchPending = true
        stateRestorationExtensionCount = 0
    }

    func scheduleResumedSessionStart() {
        isResumedSessionStartPending = true
        stateRestorationExtensionCount = 0
    }

    func stateRestorationExtended() {
        stateRestorationExtensionCount += 1
    }

    func stateRestorationCompleted() {
        stateRestorationExtensionCount = max(0, stateRestorationExtensionCount - 1)
        tryTrackPendingSessionStart()
    }

    func applicationDidBecomeActive() {
        tryTrackPendingSessionStart()
    }

    func cancelResumedSessionStart() {
        isInitialLaunchPending = false
        isResumedSessionStartPending = false
        stateRestorationExtensionCount = 0
    }

    func resetForTesting() {
        isInitialLaunchPending = false
        isResumedSessionStartPending = false
        stateRestorationExtensionCount = 0
        onTrackInitialLaunch = nil
        onTrackResumedSessionStart = nil
    }

    private func tryTrackPendingSessionStart() {
        guard stateRestorationExtensionCount == 0 else {
            return
        }

        if isInitialLaunchPending {
            isInitialLaunchPending = false
            onTrackInitialLaunch?()
            return
        }

        guard isResumedSessionStartPending else {
            return
        }

        isResumedSessionStartPending = false
        onTrackResumedSessionStart?()
    }
}

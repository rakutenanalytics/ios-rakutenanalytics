import Foundation

extension NSNotification.Name {
    static let didReceiveDarwinNotification = NSNotification.Name(rawValue: "com.rakuten.esd.sdk.events.tracking.from.darwin.notification")
}

/// `AnalyticsEventObserver` observes Darwin Notification in order to track events.
internal final class AnalyticsEventObserver {
    private let center = CFNotificationCenterGetDarwinNotifyCenter()
    private var isObserving = false
    private var analyticsEventTracker: AnalyticsEventTrackable
    weak var delegate: AnalyticsManageable? {
        didSet {
            analyticsEventTracker.delegate = delegate
        }
    }

    /// Create a new instance of `AnalyticsEventObserver`.
    ///
    /// - Parameters:
    ///    - pushEventHandler: the push event handler.
    internal init(pushEventHandler: PushEventHandleable) {
        analyticsEventTracker = AnalyticsEventTracker(pushEventHandler: pushEventHandler)

        NotificationCenter.default.addObserver(forName: .didReceiveDarwinNotification, object: nil, queue: nil) { _ in
            self.trackCachedEvents()
        }

        startObservation()
    }

    deinit {
        stopObservation()
    }

    internal func trackCachedEvents() {
        analyticsEventTracker.track()
    }

    private func startObservation() {
        guard !isObserving else { return }
        isObserving = true

        /// Note: A C function pointer cannot be formed from a closure that captures context.
        /// As CFNotificationCenterAddObserver is a C function and cannot capture properties.
        /// the solution is posting a notification through `NotificationCenter`.
        CFNotificationCenterAddObserver(center, Unmanaged.passUnretained(self).toOpaque(), { (_, _, _, _, _) in
            NotificationCenter.default.post(name: .didReceiveDarwinNotification, object: nil, userInfo: nil)
        }, AnalyticsDarwinNotification.eventsTrackingRequest, nil, .deliverImmediately)
    }

    private func stopObservation() {
        guard isObserving else { return }
        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
        isObserving = false
    }
}

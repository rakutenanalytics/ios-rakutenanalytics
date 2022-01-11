import Foundation

extension NSNotification.Name {
    static let didReceiveDarwinNotification = NSNotification.Name(rawValue: "com.rakuten.esd.sdk.events.tracking.from.darwin.notification")
}

/// `AnalyticsEventObserver` observes Darwin Notification in order to track events.
internal final class AnalyticsEventObserver {
    private let center = CFNotificationCenterGetDarwinNotifyCenter()
    private var isObserving = false
    private var analyticsEventTracker: AnalyticsEventTrackable
    private var notificationObserver: Any?

    private(set) weak var delegate: AnalyticsManageable? {
        didSet {
            analyticsEventTracker.delegate = delegate
        }
    }

    /// Create a new instance of `AnalyticsEventObserver`.
    ///
    /// - Parameters:
    ///    - pushEventHandler: the push event handler.
    init(pushEventHandler: PushEventHandleable) {
        analyticsEventTracker = AnalyticsEventTracker(pushEventHandler: pushEventHandler)
    }

    deinit {
        stopObservation()
    }
}

// MARK: - Tracking

extension AnalyticsEventObserver {
    func trackCachedEvents() {
        analyticsEventTracker.track()
    }
}

// MARK: - Observation

extension AnalyticsEventObserver {
    @discardableResult
    func startObservation(delegate: AnalyticsManageable?) -> Bool {
        guard !isObserving else { return false }
        isObserving = true

        self.delegate = delegate

        // https://developer.apple.com/documentation/foundation/nsnotificationcenter/1411723-addobserverforname
        // To avoid a retain cycle, use a weak reference to self inside the block when self contains the observer as a strong reference.
        notificationObserver = NotificationCenter
            .default
            .addObserver(forName: .didReceiveDarwinNotification, object: nil, queue: nil) { [weak self] _ in
                self?.trackCachedEvents()
            }

        /// Note: A C function pointer cannot be formed from a closure that captures context.
        /// As CFNotificationCenterAddObserver is a C function and cannot capture properties.
        /// the solution is posting a notification through `NotificationCenter`.
        CFNotificationCenterAddObserver(center, Unmanaged.passUnretained(self).toOpaque(), { (_, _, _, _, _) in
            NotificationCenter.default.post(name: .didReceiveDarwinNotification, object: nil, userInfo: nil)
        }, AnalyticsDarwinNotification.eventsTrackingRequest, nil, .deliverImmediately)

        return true
    }

    @discardableResult
    func stopObservation() -> Bool {
        guard isObserving else { return false }

        self.delegate = nil

        // https://developer.apple.com/documentation/foundation/nsnotificationcenter/1411723-addobserverforname
        // You must invoke removeObserver: or removeObserver:name:object: before the system deallocates any object that addObserverForName:object:queue:usingBlock: specifies.
        if let notificationObserver = notificationObserver {
            NotificationCenter.default.removeObserver(notificationObserver)
        }

        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
        isObserving = false

        return true
    }
}

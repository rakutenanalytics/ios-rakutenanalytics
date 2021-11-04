import Foundation
import RAnalytics

extension RAnalyticsEvent {
    @objc public static var pushTrackingIdentifier: String {
        RAnalyticsEvent.Parameter.pushTrackingIdentifier
    }

    @objc public static var pushNotification: String {
        RAnalyticsEvent.Name.pushNotification
    }
}

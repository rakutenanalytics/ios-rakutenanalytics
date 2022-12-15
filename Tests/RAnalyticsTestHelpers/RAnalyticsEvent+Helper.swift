import Foundation
import RAnalytics

extension RAnalyticsEvent {
    @objc public static var pushTrackingIdentifier: String {
        RAnalyticsEvent.Parameter.pushTrackingIdentifier
    }
}

import Foundation
import RakutenAnalytics

extension RAnalyticsEvent {
    @objc public static var pushTrackingIdentifier: String {
        RAnalyticsEvent.Parameter.pushTrackingIdentifier
    }
}

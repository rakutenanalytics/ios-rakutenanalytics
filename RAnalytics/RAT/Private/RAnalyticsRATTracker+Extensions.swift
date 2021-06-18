import Foundation
import SystemConfiguration

extension RAnalyticsRATTracker {
    @objc public static let reachabilityCallback: SCNetworkReachabilityCallBack = { _, flags, _ in
        let result = flags.reachabilityStatus.rawValue
        let selector = Selector(("setReachabilityStatus:"))

        if shared().responds(to: selector) {
            shared().perform(selector, with: NSNumber(value: result))
        }
    }
}

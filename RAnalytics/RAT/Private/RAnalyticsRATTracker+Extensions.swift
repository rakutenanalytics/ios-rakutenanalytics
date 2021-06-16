import Foundation
import SystemConfiguration

extension RAnalyticsRATTracker {
    @objc public static let reachabilityCallback: SCNetworkReachabilityCallBack = { _, flags, _ in
        let result = flags.reachabilityStatus.rawValue
        shared().perform(Selector(("setReachabilityStatus:")), with: NSNumber(value: result))
    }
}

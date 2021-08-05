import Foundation
import SystemConfiguration

extension RAnalyticsRATTracker {
    static let reachabilityCallback: SCNetworkReachabilityCallBack = { _, flags, _ in
        let result = flags.reachabilityStatus.rawValue
        shared().reachabilityStatus = NSNumber(value: result)
    }
}

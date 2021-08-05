import Foundation
import SystemConfiguration

/// Reachability status
enum RATReachabilityStatus: Int {
    case offline
    case wwan
    case wifi
}

extension SCNetworkReachabilityFlags {
    var reachabilityStatus: RATReachabilityStatus {
        if !contains(.reachable) || contains(.connectionRequired) {
            return .offline

        } else if contains(.isWWAN) {
            return .wwan

        } else {
            return .wifi
        }
    }
}

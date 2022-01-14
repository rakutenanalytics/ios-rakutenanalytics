import Foundation
import SystemConfiguration

protocol ReachabilityNotifiable {
    init?(host: String, callback: @escaping SCNetworkReachabilityCallBack)
}

/// The Reachability Notifier calls the callback when the network status changes.
final class ReachabilityNotifier: ReachabilityNotifiable {
    private let reachability: SCNetworkReachability

    /// Creates a new instance of `ReachabilityNotifier`.
    ///
    /// - Parameters:
    ///     - host: the host name.
    ///     - callback: the network reachability callback.
    ///
    /// - Returns: a new instance of `ReachabilityNotifier`.
    init?(host: String, callback: @escaping SCNetworkReachabilityCallBack) {
        guard let reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, host) else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.reachabilityNotifierErrorDomain,
                                             code: ErrorCode.scNetworkReachabilityCreateWithNameFailed.rawValue,
                                             description: ErrorDescription.reachabilityNotifierCreationFailed,
                                             reason: ErrorReason.networkReachabilityCreateWithNameFailure))
            return nil
        }

        self.reachability = reachability

        guard SCNetworkReachabilitySetCallback(reachability, callback, nil) else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.reachabilityNotifierErrorDomain,
                                             code: ErrorCode.scNetworkReachabilitySetCallback.rawValue,
                                             description: ErrorDescription.reachabilityNotifierCreationFailed,
                                             reason: ErrorReason.networkReachabilitySetCallbackFailure))
            return nil
        }

        guard SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue) else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.reachabilityNotifierErrorDomain,
                                             code: ErrorCode.scNetworkReachabilityScheduleWithRunLoop.rawValue,
                                             description: ErrorDescription.reachabilityNotifierCreationFailed,
                                             reason: ErrorReason.networkReachabilityScheduleWithRunLoopFailure))
            return nil
        }

        // We register for reachability updates, but to get the current reachability we need to query it,
        // so we do so from a background thread.

        DispatchQueue.global().async {
            var flags = SCNetworkReachabilityFlags()
            if SCNetworkReachabilityGetFlags(self.reachability, &flags) {
                callback(self.reachability, flags, nil)
            }
        }
    }

    deinit {
        SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
    }
}

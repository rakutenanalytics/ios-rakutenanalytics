#if os(iOS)
import Foundation
import CoreTelephony

extension CTTelephonyNetworkInfo: TelephonyNetworkInfoHandleable {
    /// - Returns: `CTTelephonyNetworkInfo`'s `dataServiceIdentifier` if the app runs on the iOS device, `nil` otherwise if the app runs on the iOS simulator.
    ///
    /// - Note: `dataServiceIdentifier` returns error logs on the simulator.
    var safeDataServiceIdentifier: String? {
        #if targetEnvironment(simulator)
        return nil
        #else
        return dataServiceIdentifier
        #endif
    }
}
#endif

import Foundation
import UIKit

protocol DeviceCapability {
    var idfvUUID: String? { get }
    var batteryState: UIDevice.BatteryState { get }
    var batteryLevel: Float { get }
    func setBatteryMonitoring(_ value: Bool)
}

extension UIDevice: DeviceCapability {
    var idfvUUID: String? {
        identifierForVendor?.uuidString
    }

    /// - Note: Solve a compiler ambiguity on `setBatteryMonitoringEnabled:`.
    func setBatteryMonitoring(_ value: Bool) {
        isBatteryMonitoringEnabled = value
    }
}

extension UIDevice {
    /// Return the model identifier of the device the application is currently running on.
    ///
    /// - Returns: The internal model identifier. See [here](https://www.theiphonewiki.com/wiki/Models) for a list of model identifiers.
    var modelIdentifier: String {
        // https://opensource.apple.com/source/xnu/xnu-201/bsd/sys/utsname.h.auto.html
        var systemInfo = utsname()
        uname(&systemInfo)
        // utsname.machine is a null terminated C-string
        // make String from a ptr to the first bit i.e. machine.0
        return withUnsafePointer(to: &systemInfo.machine.0) { String(cString: $0) }
    }
}

import Foundation

protocol DeviceCapability {
    var batteryState: UIDevice.BatteryState { get }
    var batteryLevel: Float { get }
    func setBatteryMonitoring(_ value: Bool)
}

extension UIDevice: DeviceCapability {
    /// - Note: Solve a compiler ambiguity on `setBatteryMonitoringEnabled:`.
    func setBatteryMonitoring(_ value: Bool) {
        isBatteryMonitoringEnabled = value
    }
}

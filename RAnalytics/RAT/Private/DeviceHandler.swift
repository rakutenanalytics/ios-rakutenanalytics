import Foundation

/// The Device Handler handles the device battery and the screen resolution.
@objc public final class DeviceHandler: NSObject {
    private let device: UIDevice
    @objc public let screenResolution: String

    /// Creates a new instance of `DeviceHandler`.
    ///
    /// - Parameters:
    ///   - device: The device.
    ///   - screen: The screen.
    ///
    /// - Returns: a new instance of `DeviceHandler`.
    @objc public init(device: UIDevice,
                      screen: Screenable) {
        let screenSize = screen.bounds.size
        screenResolution = "\(Int(screenSize.width))x\(Int(screenSize.height))"

        self.device = device
        // This is needed to enable access to the battery getters.
        device.isBatteryMonitoringEnabled = true
    }
}

extension DeviceHandler {
    @objc public var batteryState: UIDevice.BatteryState {
        device.batteryState
    }

    @objc public var batteryLevel: Float {
        device.batteryLevel
    }
}

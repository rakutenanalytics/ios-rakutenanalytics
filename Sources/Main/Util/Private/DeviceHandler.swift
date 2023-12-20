import Foundation
import UIKit

/// The Device Handler handles the device battery and the screen resolution.
final class DeviceHandler: DeviceHandleable {
    private let device: DeviceCapability
    let screenResolution: String

    /// Creates a new instance of `DeviceHandler`.
    ///
    /// - Parameters:
    ///   - device: The device.
    ///   - screen: The screen.
    ///
    /// - Returns: a new instance of `DeviceHandler`.
    init(device: DeviceCapability, screen: Screenable) {
        let screenSize = screen.bounds.size
        screenResolution = "\(Int(screenSize.width))x\(Int(screenSize.height))"

        self.device = device
        // This is needed to enable access to the battery getters.
        device.setBatteryMonitoring(true)
    }
}

extension DeviceHandler {
    var batteryState: UIDevice.BatteryState {
        device.batteryState
    }

    var batteryLevel: Float {
        device.batteryLevel
    }
}

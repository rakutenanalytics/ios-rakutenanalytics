import Foundation
import UIKit

/// The Device Handler handles the device battery and the screen resolution.
final class DeviceHandler: DeviceHandleable {
    private let device: DeviceCapability
    private let screen: Screenable

    var screenResolution: String {
        let screenSize = screen.bounds.size
        return "\(Int(screenSize.width))x\(Int(screenSize.height))"
    }

    /// Creates a new instance of `DeviceHandler`.
    ///
    /// - Parameters:
    ///   - device: The device.
    ///   - screen: The screen.
    ///
    /// - Returns: a new instance of `DeviceHandler`.
    init(device: DeviceCapability, screen: Screenable) {
        self.screen = screen
        self.device = device
        #if os(iOS)
        if let batteryDevice = device as? DeviceBatteryCapability {
            batteryDevice.setBatteryMonitoring(true)
        }
        #endif
    }
}

extension DeviceHandler {
    var includesBatteryMetrics: Bool {
        #if os(iOS)
        guard let batteryDevice = device as? DeviceBatteryCapability else {
            return false
        }
        return batteryDevice.batteryState != .unknown
        #else
        return false
        #endif
    }

    var batteryPowerStatusValue: Int {
        #if os(iOS)
        guard let batteryDevice = device as? DeviceBatteryCapability else {
            return 0
        }
        return batteryDevice.batteryState != .unplugged ? 1 : 0
        #else
        return 0
        #endif
    }

    var batteryLevelPercentage: Float {
        #if os(iOS)
        guard let batteryDevice = device as? DeviceBatteryCapability else {
            return 0
        }
        return batteryDevice.batteryLevel * 100
        #else
        return 0
        #endif
    }
}

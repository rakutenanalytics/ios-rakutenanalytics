import Foundation

protocol DeviceHandleable {
    var screenResolution: String { get }
    var includesBatteryMetrics: Bool { get }
    var batteryPowerStatusValue: Int { get }
    var batteryLevelPercentage: Float { get }
}

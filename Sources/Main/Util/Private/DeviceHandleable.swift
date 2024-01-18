import Foundation
import UIKit

protocol DeviceHandleable {
    var batteryState: UIDevice.BatteryState { get }
    var batteryLevel: Float { get }
    var screenResolution: String { get }
}

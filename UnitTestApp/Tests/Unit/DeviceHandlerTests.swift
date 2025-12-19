import Testing
import Foundation
import CoreGraphics
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - DeviceHandlerTests

@Suite("DeviceHandler")
struct DeviceHandlerTests {
    @Suite("screenResolution")
    struct ScreenResolutionTests {
        static let currentDevice = UIDevice.current

        @Test("should return the expected value")
        func testReturnsExpectedValue() {
            // Screen resolutions list:
            // https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Displays/Displays.html

            // Expected value: 375x812
            var deviceHandler = DeviceHandler(device: Self.currentDevice, screen: ScreenMock(bounds: CGRect(x: 0, y: 0, width: 375, height: 812)))
            #expect(deviceHandler.screenResolution == "375x812")

            // Expected value: 414x736
            deviceHandler = DeviceHandler(device: Self.currentDevice, screen: ScreenMock(bounds: CGRect(x: 0, y: 0, width: 414, height: 736)))
            #expect(deviceHandler.screenResolution == "414x736")

            // Expected value: 375x667
            deviceHandler = DeviceHandler(device: Self.currentDevice, screen: ScreenMock(bounds: CGRect(x: 0, y: 0, width: 375, height: 667)))
            #expect(deviceHandler.screenResolution == "375x667")
        }
    }
}

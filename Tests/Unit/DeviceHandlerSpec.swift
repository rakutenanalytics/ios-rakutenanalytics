import Quick
import Nimble
import Foundation
import CoreGraphics
import UIKit
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - ScreenMock

private final class ScreenMock: Screenable {
    private let screenBounds: CGRect

    init(bounds: CGRect) {
        self.screenBounds = bounds
    }

    var bounds: CGRect {
        screenBounds
    }
}

// MARK: - DeviceHandlerSpec

final class DeviceHandlerSpec: QuickSpec {
    override func spec() {
        describe("DeviceHandler") {
            describe("screenResolution") {
                let currentDevice = UIDevice.current

                it("should return the expected value") {
                    // Screen resolutions list:
                    // https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Displays/Displays.html

                    // Expected value: 375x812
                    var deviceHandler = DeviceHandler(device: currentDevice,
                                                      screen: ScreenMock(bounds: CGRect(x: 0, y: 0, width: 375, height: 812)))
                    expect(deviceHandler.screenResolution).to(equal("375x812"))

                    // Expected value: 414x736
                    deviceHandler = DeviceHandler(device: currentDevice,
                                                  screen: ScreenMock(bounds: CGRect(x: 0, y: 0, width: 414, height: 736)))
                    expect(deviceHandler.screenResolution).to(equal("414x736"))

                    // Expected value: 375x667
                    deviceHandler = DeviceHandler(device: currentDevice,
                                                  screen: ScreenMock(bounds: CGRect(x: 0, y: 0, width: 375, height: 667)))
                    expect(deviceHandler.screenResolution).to(equal("375x667"))
                }
            }
        }
    }
}

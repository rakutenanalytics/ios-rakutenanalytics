import CoreLocation
import UIKit
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsStatePayloadTests

@Suite("RAnalyticsState's Payload Spec")
struct RAnalyticsStatePayloadTests {
    @Suite("alwaysCollectedCorePayload")
    struct AlwaysCollectedCorePayloadTests {
        @Test("should return app_ver, app_name, ver, ts1")
        func testAlwaysCollectedFields() {
            let sessionIdentifier = "CA7A88AR-82FE-40C9-A836-B1B3455DECAF"
            let deviceIdentifier = "deviceId"
            let bundle = BundleMock()

            let state = AnalyticsManager.State(
                sessionIdentifier: sessionIdentifier,
                deviceIdentifier: deviceIdentifier,
                for: bundle)
            let payload = state.alwaysCollectedCorePayload

            #expect(!payload.isEmpty)
            #expect(payload[PayloadParameterKeys.appVer] as? String == state.currentVersion)
            #expect(payload[PayloadParameterKeys.appName] as? String == CoreHelpers.Constants.applicationName)
            #expect(payload[PayloadParameterKeys.ver] as? String == CoreHelpers.Constants.sdkVersion)
            let ts1 = payload[PayloadParameterKeys.ts1] as? Double
            #expect(ts1 != nil)
            let nowRounded = Swift.max(0, round(NSDate().timeIntervalSince1970))
            #expect(abs((ts1 ?? 0) - nowRounded) < 2)
            #expect(payload[PayloadParameterKeys.mos] == nil)
        }
    }

    @Suite("deviceInformationMosPayload")
    struct DeviceInformationMosPayloadTests {
        @Test("should return mos only")
        func testMosField() {
            let sessionIdentifier = "CA7A88AR-82FE-40C9-A836-B1B3455DECAF"
            let deviceIdentifier = "deviceId"
            let bundle = BundleMock()

            let state = AnalyticsManager.State(
                sessionIdentifier: sessionIdentifier,
                deviceIdentifier: deviceIdentifier,
                for: bundle)
            let payload = state.deviceInformationMosPayload

            #expect(payload.count == 1)
            #expect(payload[PayloadParameterKeys.mos] as? String == CoreHelpers.Constants.osVersion)
        }
    }
}

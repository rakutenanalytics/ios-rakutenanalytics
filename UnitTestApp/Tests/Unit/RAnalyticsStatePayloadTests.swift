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
    @Suite("corePayload")
    struct CorePayloadTests {
        @Test("should return the expected payload")
        func testShouldReturnExpectedPayload() {
            let sessionIdentifier = "CA7A88AR-82FE-40C9-A836-B1B3455DECAF"
            let deviceIdentifier = "deviceId"
            let bundle = BundleMock()
            
            let state = AnalyticsManager.State(
                sessionIdentifier: sessionIdentifier,
                deviceIdentifier: deviceIdentifier,
                for: bundle)
            let payload = state.corePayload
            
            #expect(!payload.isEmpty)
            #expect(payload[PayloadParameterKeys.Core.appVer] as? String == state.currentVersion)
            #expect(payload[PayloadParameterKeys.Core.appName] as? String == CoreHelpers.Constants.applicationName)
            #expect(payload[PayloadParameterKeys.Core.mos] as? String == CoreHelpers.Constants.osVersion)
            #expect(payload[PayloadParameterKeys.Core.ver] as? String == CoreHelpers.Constants.sdkVersion)
            #expect(payload[PayloadParameterKeys.Core.ts1] as? Double == Swift.max(0, round(NSDate().timeIntervalSince1970)))
        }
    }
}

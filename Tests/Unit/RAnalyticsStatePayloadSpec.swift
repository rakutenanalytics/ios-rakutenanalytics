import Quick
import Nimble
import CoreLocation
import UIKit
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsStateSpec

final class RAnalyticsStatePayloadSpec: QuickSpec {
    override func spec() {
        describe("RAnalyticsState's Payload Spec") {
            describe("corePayload") {
                let sessionIdentifier = "CA7A88AB-82FE-40C9-A836-B1B3455DECAB"
                let deviceIdentifier = "deviceId"
                let bundle = BundleMock()

                it("should return the expected payload") {
                    let state = AnalyticsManager.State(sessionIdentifier: sessionIdentifier,
                                                       deviceIdentifier: deviceIdentifier,
                                                       for: bundle)
                    let payload = state.corePayload

                    expect(payload).toNot(beEmpty())
                    expect(payload[PayloadParameterKeys.Core.appVer] as? String).to(equal(state.currentVersion))
                    expect(payload[PayloadParameterKeys.Core.appName] as? String).to(equal(CoreHelpers.Constants.applicationName))
                    expect(payload[PayloadParameterKeys.Core.mos] as? String).to(equal(CoreHelpers.Constants.osVersion))
                    expect(payload[PayloadParameterKeys.Core.ver] as? String).to(equal(CoreHelpers.Constants.sdkVersion))
                    expect(payload[PayloadParameterKeys.Core.ts1] as? Double).to(equal(Swift.max(0, round(NSDate().timeIntervalSince1970))))
                }
            }
        }
    }
}

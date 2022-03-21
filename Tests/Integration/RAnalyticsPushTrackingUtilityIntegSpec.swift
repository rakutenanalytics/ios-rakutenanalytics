import Quick
import Nimble
import Foundation
@testable import RAnalytics

#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsMain
#endif

class RAnalyticsPushTrackingUtilityIntegSpec: QuickSpec {
    override func spec() {
        describe("RAnalyticsPushTrackingUtility Integration") {
            describe("trackPushConversionEvent(pushRequestIdentifier:pushConversionAction:)") {
                var batchingDelay: TimeInterval = 0.0
                let sessionMock = URLSessionMock.mock(originalInstance: .shared)

                beforeEach {
                    batchingDelay = RAnalyticsRATTracker.shared().batchingDelay()
                    RAnalyticsRATTracker.shared().set(batchingDelay: 0.0)
                    URLSessionMock.startMockingURLSession()
                }

                afterEach {
                    RAnalyticsRATTracker.shared().set(batchingDelay: batchingDelay)
                    URLSessionMock.stopMockingURLSession()
                }

                it("should track _rem_push_cv with expected parameters") {
                    let expectedRequestId = "ichiba_iphone_long,2517554993982709815,f1f358ce-5ffb-4c01-8b59-994e72b8915b"
                    let expectedConversionAction = "ichiba_iphone_conversion_action"
                    var isSendingCompleted = false

                    sessionMock.stubRATResponse(statusCode: 200) {
                        isSendingCompleted = true
                    }

                    try? RAnalyticsPushTrackingUtility.trackPushConversionEvent(pushRequestIdentifier: expectedRequestId,
                                                                                pushConversionAction: expectedConversionAction)

                    expect(isSendingCompleted).toAfterTimeout(beTrue(), timeout: 1.0)

                    let ratPayload = sessionMock.sentRequest?.httpBody?.ratPayload

                    let conversionDictionary = ratPayload?.pushConversionJSON

                    let cpDictionary = conversionDictionary?["cp"] as? [String: Any]

                    expect(conversionDictionary).toNot(beNil())

                    expect(conversionDictionary?[PayloadParameterKeys.etype] as? String).to(equal(RAnalyticsEvent.Name.pushNotificationConversion))

                    expect(cpDictionary?[PayloadParameterKeys.pushRequestIdentifier] as? String).to(equal(expectedRequestId))
                    expect(cpDictionary?[PayloadParameterKeys.pushConversionAction] as? String).to(equal(expectedConversionAction))
                }
            }
        }
    }
}

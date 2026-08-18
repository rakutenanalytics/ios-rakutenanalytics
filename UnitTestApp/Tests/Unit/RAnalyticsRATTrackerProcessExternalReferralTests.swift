import Foundation
import Testing
@preconcurrency @testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("External referral tracking tests")
struct ExternalReferralTests {
    static let universalLinkURLForExternalApp = URL(string: "https://www.rakuten.co.jp")!
    var helper = ProcessTestHelper.TestHelper()
    
    @Test("should process an external referrer event")
    mutating func testShouldProcessPageVisitAndDeeplinkEvent() async throws {
        helper.setUp()
        defer { helper.tearDown() }
        
        var payload: [String: Any]?
        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.externalReferrer, parameters: nil)
        let state = RAnalyticsState(sessionIdentifier: "sessionIdentifier", deviceIdentifier: "deviceIdentifier")
        state.referralTracking = .externalReferral(Self.universalLinkURLForExternalApp)
        
        let processed = helper.ratTracker.process(event: event, state: state)
        #expect(processed == true)
        
        try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
            payload = $0.first
        }
        
        try await TestingHelpers.eventually {
            payload != nil
        }
        
        let extraParameters = payload?[PayloadParameterKeys.cp] as? [String: Any]
        
        #expect(payload?[PayloadParameterKeys.ref] as? String == Self.universalLinkURLForExternalApp.absoluteString)
        #expect(extraParameters?[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.external.toString)
    }
}

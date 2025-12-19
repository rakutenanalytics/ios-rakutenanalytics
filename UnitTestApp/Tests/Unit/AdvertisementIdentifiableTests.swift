import Testing
import AdSupport.ASIdentifierManager

@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("AdvertisementIdentifiable")
struct AdvertisementIdentifiableTests {
    @Suite("advertisingIdentifierUUIDString")
    struct AdvertisingIdentifierUUIDStringTests {
        @Test("should return a non-empty value")
        func testReturnsNonEmptyValue() {
            let result = ASIdentifierManager.shared().advertisingIdentifierUUIDString
            #expect(!result.isEmpty)
        }

        @Test("should return 00000000-0000-0000-0000-000000000000 when App Tracking Transparency is not asked.")
        func testReturnsZeroUUIDWhenTrackingNotAsked() {
            let result = ASIdentifierManager.shared().advertisingIdentifierUUIDString
            #expect(result == "00000000-0000-0000-0000-000000000000")
        }

        @Test("should never crash")
        func testNeverCrashes() {
            (0..<10000).forEach { _ in
                let result = ASIdentifierManager.shared().advertisingIdentifierUUIDString
                #expect(!result.isEmpty)
            }
        }
    }
}

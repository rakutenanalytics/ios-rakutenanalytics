import UIKit
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsSharedApplicationTests

@Suite("UIApplication")
struct RAnalyticsSharedApplicationTests {
    @Suite("RAnalyticsSharedApplication")
    struct SharedApplicationTests {
        @Test("should not return nil")
        func testShouldNotReturnNil() {
            #if SWIFT_PACKAGE
            // There is no application running in SPM
            #else
            #expect(UIApplication.RAnalyticsSharedApplication != nil)
            #endif
        }
    }
}

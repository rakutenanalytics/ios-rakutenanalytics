import Quick
import Nimble
import UIKit
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsSharedApplicationSpec

final class RAnalyticsSharedApplicationSpec: QuickSpec {
    override func spec() {
        describe("UIApplication") {
            describe("RAnalyticsSharedApplication") {
                it("should not return nil") {
                    #if SWIFT_PACKAGE
                    // There is no application running in SPM
                    #else
                    expect(UIApplication.RAnalyticsSharedApplication).toNot(beNil())
                    #endif
                }
            }
        }
    }
}

import Quick
import Nimble
import Foundation
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - CoreSubspecSpec

final class CoreSubspecSpec: QuickSpec {
    override func spec() {
        describe("CoreSubspec") {
            it("should not contain RAnalyticsRATTracker") {
                expect(NSClassFromString("RAnalyticsRATTracker")).to(beNil())
            }
        }
    }
}

import Quick
import Nimble
@testable import RAnalytics

// MARK: - CoreSubspecSpec

final class CoreSubspecSpec: QuickSpec {
    override func spec() {
        describe("CoreSubspec") {
            it("should not contain RAnalyticsRATTracker") {
                expect(NSClassFromString("RAnalyticsRATTracker")).to(beNil())
            }

            it("should contain SDKTracker") {
                let trackers = AnalyticsManager.shared().trackers

                expect(trackers).toNot(beNil())
                expect(trackers.count).to(equal(1))

                let sdkTrackerIsContained = trackers.first(where: { $0 is SDKTracker }) != nil
                expect(sdkTrackerIsContained).to(beTrue())
            }
        }
    }
}

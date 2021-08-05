import Quick
import Nimble
import UIKit
@testable import RAnalytics

// MARK: - RAnalyticsSharedApplicationSpec

final class RAnalyticsSharedApplicationSpec: QuickSpec {
    override func spec() {
        describe("UIApplication") {
            describe("RAnalyticsSharedApplication") {
                it("should not return nil") {
                    expect(UIApplication.RAnalyticsSharedApplication).toNot(beNil())
                }
            }
        }
    }
}

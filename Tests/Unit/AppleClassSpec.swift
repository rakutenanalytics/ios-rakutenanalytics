import Quick
import Nimble
import UIKit
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - AppleClassSpec

final class AppleClassSpec: QuickSpec {
    override func spec() {
        describe("NSObject") {
            describe("isAppleClass") {
                it("should return true if the class is an Apple class") {
                    expect(NSObject.isAppleClass(UIViewController.self)).to(beTrue())
                }

                it("should return false if the class is a non-Apple class") {
                    expect(NSObject.isAppleClass(AnalyticsManager.self)).to(beFalse())
                }

                it("should return false if the class pointer is Nil") {
                    expect(NSObject.isAppleClass(nil)).to(beFalse())
                }
            }
        }
    }
}

import Testing
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - AppleClassTests

@Suite("NSObject")
struct AppleClassTests {
    @Suite("isAppleClass")
    struct IsAppleClassTests {
        @Test("should return true if the class is an Apple class")
        func testReturnsTrueIfClassIsAppleClass() {
            #expect(NSObject.isAppleClass(UIViewController.self) == true)
        }

        @Test("should return false if the class is a non-Apple class")
        func testReturnsFalseIfClassIsNonAppleClass() {
            #expect(NSObject.isAppleClass(AnalyticsManager.self) == false)
        }

        @Test("should return false if the class pointer is Nil")
        func testReturnsFalseIfClassPointerIsNil() {
            #expect(NSObject.isAppleClass(nil) == false)
        }
    }
}

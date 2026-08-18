import CoreLocation
import UIKit
import Testing
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsStateTests

@Suite("AnalyticsManager.State")
struct RAnalyticsStateTests {
    // Shared test data
    static let sessionIdentifier = "CA7A88AR-82FE-40C9-A836-B1B3455DECAF"
    static let deviceIdentifier = "deviceId"
    static let advertisingIdentifier = "adId"
    static let userIdentifier = "userId"
    static let easyIdentifier = "easyId"
    static let currentVersion = "2.0"
    static let lastVersion = "1.0"
    
    static var bundle: BundleMock {
        let bundle = BundleMock()
        bundle.shortVersion = currentVersion
        return bundle
    }
    
    static var dateComponents: DateComponents {
        DateComponents(year: 2016, month: 6, day: 10, hour: 9, minute: 15, second: 30)
    }
    
    static var calendar: Calendar {
        Calendar(identifier: .gregorian)
    }
    
    static var sessionStartDate: Date? {
        calendar.date(from: dateComponents)
    }
    
    static var initialLaunchDate: Date? {
        calendar.date(from: DateComponents(year: 2016, month: 6, day: 10))
    }
    
    static var lastLaunchDate: Date? {
        calendar.date(from: DateComponents(year: 2016, month: 7, day: 12))
    }
    
    static var lastUpdateDate: Date? {
        calendar.date(from: DateComponents(year: 2016, month: 7, day: 11))
    }
    
    static func makeCurrentPage() async -> UIViewController {
        await MainActor.run {
            let viewController = UIViewController()
            viewController.view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            return viewController
        }
    }
    
    static var model: ReferralAppModel {
        ReferralAppModel(
            bundleIdentifier: "jp.co.rakuten.app",
            accountIdentifier: 1,
            applicationIdentifier: 2,
            link: nil,
            component: nil,
            customParameters: nil)
    }
    
    static var location: CLLocation {
        CLLocation(latitude: -56.6462520, longitude: -36.6462520)
    }
    
    struct TestHelper {
        static func makeDefaultState() -> AnalyticsManager.State {
            let state = AnalyticsManager.State(sessionIdentifier: sessionIdentifier, deviceIdentifier: deviceIdentifier, for: bundle)
            state.advertisingIdentifier = advertisingIdentifier
            state.lastKnownLocation = LocationModel(location: location, isAction: false, actionParameters: nil)
            state.loginMethod = .oneTapLogin
            state.origin = .external
            state.lastVersion = "1.0"
            state.lastVersionLaunches = 10
            state.sessionStartDate = sessionStartDate
            state.initialLaunchDate = initialLaunchDate
            state.lastLaunchDate = lastLaunchDate
            state.lastUpdateDate = lastUpdateDate
            state.userIdentifier = userIdentifier
            state.easyIdentifier = easyIdentifier
            state.loggedIn = true
            return state
        }
        
        static func makeStateForVisitedUIKitPage(currentPage: UIViewController) -> AnalyticsManager.State {
            let state: AnalyticsManager.State! = makeDefaultState().copy() as? AnalyticsManager.State
            state.referralTracking = .page(currentPage: currentPage)
            return state
        }
        
        static func makeStateForVisitedSwiftUIPage() -> AnalyticsManager.State {
            let state: AnalyticsManager.State! = makeDefaultState().copy() as? AnalyticsManager.State
            state.referralTracking = .swiftuiPage(pageName: "MyView")
            return state
        }
        
        static func makeStateForReferralAppTracking() -> AnalyticsManager.State {
            let state: AnalyticsManager.State! = makeDefaultState().copy() as? AnalyticsManager.State
            state.referralTracking = .referralApp(model)
            return state
        }
        
        static func verify(_ state: AnalyticsManager.State) {
            #expect(state.sessionIdentifier == sessionIdentifier)
            #expect(state.deviceIdentifier == deviceIdentifier)
            #expect(state.currentVersion == currentVersion)
            #expect(state.advertisingIdentifier == advertisingIdentifier)
            #expect(state.lastKnownLocation?.latitude == location.coordinate.latitude)
            #expect(state.lastKnownLocation?.longitude == location.coordinate.longitude)
            #expect(state.sessionStartDate == sessionStartDate)
            #expect(state.isLoggedIn == true)
            #expect(state.userIdentifier == userIdentifier)
            #expect(state.easyIdentifier == easyIdentifier)
            #expect(state.lastVersion == lastVersion)
            #expect(state.initialLaunchDate == initialLaunchDate)
            #expect(state.lastLaunchDate == lastLaunchDate)
            #expect(state.lastUpdateDate == lastUpdateDate)
            #expect(state.lastVersionLaunches == 10)
            #expect(state.loginMethod == .oneTapLogin)
            #expect(state.origin == .external)
        }
    }
    
    @Suite("init")
    struct InitTests {
        @Test("should have the correct default values")
        func testShouldHaveCorrectDefaultValues() {
            let state = AnalyticsManager.State(sessionIdentifier: RAnalyticsStateTests.sessionIdentifier, deviceIdentifier: RAnalyticsStateTests.deviceIdentifier, for: RAnalyticsStateTests.bundle)
            #expect(state.sessionIdentifier == RAnalyticsStateTests.sessionIdentifier)
            #expect(state.deviceIdentifier == RAnalyticsStateTests.deviceIdentifier)
            #expect(state.currentVersion == RAnalyticsStateTests.currentVersion)
            #expect(state.advertisingIdentifier == nil)
            #expect(state.lastKnownLocation == nil)
            #expect(state.sessionStartDate == nil)
            #expect(state.loggedIn == false)
            #expect(state.userIdentifier == nil)
            #expect(state.easyIdentifier == nil)
            #expect(state.lastVersion == nil)
            #expect(state.initialLaunchDate == nil)
            #expect(state.lastLaunchDate == nil)
            #expect(state.lastUpdateDate == nil)
            #expect(state.lastVersionLaunches == 0)
            #expect(state.loginMethod == .other)
            #expect(state.origin == .inner)
            #expect(state.referralTracking == ReferralTrackingType.none)
        }
    }
    
    @Suite("setting")
    struct SettingTests {
        @Suite("Visited UIKit page")
        struct VisitedUIKitPageTests {
            @Test("should have the expected values")
            func testShouldHaveExpectedValues() async throws {
                let currentPage = await RAnalyticsStateTests.makeCurrentPage()
                let state = TestHelper.makeStateForVisitedUIKitPage(currentPage: currentPage)
                TestHelper.verify(state)
                // Check that referralTracking is .page case (can't compare UIViewController instances directly)
                if case .page(let page) = state.referralTracking {
                    #expect(page === currentPage)
                } else {
                    Issue.record("Expected .page case")
                }
            }
        }
        
        @Suite("Visited SwiftUI page")
        struct VisitedSwiftUIPageTests {
            @Test("should have the expected values")
            func testShouldHaveExpectedValues() {
                let state = TestHelper.makeStateForVisitedSwiftUIPage()
                TestHelper.verify(state)
                #expect(state.referralTracking == .swiftuiPage(pageName: "MyView"))
            }
        }
        
        @Suite("Referral app tracking")
        struct ReferralAppTrackingTests {
            @Test("should have the expected values")
            func testShouldHaveExpectedValues() {
                let state = TestHelper.makeStateForReferralAppTracking()
                TestHelper.verify(state)
                #expect(state.referralTracking == .referralApp(RAnalyticsStateTests.model))
            }
        }
    }
    
    @Suite("copy")
    struct CopyTests {
        @Suite("Visited UIKit page")
        struct VisitedUIKitPageTests {
            @Test("should have the expected values")
            func testShouldHaveExpectedValues() async throws {
                let currentPage = await RAnalyticsStateTests.makeCurrentPage()
                let originalState = TestHelper.makeStateForVisitedUIKitPage(currentPage: currentPage)
                guard let state = originalState.copy() as? AnalyticsManager.State else {
                    Issue.record("AnalyticsManager.State copy fails")
                    return
                }
                TestHelper.verify(state)
                // Check that referralTracking is .page case
                if case .page(let page) = state.referralTracking {
                    #expect(page === currentPage)
                } else {
                    Issue.record("Expected .page case")
                }
            }
        }
        
        @Suite("Visited SwiftUI page")
        struct VisitedSwiftUIPageTests {
            @Test("should have the expected values")
            func testShouldHaveExpectedValues() {
                guard let state = TestHelper.makeStateForVisitedSwiftUIPage().copy() as? AnalyticsManager.State else {
                    Issue.record("AnalyticsManager.State copy fails")
                    return
                }
                TestHelper.verify(state)
                #expect(state.referralTracking == .swiftuiPage(pageName: "MyView"))
            }
        }
        
        @Suite("Referral app tracking")
        struct ReferralAppTrackingTests {
            @Test("should have the expected values")
            func testShouldHaveExpectedValues() {
                guard let state = TestHelper.makeStateForReferralAppTracking().copy() as? AnalyticsManager.State else {
                    Issue.record("AnalyticsManager.State copy fails")
                    return
                }
                TestHelper.verify(state)
                #expect(state.referralTracking == .referralApp(RAnalyticsStateTests.model))
            }
        }
    }
    
    @Suite("equal")
    struct EqualTests {
        @Suite("Visited UIKit page")
        struct VisitedUIKitPageTests {
            @Test("should be true if it has the same properties of an other state")
            func testShouldBeTrueIfSameProperties() async throws {
                let currentPage = await RAnalyticsStateTests.makeCurrentPage()
                let state = TestHelper.makeStateForVisitedUIKitPage(currentPage: currentPage)
                guard let copiedState = state.copy() as? AnalyticsManager.State else {
                    Issue.record("AnalyticsManager.State copy fails")
                    return
                }
                #expect(state == copiedState)
            }
            
            @Test("should be false if it has not the same properties of an other state")
            func testShouldBeFalseIfDifferentProperties() async throws {
                let currentPage = await RAnalyticsStateTests.makeCurrentPage()
                let state = TestHelper.makeStateForVisitedUIKitPage(currentPage: currentPage)
                let otherState = AnalyticsManager.State(sessionIdentifier: RAnalyticsStateTests.sessionIdentifier, deviceIdentifier: "differentDeviceId")
                #expect(state != otherState)
            }
            
            @Test("should be false if it doesn't match the State type")
            func testShouldBeFalseIfDifferentType() async throws {
                let currentPage = await RAnalyticsStateTests.makeCurrentPage()
                let state = TestHelper.makeStateForVisitedUIKitPage(currentPage: currentPage)
                let anObject = NSObject()
                #expect(state != anObject)
            }
        }
        
        @Suite("Visited SwiftUI page")
        struct VisitedSwiftUIPageTests {
            @Test("should be true if it has the same properties of an other state")
            func testShouldBeTrueIfSameProperties() {
                let state = TestHelper.makeStateForVisitedSwiftUIPage()
                guard let copiedState = state.copy() as? AnalyticsManager.State else {
                    Issue.record("AnalyticsManager.State copy fails")
                    return
                }
                #expect(state == copiedState)
            }
            
            @Test("should be false if it has not the same properties of an other state")
            func testShouldBeFalseIfDifferentProperties() {
                let state = TestHelper.makeStateForVisitedSwiftUIPage()
                let otherState = AnalyticsManager.State(sessionIdentifier: RAnalyticsStateTests.sessionIdentifier, deviceIdentifier: "differentDeviceId")
                #expect(state != otherState)
            }
            
            @Test("should be false if it doesn't match the State type")
            func testShouldBeFalseIfDifferentType() {
                let state = TestHelper.makeStateForVisitedSwiftUIPage()
                let anObject = NSObject()
                #expect(state != anObject)
            }
        }
        
        @Suite("Referral app tracking")
        struct ReferralAppTrackingTests {
            @Test("should be true if it has the same properties of an other state")
            func testShouldBeTrueIfSameProperties() {
                let state = TestHelper.makeStateForReferralAppTracking()
                guard let copiedState = state.copy() as? AnalyticsManager.State else {
                    Issue.record("AnalyticsManager.State copy fails")
                    return
                }
                #expect(state == copiedState)
            }
            
            @Test("should be false if it has not the same properties of an other state")
            func testShouldBeFalseIfDifferentProperties() {
                let state = TestHelper.makeStateForReferralAppTracking()
                let otherState = AnalyticsManager.State(sessionIdentifier: RAnalyticsStateTests.sessionIdentifier, deviceIdentifier: "differentDeviceId")
                #expect(state != otherState)
            }
            
            @Test("should be false if it doesn't match the State type")
            func testShouldBeFalseIfDifferentType() async throws {
                let state = TestHelper.makeStateForReferralAppTracking()
                let anObject = await MainActor.run {
                    UIView()
                }
                #expect(state != anObject)
            }
        }
    }
    
    @Suite("hash")
    struct HashTests {
        @Suite("Visited UIKit page")
        struct VisitedUIKitPageTests {
            @Test("should be identical if it is a copy of an other state")
            func testShouldBeIdenticalIfCopy() async throws {
                let currentPage = await RAnalyticsStateTests.makeCurrentPage()
                let state = TestHelper.makeStateForVisitedUIKitPage(currentPage: currentPage)
                guard let copiedState = state.copy() as? AnalyticsManager.State else {
                    Issue.record("AnalyticsManager.State copy fails")
                    return
                }
                #expect(state.hash == copiedState.hash)
            }
            
            @Test("should not be identical if the properties are different")
            func testShouldNotBeIdenticalIfDifferentProperties() async throws {
                let currentPage = await RAnalyticsStateTests.makeCurrentPage()
                let state = TestHelper.makeStateForVisitedUIKitPage(currentPage: currentPage)
                let otherState = AnalyticsManager.State(sessionIdentifier: RAnalyticsStateTests.sessionIdentifier, deviceIdentifier: "differentDeviceId")
                #expect(state.hash != otherState.hash)
            }
        }
        
        @Suite("Visited SwiftUI page")
        struct VisitedSwiftUIPageTests {
            @Test("should be identical if it is a copy of an other state")
            func testShouldBeIdenticalIfCopy() {
                let state = TestHelper.makeStateForVisitedSwiftUIPage()
                guard let copiedState = state.copy() as? AnalyticsManager.State else {
                    Issue.record("AnalyticsManager.State copy fails")
                    return
                }
                #expect(state.hash == copiedState.hash)
            }
            
            @Test("should not be identical if the properties are different")
            func testShouldNotBeIdenticalIfDifferentProperties() {
                let state = TestHelper.makeStateForVisitedSwiftUIPage()
                let otherState = AnalyticsManager.State(sessionIdentifier: RAnalyticsStateTests.sessionIdentifier, deviceIdentifier: "differentDeviceId")
                #expect(state.hash != otherState.hash)
            }
        }
        
        @Suite("Referral app tracking")
        struct ReferralAppTrackingTests {
            @Test("should be identical if it is a copy of an other state")
            func testShouldBeIdenticalIfCopy() {
                let state = TestHelper.makeStateForReferralAppTracking()
                guard let copiedState = state.copy() as? AnalyticsManager.State else {
                    Issue.record("AnalyticsManager.State copy fails")
                    return
                }
                #expect(state.hash == copiedState.hash)
            }
            
            @Test("should not be identical if the properties are different")
            func testShouldNotBeIdenticalIfDifferentProperties() {
                let state = TestHelper.makeStateForReferralAppTracking()
                let otherState = AnalyticsManager.State(sessionIdentifier: RAnalyticsStateTests.sessionIdentifier, deviceIdentifier: "differentDeviceId")
                #expect(state.hash != otherState.hash)
            }
        }
    }
}

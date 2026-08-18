import Testing
import UIKit
@testable import RakutenAnalytics

@Suite("GeoLaunchConfigurator")
struct GeoLaunchConfiguratorTests {
    @Test("resetForTesting is idempotent and leaves the configurator functional")
    func testResetForTestingIsIdempotent() {
        GeoLaunchConfigurator.resetForTesting()
        GeoLaunchConfigurator.resetForTesting()
        #expect(GeoLaunchConfigurator.isLocationLaunch(from: [UIApplication.LaunchOptionsKey.location: true]) == true)
    }

    @Test("requests continual location updates only for location launches")
    func testRequestsContinualLocationUpdatesOnlyForLocationLaunches() {
        #expect(GeoLaunchConfigurator.shouldRequestContinualLocationUpdate(isLocationLaunch: true) == true)
        #expect(GeoLaunchConfigurator.shouldRequestContinualLocationUpdate(isLocationLaunch: false) == false)
    }

    @Suite("isLocationLaunch(from:)")
    struct IsLocationLaunchTests {
        @Test("returns false for nil userInfo")
        func testReturnsFalseForNilUserInfo() {
            #expect(GeoLaunchConfigurator.isLocationLaunch(from: nil) == false)
        }

        @Test("returns false when location key is absent")
        func testReturnsFalseWhenLocationKeyAbsent() {
            #expect(GeoLaunchConfigurator.isLocationLaunch(from: [:]) == false)
        }

        @Test("returns true for Bool value under LaunchOptionsKey.location")
        func testReturnsTrueForBoolUnderLaunchOptionsKey() {
            let userInfo: [AnyHashable: Any] = [UIApplication.LaunchOptionsKey.location: true]
            #expect(GeoLaunchConfigurator.isLocationLaunch(from: userInfo) == true)
        }

        @Test("returns true for Bool value under raw string key")
        func testReturnsTrueForBoolUnderRawStringKey() {
            let userInfo: [AnyHashable: Any] = [UIApplication.LaunchOptionsKey.location.rawValue: true]
            #expect(GeoLaunchConfigurator.isLocationLaunch(from: userInfo) == true)
        }

        @Test("returns true for NSNumber value under LaunchOptionsKey.location")
        func testReturnsTrueForNSNumberUnderLaunchOptionsKey() {
            let userInfo: [AnyHashable: Any] = [UIApplication.LaunchOptionsKey.location: NSNumber(value: true)]
            #expect(GeoLaunchConfigurator.isLocationLaunch(from: userInfo) == true)
        }

        @Test("returns true for NSNumber value under raw string key")
        func testReturnsTrueForNSNumberUnderRawStringKey() {
            let userInfo: [AnyHashable: Any] = [UIApplication.LaunchOptionsKey.location.rawValue: NSNumber(value: true)]
            #expect(GeoLaunchConfigurator.isLocationLaunch(from: userInfo) == true)
        }

        @Test("returns false when location value is false")
        func testReturnsFalseWhenLocationValueIsFalse() {
            let userInfo: [AnyHashable: Any] = [UIApplication.LaunchOptionsKey.location: false]
            #expect(GeoLaunchConfigurator.isLocationLaunch(from: userInfo) == false)
        }
    }
}

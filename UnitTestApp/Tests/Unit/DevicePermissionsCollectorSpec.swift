import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class AnalyticsDevicePermissionCollectorSpec: QuickSpec {
    override func spec() {
        describe("AnalyticsDevicePermissionCollector") {
            var collector: MockDevicePermissionCollector!
            
            beforeEach {
                collector = MockDevicePermissionCollector.shared
            }
            
            context("when collecting all permissions") {
                it("returns the correct combined permissions string for various states") {
                    if #available(iOS 14, *) {
                        collector.setup(locationAuthStatus: .notDetermined,
                                        notificationsAuthStatus: .notDetermined,
                                        trackingAuthStatus: .notDetermined,
                                        videoAuthStatus: .notDetermined,
                                        audioAuthStatus: .notDetermined)
                        
                        expect(collector.collectPermissions()).to(equal("00000"))
                        
                        collector.setup(locationAuthStatus: .denied,
                                        notificationsAuthStatus: .denied,
                                        trackingAuthStatus: .denied,
                                        videoAuthStatus: .denied,
                                        audioAuthStatus: .denied)
                        
                        expect(collector.collectPermissions()).to(equal("00000"))
                        
                        collector.setup(locationAuthStatus: .authorizedAlways,
                                        notificationsAuthStatus: .authorized,
                                        trackingAuthStatus: .authorized,
                                        videoAuthStatus: .authorized,
                                        audioAuthStatus: .authorized)
                        
                        expect(collector.collectPermissions()).to(equal("21111"))
                        
                        collector.setup(locationAuthStatus: .authorizedWhenInUse,
                                        notificationsAuthStatus: .denied,
                                        trackingAuthStatus: .notDetermined,
                                        videoAuthStatus: .authorized,
                                        audioAuthStatus: .denied)
                        
                        expect(collector.collectPermissions()).to(equal("10010"))
                    } else {}
                }
            }
        }
    }
}




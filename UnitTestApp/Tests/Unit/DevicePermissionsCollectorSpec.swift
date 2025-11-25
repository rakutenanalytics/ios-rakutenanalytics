import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class AnalyticsDevicePermissionCollectorSpec: QuickSpec {
    override class func spec() {
        describe("AnalyticsDevicePermissionCollector") {
            var collector: MockDevicePermissionCollector!
            
            beforeEach {
                collector = MockDevicePermissionCollector.shared
            }
            
            context("when collecting all permissions") {
                it("should return default values") {
                    if #available(iOS 14, *) {
                        expect(AnalyticsDevicePermissionCollector.shared.collectPermissions()).to(equal("00000"))
                    }
                }
                
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
            
            context("when collecting all permissions") {
                it("permission type descripton should be correct") {
                    var permissionType: DevicePermissionType = .allowed
                    expect(permissionType.description).to(equal("Allowed. Used with Location, Notification, Privacy ID, Camera and Microfone permissions."))
                    
                    permissionType = .none
                    expect(permissionType.description).to(equal("No permission. Used with Location, Notification, Privacy ID, Camera and Microfone permissions."))
                    
                    permissionType = .foregroundOnly
                    expect(permissionType.description).to(equal("Foreground only. Used with Location permissions."))
                    
                    permissionType = .alwaysAllow
                    expect(permissionType.description).to(equal("Always allow. Used with Location permissions."))
                }
            }
        }
    }
}




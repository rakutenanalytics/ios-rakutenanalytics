import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("AnalyticsDevicePermissionCollector")
struct AnalyticsDevicePermissionCollectorTests {
    var collector: MockDevicePermissionCollector!
    
    mutating func setUp() {
        collector = MockDevicePermissionCollector.shared
    }
    
    @Suite("when collecting all permissions")
    struct WhenCollectingAllPermissionsTests {
        @Test("should return default values")
        func testShouldReturnDefaultValues() {
            guard #available(iOS 14, *) else {
                return
            }
            #expect(AnalyticsDevicePermissionCollector.shared.collectPermissions() == "00000")
        }
        
        @Test("returns the correct combined permissions string for various states")
        func testReturnsCorrectCombinedPermissionsStringForVariousStates() {
            guard #available(iOS 14, *) else {
                return
            }
            
            var spec = AnalyticsDevicePermissionCollectorTests()
            spec.setUp()
            
            spec.collector.setup(
                locationAuthStatus: .notDetermined,
                notificationsAuthStatus: .notDetermined,
                trackingAuthStatus: .notDetermined,
                videoAuthStatus: .notDetermined,
                audioAuthStatus: .notDetermined)
            
            #expect(spec.collector.collectPermissions() == "00000")
            
            spec.collector.setup(
                locationAuthStatus: .denied,
                notificationsAuthStatus: .denied,
                trackingAuthStatus: .denied,
                videoAuthStatus: .denied,
                audioAuthStatus: .denied)
            
            #expect(spec.collector.collectPermissions() == "00000")
            
            spec.collector.setup(
                locationAuthStatus: .authorizedAlways,
                notificationsAuthStatus: .authorized,
                trackingAuthStatus: .authorized,
                videoAuthStatus: .authorized,
                audioAuthStatus: .authorized)
            
            #expect(spec.collector.collectPermissions() == "21111")
            
            spec.collector.setup(
                locationAuthStatus: .authorizedWhenInUse,
                notificationsAuthStatus: .denied,
                trackingAuthStatus: .notDetermined,
                videoAuthStatus: .authorized,
                audioAuthStatus: .denied)
            
            #expect(spec.collector.collectPermissions() == "10010")
        }
    }
    
    @Suite("when collecting all permissions")
    struct WhenCollectingAllPermissionsDescriptionTests {
        @Test("permission type descripton should be correct")
        func testPermissionTypeDescriptionShouldBeCorrect() {
            var permissionType: DevicePermissionType = .allowed
            #expect(permissionType.description == "Allowed. Used with Location, Notification, Privacy ID, Camera and Microfone permissions.")
            
            permissionType = .none
            #expect(permissionType.description == "No permission. Used with Location, Notification, Privacy ID, Camera and Microfone permissions.")
            
            permissionType = .foregroundOnly
            #expect(permissionType.description == "Foreground only. Used with Location permissions.")
            
            permissionType = .alwaysAllow
            #expect(permissionType.description == "Always allow. Used with Location permissions.")
        }
    }
}

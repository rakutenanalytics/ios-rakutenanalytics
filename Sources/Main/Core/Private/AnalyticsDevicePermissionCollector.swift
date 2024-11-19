import Foundation
import CoreLocation
import UserNotifications
import AppTrackingTransparency
import AVFoundation

enum DevicePermissionType {
    case none
    case allowed
    case foregroundOnly
    case alwaysAllow

    var description: String {
        switch self {
        case .none:
            return "No permission. Used with Location, Notification, Privacy ID, Camera and Microfone permissions."
        case .allowed:
            return "Allowed. Used with Location, Notification, Privacy ID, Camera and Microfone permissions."
        case .foregroundOnly:
            return "Foreground only. Used with Location permissions."
        case .alwaysAllow:
            return "Always allow. Used with Location permissions."
        }
    }

    var rawValue: String {
        switch self {
        case .none:
            return "0"
        case .allowed, .foregroundOnly:
            return "1"
        case .alwaysAllow:
            return "2"
        }
    }
}

protocol DevicePermissionCollector {
    func collectPermissions() -> String
}

final class AnalyticsDevicePermissionCollector: NSObject, CLLocationManagerDelegate, DevicePermissionCollector {
    
    static let shared = AnalyticsDevicePermissionCollector()
    
    /// Collect permissions in order: Location (0..2) → Notification (0..1) → Privacy ID (0..1) → Camera (0..1) → Microphone (0..1).
    func collectPermissions() -> String {
        var permissions = [String]()
        
        permissions.append(collectLocationPermissions())
        permissions.append(collectNotificationPermissions())
        permissions.append(collectPrivacyIDPermissions())
        permissions.append(collectCameraPermissions())
        permissions.append(collectMicrophonePermissions())
        
        return permissions.joined()
    }
    
    /// Collect location permissions
    private func collectLocationPermissions() -> String {
        if #available(iOS 14, *) {
            switch CLLocationManager().authorizationStatus {
            case .restricted, .denied, .notDetermined:
                return DevicePermissionType.none.rawValue
            case .authorizedWhenInUse:
                return DevicePermissionType.foregroundOnly.rawValue
            case .authorizedAlways:
                return DevicePermissionType.alwaysAllow.rawValue
            @unknown default:
                return DevicePermissionType.none.rawValue
            }
        } else {
            switch CLLocationManager.authorizationStatus() {
            case .restricted, .denied, .notDetermined:
                return DevicePermissionType.none.rawValue
            case .authorizedWhenInUse:
                return DevicePermissionType.foregroundOnly.rawValue
            case .authorizedAlways:
                return DevicePermissionType.alwaysAllow.rawValue
            @unknown default:
                return DevicePermissionType.none.rawValue
            }
        }
    }
    
    /// Collect notification permissions
    private func collectNotificationPermissions() -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var permission = DevicePermissionType.none.rawValue
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined, .denied:
                permission = DevicePermissionType.none.rawValue
            case .authorized, .provisional, .ephemeral:
                permission = DevicePermissionType.allowed.rawValue
            @unknown default:
                permission = DevicePermissionType.none.rawValue
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return permission
    }
    
    /// Collect privacy ID permissions
    private func collectPrivacyIDPermissions() -> String {
        if #available(iOS 14, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
            case .denied, .notDetermined, .restricted:
                return DevicePermissionType.none.rawValue
            case .authorized:
                return DevicePermissionType.allowed.rawValue
            @unknown default:
                return DevicePermissionType.none.rawValue
            }
        } else {
            return DevicePermissionType.none.rawValue
        }
    }
    
    /// Collect camera permissions
    private func collectCameraPermissions() -> String {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined, .denied:
            return DevicePermissionType.none.rawValue
        case .restricted, .authorized:
            return DevicePermissionType.allowed.rawValue
        @unknown default:
            return DevicePermissionType.none.rawValue
        }
    }
    
    /// Collect microphone permissions
    private func collectMicrophonePermissions() -> String {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined, .denied:
            return DevicePermissionType.none.rawValue
        case .restricted, .authorized:
            return DevicePermissionType.allowed.rawValue
        @unknown default:
            return DevicePermissionType.none.rawValue
        }
    }
}

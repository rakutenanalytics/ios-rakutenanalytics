import UIKit
import CoreLocation
import RakutenAnalytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Override the build time configuration of disabled automatic events defined in `RAnalyticsInfo.plist`
        AnalyticsManager.shared().shouldTrackEventHandler = { _ in
            true
        }
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.requestWhenInUseAuthorization()

        AnalyticsManager.shared().set(loggingLevel: .debug)
        AnalyticsManager.shared().enableAppToWebTracking = true

        AnalyticsManager.shared().setWebTrackingCookieDomain { () -> String? in
            return ".my-domain.co.jp"
        }

        RAnalyticsRATTracker.shared().set(batchingDelay: 15)
        AnalyticsManager.shared().set(endpointURL: URL(string: "https://rat.rakuten.co.jp/"))

        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }

        return true
    }
}

extension Data {
    var hexadecimal: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}

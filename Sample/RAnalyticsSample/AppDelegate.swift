import UIKit
import CoreLocation
import RakutenAnalytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    let locationManager = CLLocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AnalyticsManager.shared().shouldTrackEventHandler = { _ in
            true
        }

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

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

extension Data {
    var hexadecimal: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}

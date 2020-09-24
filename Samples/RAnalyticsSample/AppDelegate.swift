import UIKit
import CoreLocation
import RAnalytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.requestWhenInUseAuthorization()
        
        AnalyticsManager.shared().set(loggingLevel: .debug)

        RAnalyticsRATTracker.shared().set(batchingDelay: 15)

        return true
    }
}

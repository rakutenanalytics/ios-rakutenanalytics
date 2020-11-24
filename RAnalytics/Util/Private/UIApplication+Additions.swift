import UIKit

@objc public extension UIApplication {
    static var ratStatusBarOrientation: UIInterfaceOrientation {
        guard let statusBarOrientation = UIApplication.RAnalyticsSharedApplication?.statusBarOrientation else {
            // [UIApplication sharedApplication] is not available for App Extension
            return .portrait // default returned value
        }
        return statusBarOrientation
    }
}

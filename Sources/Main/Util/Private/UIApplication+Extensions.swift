import Foundation
import UIKit

// MARK: - StatusBarOrientationGettable

protocol StatusBarOrientationGettable {
    var analyticsStatusBarOrientation: UIInterfaceOrientation { get }
}

extension UIApplication: StatusBarOrientationGettable {
    var analyticsStatusBarOrientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *) {
            guard let interfaceOrientation = windows.first?.windowScene?.interfaceOrientation else {
                return .portrait // default value
            }
            return interfaceOrientation

        } else {
            return statusBarOrientation
        }
    }
}

// MARK: - RAnalyticsSharedApplication

extension UIApplication {
    static var RAnalyticsSharedApplication: UIApplication? {
        UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication
    }
}

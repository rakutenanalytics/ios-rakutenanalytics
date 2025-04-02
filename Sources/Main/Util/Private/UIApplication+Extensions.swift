import Foundation
import UIKit

// MARK: - StatusBarOrientationGettable

protocol StatusBarOrientationGettable {
    var analyticsStatusBarOrientation: UIInterfaceOrientation { get }
}

extension UIApplication: StatusBarOrientationGettable {
    var analyticsStatusBarOrientation: UIInterfaceOrientation {
        if let interfaceOrientation = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first?.windowScene?.interfaceOrientation {
            return interfaceOrientation
        } else if let interfaceOrientation = delegate?.window??.windowScene?.interfaceOrientation {
            return interfaceOrientation
        } else {
            return .portrait
        }
    }
}

// MARK: - RAnalyticsSharedApplication

extension UIApplication {
    static var RAnalyticsSharedApplication: UIApplication? {
        UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication
    }
}

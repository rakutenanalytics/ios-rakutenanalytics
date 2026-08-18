import UIKit

private let unknownViewControllerName = "Unknown"

internal extension UIView {
    /// Check if the view is in a valid state for tracking (visible, in window, app active)
    var isValidForTracking: Bool {
        !isHidden && window != nil && UIApplication.shared.applicationState == .active
    }

    /// Find the view controller in the responder chain
    func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let currentResponder = responder {
            if let viewController = currentResponder as? UIViewController {
                return viewController
            }
            responder = currentResponder.next
        }
        return nil
    }

    /// Find the view controller name in the responder chain
    func findViewControllerName() -> String {
        findViewController().map { String(describing: type(of: $0)) } ?? unknownViewControllerName
    }
}

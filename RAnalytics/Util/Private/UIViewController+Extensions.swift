import UIKit

extension UIViewController {
    var isTrackableAsPageVisit: Bool {
        // Don't treat as pages view controllers known to be just
        // content-less chromes around other view controllers.
        // Note: won't catch third-party content-less containers.
        guard !isKind(of: UINavigationController.self)
                && !isKind(of: UISplitViewController.self)
                && !isKind(of: UIPageViewController.self)
                && !isKind(of: UITabBarController.self) else {
            return false
        }

        // Don't treat system popups as pages.
        // Note: "isKind(of className: String) -> Bool" is used here to silent deprecation warnings for UIAlertView and UIActionSheet
        guard !view.isKind(of: "UIAlertView")
                && !view.isKind(of: "UIActionSheet")
                && !isKind(of: "UIAlertController") else {
            return false
        }

        // Don't treat private classes as pages if they come from system frameworks.
        // Note: Won't catch private class not adhering to the _ prefix standard.
        guard !isApplePrivateClass()
                && !view.isApplePrivateClass()
                && !view.window.isApplePrivateClass() else {
            return false
        }

        // Allow UIWindow subclasses except those from system frameworks
        // (so that view controllers presented in e.g. UITextEffectWindow are not
        // counting as pages).
        // This catches most keyboard windows.
        guard view.window.isMember(of: UIWindow.self)
                || !view.window.isAppleClass() else {
            return false
        }
        return true
    }
}

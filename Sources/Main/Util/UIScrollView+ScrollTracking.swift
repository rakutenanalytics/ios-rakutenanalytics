import UIKit
import ObjectiveC

extension UIScrollView {
    private struct AssociatedKeys {
        static var scrollViewIdentifier: UInt8 = 0
    }

    /// Optional identifier for this scroll view (useful for distinguishing multiple scroll views)
    @objc public var scrollViewIdentifier: String? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.scrollViewIdentifier) as? String }
        set { objc_setAssociatedObject(self, &AssociatedKeys.scrollViewIdentifier, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

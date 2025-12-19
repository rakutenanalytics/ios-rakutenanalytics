import Foundation
import UIKit

extension UIApplication {
    static func replaceMethod(_ newSelector: Selector, toClass recipient: AnyClass, replacing originalSelector: Selector) {
        guard let newMethod = class_getInstanceMethod(self, newSelector), let originalMethod = class_getInstanceMethod(recipient, originalSelector) else {
            return
        }
        method_exchangeImplementations(newMethod, originalMethod)
    }
}

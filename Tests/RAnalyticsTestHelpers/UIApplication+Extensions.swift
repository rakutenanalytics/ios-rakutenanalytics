import Foundation
import UIKit

extension UIApplication {
    static func replaceMethod(_ newSelector: Selector, toClass recipient: AnyClass, replacing originalSelector: Selector) {
        let newMethod      = class_getInstanceMethod(self, newSelector)!
        let originalMethod = class_getInstanceMethod(recipient, originalSelector)!
        method_exchangeImplementations(newMethod, originalMethod)
    }
}

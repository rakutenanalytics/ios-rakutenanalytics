import Foundation

internal protocol RAnalyticsClassManipulable: NSObjectProtocol {
    @discardableResult
    static func replaceMethod(_ originalSelector: Selector,
                              inClass recipient: NSObjectProtocol.Type,
                              with newSelector: Selector,
                              onlyIfPresent: Bool) -> Bool
}

internal extension RAnalyticsClassManipulable {

    @discardableResult
    static func replaceMethod(_ originalSelector: Selector,
                              inClass recipient: NSObjectProtocol.Type,
                              with newSelector: Selector,
                              onlyIfPresent: Bool) -> Bool {

        guard let newMethod = class_getInstanceMethod(self, newSelector) else {
            return false
        }
        let originalMethod = class_getInstanceMethod(recipient, originalSelector)
        var resultSelector = originalSelector
        /*
         * If the target method exists, we exchange its implementation with our new one and
         * update originalSelector to still point to the original implementation.
         */
        if let originalMethodUnwrapped = originalMethod {
            method_exchangeImplementations(newMethod, originalMethodUnwrapped)
            resultSelector = newSelector
        }
        /*
         * If the target method doesn't exist but was required, we don't do anything.
         */
        else if onlyIfPresent {
            return false
        }
        /*
         * If at this point no method exists for the selector, it means that either:
         * - The original method didn't exist, so we need to add the new method in its place; or
         * - The original method was replaced, so we need to add back its original implementation (that now
         *   uses what was passed as `newSelector`).
         */
        if class_getInstanceMethod(recipient, resultSelector) == nil {
            class_addMethod(recipient,
                            resultSelector,
                            method_getImplementation(newMethod),
                            method_getTypeEncoding(newMethod))
        }
        return true
    }
}

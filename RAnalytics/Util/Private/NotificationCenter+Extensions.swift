import Foundation

@objc public protocol NotificationObservable {
    func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?)
}

extension NotificationCenter: NotificationObservable {}

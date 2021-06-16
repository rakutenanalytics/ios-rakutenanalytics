import Foundation

@objc public protocol NotificationObservable {
    func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?)
    func observe(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Void) -> NSObjectProtocol
}

extension NotificationCenter: NotificationObservable {
    /// - Note: need to redeclare this method in order to avoid a compiler error ambiguity
    public func observe(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        addObserver(forName: name, object: obj, queue: queue, using: block)
    }
}

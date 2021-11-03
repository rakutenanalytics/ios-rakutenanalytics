import Foundation

protocol NotificationObservable {
    func addObserver(_ observer: Any, selector aSelector: Selector, name aName: Notification.Name?, object anObject: Any?)
    func observe(forName name: Notification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Void) -> NSObjectProtocol
}

extension NotificationCenter: NotificationObservable {
    /// - Note: need to redeclare this method in order to avoid a compiler error ambiguity
    func observe(forName name: Notification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        addObserver(forName: name, object: obj, queue: queue, using: block)
    }
}

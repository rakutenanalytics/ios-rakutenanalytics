import Foundation

/// Note:
/// a compiler error occurs if this method is present in the protocol and if UserDefaults conforms to this protocol:
/// func set(_ value: Any?, forKey defaultName: String)
/// Declaring this method instead solves this error:
/// set(value: Any?, forKey defaultName: String)
@objc public protocol UserStorageHandleable {
    func object(forKey defaultName: String) -> Any?
    func string(forKey defaultName: String) -> String?
    func set(value: Any?, forKey defaultName: String)
}

extension UserDefaults: UserStorageHandleable {
    public func set(value: Any?, forKey defaultName: String) {
        set(value, forKey: defaultName)
    }
}

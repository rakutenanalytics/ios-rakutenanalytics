import Foundation

/// Note:
/// a compiler error occurs if this method is present in the protocol and if UserDefaults conforms to this protocol:
/// func set(_ value: Any?, forKey defaultName: String)
/// Declaring this method instead solves this error:
/// set(value: Any?, forKey defaultName: String)
protocol UserStorageHandleable {
    init?(suiteName suitename: String?)
    func array(forKey defaultName: String) -> [Any]?
    func dictionary(forKey defaultName: String) -> [String: Any]?
    func object(forKey defaultName: String) -> Any?
    func bool(forKey defaultName: String) -> Bool
    func string(forKey defaultName: String) -> String?
    func set(value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
    @discardableResult func synchronize() -> Bool
}

extension UserDefaults: UserStorageHandleable {
    func set(value: Any?, forKey defaultName: String) {
        set(value, forKey: defaultName)
    }
}

import Foundation

enum UserDefaultsKeys {
    static let userAgentKey = "UserAgent"
    static let locationCollectionKey = "RATGeoLocationCollection"
    static let locationTimestampKey = "RATGeoLocationTimestamp"
    static let configurationKey = "RATGeoCongiuration"
    static let geoScheduleStartTimeKey = "RATGeoScheduleStartTime"
    static let carrierPrimaryNameKey = "RATCarrierPrimaryName"
    static let carrierSecondaryNameKey = "RATCarrierSecondaryName"
}

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
    func data(forKey defaultName: String) -> Data?
    func bool(forKey defaultName: String) -> Bool
    func string(forKey defaultName: String) -> String?
    func double(forKey key: String) -> Double
    func set(value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
    func register(defaults registrationDictionary: [String: Any])
    @discardableResult func synchronize() -> Bool
}

extension UserDefaults: UserStorageHandleable {
    func set(value: Any?, forKey defaultName: String) {
        set(value, forKey: defaultName)
    }
}

extension UserStorageHandleable {
    /// - Returns: `true` when there is a value for `RATGeoScheduleStartTime`  key, or `false` otherwise.
    var shouldContinueGeoBackgroundTimer: Bool {
        object(forKey: UserDefaultsKeys.geoScheduleStartTimeKey) != nil
    }
}

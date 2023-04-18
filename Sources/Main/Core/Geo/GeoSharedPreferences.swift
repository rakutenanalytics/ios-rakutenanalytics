import Foundation

/// `GeoSharedPreferences` is the object used to store preferences of Geo persistently.
final class GeoSharedPreferences {
    /// Instance of `UserDefaults`
    private let userStorageHandler: UserStorageHandleable

    init(userStorageHandler: UserStorageHandleable) {
        self.userStorageHandler = userStorageHandler
    }

    /// Method used for setting the status of location collection.
    ///
    /// - parameters:
    ///     - value: Value of type `Bool`.
    func setLocationCollectionStatus(_ value: Bool) {
        userStorageHandler.set(value: value, forKey: UserDefaultsKeys.locationCollectionKey)
    }

    /// Computed-property used for getting the status of location collection.
    var isLocationCollection: Bool {
        userStorageHandler.bool(forKey: UserDefaultsKeys.locationCollectionKey)
    }

    /// Method used for setting the timestamp of last collected location timestamp.
    ///
    /// - parameters:
    ///     - value: Value of type `Date`.
    func setLastCollectedLocationTimeStamp(_ value: Date) {
        userStorageHandler.set(value: value, forKey: UserDefaultsKeys.locationTimestampKey)
    }

    /// Computed-property used for getting the timestamp of last collected location timestamp.
    var getLastCollectedLocationTimeStamp: Date? {
        userStorageHandler.object(forKey: UserDefaultsKeys.locationTimestampKey) as? Date
    }

    /// Use this method to save the configuration into `UserDefaults()`.
    ///
    /// - parameters:
    ///     - value: Value of type `Data`.
    func setGeoConfiguration(_ value: Data) {
        userStorageHandler.set(value: value, forKey: UserDefaultsKeys.configurationKey)
    }

    /// Computed-property used for getting the saved configuration.
    var getGeoConfiguration: Data? {
        userStorageHandler.object(forKey: UserDefaultsKeys.configurationKey) as? Data
    }
}

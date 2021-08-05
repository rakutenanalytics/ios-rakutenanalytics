import Foundation

struct PushEventHandler {
    let userStorageHandler: UserStorageHandleable?

    init(bundle: EnvironmentBundle, userDefaultsType: UserStorageHandleable.Type) {
        guard let appGroupId = bundle.object(forInfoDictionaryKey: RPushAppGroupIdentifierPlistKey) as? String else {
            userStorageHandler = nil
            return
        }
        userStorageHandler = userDefaultsType.init(suiteName: appGroupId)
    }

    func eventHasBeenSent(with trackingIdentifier: String?) -> Bool {
        guard let trackingIdentifier = trackingIdentifier,
              let domain = userStorageHandler?.dictionary(forKey: RPushOpenCountSentUserDefaultKey),
              let result = domain[trackingIdentifier] as? Bool else {
            return false
        }
        return result
    }
}

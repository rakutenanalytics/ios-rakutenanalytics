import Foundation

extension UserDefaults {
    /// Unregisters a value set in the UserDefaults.registrationDomain, if it exists
    public func unregister(defaultsFor key: String) {
        var registeredDefaults = volatileDomain(forName: UserDefaults.registrationDomain)
        registeredDefaults[key] = nil
        setVolatileDomain(registeredDefaults, forName: UserDefaults.registrationDomain)
    }
}

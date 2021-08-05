import Foundation

/// A handler to get the IDFA from AdSupport framework
final class RAdvertisingIdentifierHandler: NSObject {
    private let adIdentifierManager: AdvertisementIdentifiable

    /// Initialize RAdvertisingIdentifierHandler with a dependenciesFactory
    init(dependenciesContainer: SimpleDependenciesContainable) {
        self.adIdentifierManager = dependenciesContainer.adIdentifierManager
    }

    /// Request the advertising identifier.
    /// Returned value is not nil if tracking is authorized.
    /// Note: returns nil on simulator
    var idfa: String? {
        let idfa = advertisingIdentifierUUIDString
        let replacedIdfa = idfa.replacingOccurrences(of: "[0\\-]",
                                                     with: "",
                                                     options: .regularExpression)
        guard !idfa.isEmpty && !replacedIdfa.isEmpty else {
            return nil
        }
        return idfa
    }

    /// Wrapper to get the ADSupport framework `advertisingIdentifier` string.
    /// Use the `idfa` method above unless you need direct access.
    var advertisingIdentifierUUIDString: String {
        adIdentifierManager.advertisingIdentifierUUIDString
    }
}

import Foundation

/// A handler to get the IDFA from AdSupport framework
/// @warning RAdvertisingIdentifierHandler is declared as public to be accessible from Objective-C
/// @warning RAdvertisingIdentifierHandler will have to be private when the callers are migrated to Swift
@objc public final class RAdvertisingIdentifierHandler: NSObject {
    private let adIdentifierManager: AdvertisementIdentifiable

    /// Initialize RAdvertisingIdentifierHandler with a dependenciesFactory
    @objc public init(dependenciesContainer: SimpleDependenciesContainable) {
        self.adIdentifierManager = dependenciesContainer.adIdentifierManager
    }

    /// Request the advertising identifier.
    /// Returned value is not nil if tracking is authorized.
    /// Note: returns nil on simulator
    @objc public var idfa: String? {
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
    @objc public var advertisingIdentifierUUIDString: String {
        adIdentifierManager.advertisingIdentifierUUIDString
    }
}

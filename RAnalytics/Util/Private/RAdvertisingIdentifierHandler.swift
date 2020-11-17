import Foundation
import AdSupport.ASIdentifierManager

/// A handler to get the IDFA from AdSupport framework
/// @warning RAdvertisingIdentifierHandler is declared as public to be accessible from Objective-C
/// @warning RAdvertisingIdentifierHandler will have to be private when the callers are migrated to Swift
@objc public final class RAdvertisingIdentifierHandler: NSObject {
    private let dependenciesContainer: AnyDependenciesContainer

    /// Initialize RAdvertisingIdentifierHandler with a dependenciesContainer that registers an instance implementing AdvertisementIdentifiable protocol
    @objc public init?(dependenciesContainer: AnyDependenciesContainer) {
        guard dependenciesContainer.resolve(AdvertisementIdentifiable.self) != nil else {
            return nil
        }
        self.dependenciesContainer = dependenciesContainer
    }

    /// Request the advertising identifier.
    /// Returned value is not nil if tracking is authorized.
    /// Note: returns nil on simulator
    @objc public var idfa: String? {
        guard let idfa = advertisingIdentifierUUIDString else {
            return nil
        }
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
    @objc public var advertisingIdentifierUUIDString: String? {
        dependenciesContainer.resolve(AdvertisementIdentifiable.self)?.advertisingIdentifierUUIDString
    }
}

@objc protocol AdvertisementIdentifiable: NSObjectProtocol {
    var advertisingIdentifierUUIDString: String { get }
}

@objc extension ASIdentifierManager: AdvertisementIdentifiable {
    public var advertisingIdentifierUUIDString: String {
        advertisingIdentifier.uuidString
    }
}

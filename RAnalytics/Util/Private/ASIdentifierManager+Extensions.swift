import AdSupport.ASIdentifierManager

@objc public protocol AdvertisementIdentifiable {
    var advertisingIdentifierUUIDString: String { get }
}

@objc extension ASIdentifierManager: AdvertisementIdentifiable {
    public var advertisingIdentifierUUIDString: String {
        advertisingIdentifier.uuidString
    }
}

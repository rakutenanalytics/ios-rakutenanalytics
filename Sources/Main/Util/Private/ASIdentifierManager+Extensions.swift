import AdSupport.ASIdentifierManager

protocol AdvertisementIdentifiable {
    var advertisingIdentifierUUIDString: String { get }
}

extension ASIdentifierManager: AdvertisementIdentifiable {
    /// Fix a native iOS crash `UUID.unconditionallyBridgeFromObjectiveC `
    /// https://bugs.swift.org/browse/SR-6143?focusedCommentId=33257&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel
    private var safeAdvertisingIdentifier: UUID? {
        perform(#selector(getter: Self.advertisingIdentifier))?.takeUnretainedValue() as? UUID
    }

    var advertisingIdentifierUUIDString: String {
        safeAdvertisingIdentifier?.uuidString ?? ""
    }
}

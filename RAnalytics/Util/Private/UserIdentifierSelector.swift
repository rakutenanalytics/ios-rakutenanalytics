import Foundation

/// `UserIdentifierSelector` is used to get the correct tracking identifier.
struct UserIdentifierSelector {
    /// The user identifiable.
    private let userIdentifiable: UserIdentifiable

    /// Creates a user identifier selector
    ///
    /// - Parameters:
    ///   - userIdentifiable: The user identifiable.
    ///
    /// - Returns: An instance of UserIdentifierSelector.
    init(userIdentifiable: UserIdentifiable) {
        self.userIdentifiable = userIdentifiable
    }

    /// Returns the selected tracking identifier
    ///
    /// - Returns: A tracking identifier or nil.
    var selectedTrackingIdentifier: String? {
        userIdentifiable.userIdentifier ?? userIdentifiable.trackingIdentifier
    }
}

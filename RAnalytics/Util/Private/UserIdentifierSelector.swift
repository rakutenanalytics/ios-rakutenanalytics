import Foundation

/// This class is used to get the correct tracking identifier.
final class UserIdentifierSelector: NSObject {
    private let trackingIdentifierNoLoginFound = "NO_LOGIN_FOUND"
    private let userIdentifiable: UserIdentifiable

    /// Creates a user identifier selector
    ///
    /// - Parameters:
    ///   - userIdentifiable: The user identifiable.
    ///
    /// - Returns: An instance of UserIdentifierSelector.
    init(userIdentifiable: UserIdentifiable) {
        self.userIdentifiable = userIdentifiable
        super.init()
    }

    /// Returns the selected tracking identifier
    ///
    /// - Returns: A tracking identifier.
    var selectedTrackingIdentifier: String {
        let selectedTrackingIdentifier = userIdentifiable.userIdentifier ?? userIdentifiable.trackingIdentifier
        guard let aTrackingIdentifier = selectedTrackingIdentifier else {
            return trackingIdentifierNoLoginFound
        }
        return aTrackingIdentifier
    }
}

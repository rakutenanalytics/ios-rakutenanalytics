import Foundation

/// `GeoActionParameters` capture a set of optional parameters to be collected as stored properties on requesting location.
///
/// `GeoActionParameters` does not default to any values and are optional. It is upto the app to set them, if necessary.
public struct GeoActionParameters: Hashable {
    /// Specify the type of action performed in requesting location.
    public let actionType: String?
    /// Logs related to the action.
    public let actionLog: String?
    /// Id associated with the action.
    public let actionId: String?
    /// Duration of action.
    public let actionDuration: String?
    /// Additional information related to the action.
    public let additionalLog: String?

    public init(actionType: String? = nil,
                actionLog: String? = nil,
                actionId: String? = nil,
                actionDuration: String? = nil,
                additionalLog: String? = nil) {
        self.actionType = actionType
        self.actionLog = actionLog
        self.actionId = actionId
        self.actionDuration = actionDuration
        self.additionalLog = additionalLog
    }
}

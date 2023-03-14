import Foundation

/// `GeoActionParameters` capture a set of optional parameters to be collected as stored properties on requesting location.
///
/// `GeoActionParameters` does not default to any values and are optional. It is upto the app to set them, if necessary.
public struct GeoActionParameters {
    /// Specify the type of action performed in requesting location.
    let actionType: String?
    /// Logs related to the action.
    let actionLog: String?
    /// Id associated with the action.
    let actionId: String?
    /// Duration of action.
    let actionDuration: String?
    /// Additional information related to the action.
    let additionalLog: String?
}

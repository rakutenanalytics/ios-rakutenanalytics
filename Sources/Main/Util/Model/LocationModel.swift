import Foundation
import CoreLocation

extension CLLocation {
    var safeCourseAccuracy: CLLocationDirectionAccuracy {
        var value: CLLocationDirectionAccuracy = 0.0
        if #available(iOS 13.4, *) {
            value = courseAccuracy
        }
        return value
    }
}

/// `ActionParameters` does not default to any values and are optional. It is upto the app to set them, if necessary.
public struct ActionParameters {
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

/// Location used by the Geo Tracker.
struct LocationModel {
    /// The user location.
    let location: CLLocation

    /// isAction = false → The Location collection in regular interval/distance.
    /// isAction = true → The Location Collection is happening on demand(Application Calls Public Method requestLocation)
    /// Default value: `false`
    let isAction: Bool

    /// Optional ObjectModel which application can send along with requestLocation() method of public API.
    /// - Note: Present only when `isaction` = true.
    let actionParameters: ActionParameters?
}

// MARK: - Serialization

extension LocationModel {
    var toDictionary: [String: Any] {
        [
            PayloadParameterKeys.Location.lat: NSNumber(value: min(90.0, max(-90.0, location.coordinate.latitude))),
            PayloadParameterKeys.Location.long: NSNumber(value: min(180.0, max(-180.0, location.coordinate.longitude))),
            PayloadParameterKeys.Location.accu: NSNumber(value: max(0.0, location.horizontalAccuracy)),
            PayloadParameterKeys.Location.tms: NSNumber(value: location.ratTimestamp),
            PayloadParameterKeys.Location.speed: NSNumber(value: max(0.0, location.speed)),
            PayloadParameterKeys.Location.speedAccuracy: NSNumber(value: max(0.0, location.speedAccuracy)),
            PayloadParameterKeys.Location.altitude: NSNumber(value: location.altitude),
            PayloadParameterKeys.Location.verticalAccuracy: NSNumber(value: max(0.0, location.verticalAccuracy)),
            PayloadParameterKeys.Location.bearing: NSNumber(value: max(0.0, location.course)),
            PayloadParameterKeys.Location.bearingAccuracy: NSNumber(value: max(0.0, location.safeCourseAccuracy))
        ]
    }

    func addAction(to payload: [String: Any]) -> [String: Any] {
        var location = payload

        location[PayloadParameterKeys.Location.isAction] = isAction

        // Add action parameters only when isAction is true and only when parameters are not empty
        if isAction == true,
           let actionParameters = actionParameters {
            var dictionary = [String: Any]()

            if let actionType = actionParameters.actionType, !actionType.isEmpty {
                dictionary[PayloadParameterKeys.Location.ActionParameters.type] = actionType
            }

            if let actionLog = actionParameters.actionLog, !actionLog.isEmpty {
                dictionary[PayloadParameterKeys.Location.ActionParameters.log] = actionLog
            }

            if let actionId = actionParameters.actionId, !actionId.isEmpty {
                dictionary[PayloadParameterKeys.Location.ActionParameters.identifier] = actionId
            }

            if let actionDuration = actionParameters.actionDuration, !actionDuration.isEmpty {
                dictionary[PayloadParameterKeys.Location.ActionParameters.duration] = actionDuration
            }

            if let additionalLog = actionParameters.additionalLog, !additionalLog.isEmpty {
                dictionary[PayloadParameterKeys.Location.ActionParameters.addLog] = additionalLog
            }

            location[PayloadParameterKeys.Location.actionParameters] = dictionary
        }

        return location
    }
}

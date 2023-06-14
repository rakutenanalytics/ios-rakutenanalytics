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

/// Location used by the Geo Tracker.
public struct LocationModel {
    /// Latitude of collected location in degrees
    /// https://developer.apple.com/documentation/corelocation/cllocationcoordinate2d
    public let latitude: CLLocationDegrees

    /// Longitude of collected location in degrees
    /// https://developer.apple.com/documentation/corelocation/cllocationcoordinate2d
    public let longitude: CLLocationDegrees

    /// Horizontal accuracy of this location
    /// https://developer.apple.com/documentation/corelocation/cllocation/1423599-horizontalaccuracy
    public let horizontalAccuracy: CLLocationAccuracy

    /// Speed at the time of this location
    /// https://developer.apple.com/documentation/corelocation/cllocation/1423798-speed
    public let speed: CLLocationSpeed

    /// The accuracy of the speed value, measured in meters per second.
    /// https://developer.apple.com/documentation/corelocation/cllocation/3524340-speedaccuracy
    public let speedAccuracy: CLLocationSpeedAccuracy

    /// Vertical accuracy of this location
    /// https://developer.apple.com/documentation/corelocation/cllocation/1423550-verticalaccuracy
    public let verticalAccuracy: CLLocationAccuracy

    /// The altitude above mean sea level associated with a location, measured in meters
    /// https://developer.apple.com/documentation/corelocation/cllocation/1423820-altitude
    public let altitude: CLLocationDistance

    /// Course at the time of this location Value is between 0.0 and 360.0 inclusive
    /// https://developer.apple.com/documentation/corelocation/cllocation/1423832-course
    public let course: CLLocationDirection

    /// Course accuracy in degrees of this location
    /// https://developer.apple.com/documentation/corelocation/cllocation/3524338-courseaccuracy
    public let courseAccuracy: CLLocationDirectionAccuracy

    /// The time at which this location was determined.
    public let timestamp: Date

    /// isAction = false → The Location collection in regular interval/distance.
    /// isAction = true → The Location Collection is happening on demand(Application Calls Public Method requestLocation)
    /// Default value: `false`
    public let isAction: Bool

    /// Optional ObjectModel which application can send along with requestLocation() method of public API.
    /// - Note: Present only when `isaction` = true.
    public let actionParameters: GeoActionParameters?

    /// Creates a new instance of `LocationModel`.
    /// - Parameter location: the user location.
    /// - Parameter isAction: the action boolean indicating that `actionParameters` can be added or not to the payload.
    /// - Parameter actionParameters: the action parameters.
    public init(location: CLLocation,
                isAction: Bool = false,
                actionParameters: GeoActionParameters? = nil) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        horizontalAccuracy = location.horizontalAccuracy
        speed = location.speed
        speedAccuracy = location.speedAccuracy
        verticalAccuracy = location.verticalAccuracy
        altitude = location.altitude
        course = location.course
        courseAccuracy = location.safeCourseAccuracy
        timestamp = location.timestamp
        self.isAction = isAction
        self.actionParameters = actionParameters
    }
}

// MARK: - Hashable

extension LocationModel: Hashable {
    public static func == (lhs: LocationModel, rhs: LocationModel) -> Bool {
        lhs.latitude == rhs.latitude
        && lhs.longitude == rhs.longitude
        && lhs.horizontalAccuracy == rhs.horizontalAccuracy
        && lhs.speed == rhs.speed
        && lhs.speedAccuracy == rhs.speedAccuracy
        && lhs.verticalAccuracy == rhs.verticalAccuracy
        && lhs.altitude == rhs.altitude
        && lhs.course == rhs.course
        && lhs.courseAccuracy == rhs.courseAccuracy
        && lhs.timestamp == rhs.timestamp
        && lhs.isAction == rhs.isAction
        && lhs.actionParameters == rhs.actionParameters
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
        hasher.combine(horizontalAccuracy)
        hasher.combine(speed)
        hasher.combine(speedAccuracy)
        hasher.combine(verticalAccuracy)
        hasher.combine(altitude)
        hasher.combine(course)
        hasher.combine(courseAccuracy)
        hasher.combine(timestamp)
        hasher.combine(isAction)
        hasher.combine(actionParameters)
    }
}

// MARK: - Serialization

extension LocationModel {
    /// Convert LocationModel to a RAT location payload.
    ///
    /// - Spec: https://confluence.rakuten-it.com/confluence/display/RAT/analytics+sdk%3A+Implement+GeoTracker
    var toDictionary: [String: Any] {
        var payload = [String: Any]()
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        if horizontalAccuracy >= 0
            && CLLocationCoordinate2DIsValid(coordinate) {
            payload[PayloadParameterKeys.Location.accu] = NSNumber(value: horizontalAccuracy)
            payload[PayloadParameterKeys.Location.lat] = NSNumber(value: min(90.0, max(-90.0, latitude)))
            payload[PayloadParameterKeys.Location.long] = NSNumber(value: min(180.0, max(-180.0, longitude)))
        }

        payload[PayloadParameterKeys.Location.tms] = NSNumber(value: timestamp.toRatTimestamp)

        if speedAccuracy >= 0 && speed >= 0 {
            payload[PayloadParameterKeys.Location.speedAccuracy] = NSNumber(value: speedAccuracy)
            payload[PayloadParameterKeys.Location.speed] = NSNumber(value: speed)
        }

        if verticalAccuracy > 0 {
            payload[PayloadParameterKeys.Location.verticalAccuracy] = NSNumber(value: verticalAccuracy)
            payload[PayloadParameterKeys.Location.altitude] = NSNumber(value: altitude)
        }

        if courseAccuracy >= 0 && course >= 0 {
            payload[PayloadParameterKeys.Location.bearingAccuracy] = NSNumber(value: courseAccuracy)
            payload[PayloadParameterKeys.Location.bearing] = NSNumber(value: course)
        }

        return payload
    }

    func requestLocationActionParameters() -> [String: Any] {
        var locationActionParameters = [String: Any]()

        // Add action parameters only when isAction is true and only when parameters are not empty
        if isAction,
           let actionParameters = actionParameters {

            if let actionType = actionParameters.actionType, !actionType.isEmpty {
                locationActionParameters[PayloadParameterKeys.ActionParameters.type] = actionType
            }

            if let actionLog = actionParameters.actionLog, !actionLog.isEmpty {
                locationActionParameters[PayloadParameterKeys.ActionParameters.log] = actionLog
            }

            if let actionId = actionParameters.actionId, !actionId.isEmpty {
                locationActionParameters[PayloadParameterKeys.ActionParameters.identifier] = actionId
            }

            if let actionDuration = actionParameters.actionDuration, !actionDuration.isEmpty {
                locationActionParameters[PayloadParameterKeys.ActionParameters.duration] = actionDuration
            }

            if let additionalLog = actionParameters.additionalLog, !additionalLog.isEmpty {
                locationActionParameters[PayloadParameterKeys.ActionParameters.addLog] = additionalLog
            }
        }

        return locationActionParameters
    }
}

extension Optional where Wrapped == LocationModel {
    /// Retrieve the hash value of a `LocationModel`.
    ///
    /// - Returns: The hash value or `0`.
    var safeHashValue: Int {
        guard let str = self else { return 0 }
        return str.hashValue
    }
}

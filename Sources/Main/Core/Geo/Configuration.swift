import Foundation

/// The default location collection configuration constants.
public enum ConfigurationConstants {
    public static let distanceInterval: UInt = 300
    public static let timeInterval: UInt = 300
    public static let accuracy: GeoAccuracy = .best
    public static let startTime: GeoTime = GeoTime(hours: 0, minutes: 0)
    public static let endTime: GeoTime = GeoTime(hours: 23, minutes: 59)
}

/// Configures the location collection.
public struct Configuration: Equatable {
    /// The distance interval (meters)
    var distanceInterval: UInt?

    /// The time interval (seconds)
    var timeInterval: UInt?

    let accuracy: GeoAccuracy?

    /// The local time to start location collection
    var startTime: GeoTime?

    /// The local time to end location collection
    var endTime: GeoTime?
    
    public init(distanceInterval: UInt? = ConfigurationConstants.distanceInterval,
                timeInterval: UInt? = ConfigurationConstants.timeInterval,
                accuracy: GeoAccuracy? = .best,
                startTime: GeoTime? = ConfigurationConstants.startTime,
                endTime: GeoTime? = ConfigurationConstants.endTime) {
        self.distanceInterval = distanceInterval
        self.timeInterval = timeInterval
        self.accuracy = accuracy
        self.startTime = startTime
        self.endTime = endTime
    }
}

extension Configuration: Codable {
    enum CodingKeys: String, CodingKey {
        case distanceInterval = "GeoDistanceInterval"
        case timeInterval = "GeoTimeInterval"
        case accuracy = "GeoAccuracy"
        case startTime = "GeoStartTime"
        case endTime = "GeoEndTime"
    }
}

/// The time used to collect the location.
public struct GeoTime: Equatable {
    let hours: UInt
    let minutes: UInt
    
    public init(hours: UInt, minutes: UInt) {
        self.hours = hours
        self.minutes = minutes
    }
}

extension GeoTime: Codable {
    private enum CodingKeys: String, CodingKey {
        case hours
        case minutes
    }
}

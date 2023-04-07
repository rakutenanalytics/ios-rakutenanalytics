import Foundation

/// `GeoConfigurationConstants` consists default configuration properties used in location collection.
public enum GeoConfigurationConstants {
    public static let distanceInterval: UInt = 300
    public static let timeInterval: UInt = 300
    public static let accuracy: GeoAccuracy = .best
    public static let startTime: GeoTime = GeoTime(hours: 0, minutes: 0)
    public static let endTime: GeoTime = GeoTime(hours: 23, minutes: 59)
}

/// Configures the location collection.
public struct GeoConfiguration: Codable, Equatable {
    /// The distance interval for location collection in meters.
    public var distanceInterval: UInt

    /// Time frequency of location collection in seconds.
    public var timeInterval: UInt

    /// Accuracy of the location data in collection.
    public var accuracy: GeoAccuracy

    /// Time to start location collection.
    public var startTime: GeoTime

    /// Time to end location collection.
    public var endTime: GeoTime
    
    public init(distanceInterval: UInt = GeoConfigurationConstants.distanceInterval,
                timeInterval: UInt = GeoConfigurationConstants.timeInterval,
                accuracy: GeoAccuracy = GeoConfigurationConstants.accuracy,
                startTime: GeoTime = GeoConfigurationConstants.startTime,
                endTime: GeoTime = GeoConfigurationConstants.endTime) {
        self.distanceInterval = distanceInterval
        self.timeInterval = timeInterval
        self.accuracy = accuracy
        self.startTime = startTime
        self.endTime = endTime
    }
}

/// `GeoTime` defines the time interval for location collection.
public struct GeoTime: Codable, Equatable {
    public let hours: UInt
    public let minutes: UInt
    
    public init(hours: UInt, minutes: UInt) {
        self.hours = hours
        self.minutes = minutes
    }
}

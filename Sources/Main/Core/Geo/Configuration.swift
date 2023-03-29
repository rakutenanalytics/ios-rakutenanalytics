import Foundation
import CoreLocation

/// The time used to collect the location.
public struct GeoTime: Equatable {
    let hour: UInt
    let minute: UInt
}

/// Configures the location collection.
public struct Configuration: Equatable {
    /// The distance interval (meters)
    let distanceInterval: UInt?

    /// The time interval (seconds)
    let timeInterval: UInt?

    let accuracy: GeoAccuracy?

    /// The local time to start location collection
    let startTime: GeoTime?

    /// The local time to end location collection
    let endTime: GeoTime?
}

/// The default location collection configuration constants.
private enum ConfigurationConstants {
    static let distanceInterval: UInt = 300
    static let timeInterval: UInt = 300
    static let accuracy: GeoAccuracy = .best
    static let startTime: GeoTime = GeoTime(hour: 0, minute: 0)
    static let endTime: GeoTime = GeoTime(hour: 23, minute: 59)
}

enum ConfigurationFactory {
    /// - Returns: the default location collection configuration.
    static var defaultConfiguration: Configuration {
        Configuration(distanceInterval: ConfigurationConstants.distanceInterval,
                      timeInterval: ConfigurationConstants.timeInterval,
                      accuracy: ConfigurationConstants.accuracy,
                      startTime: ConfigurationConstants.startTime,
                      endTime: ConfigurationConstants.endTime)
    }
}

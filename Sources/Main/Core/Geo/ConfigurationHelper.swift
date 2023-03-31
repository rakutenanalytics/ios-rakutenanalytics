import Foundation

enum ConfigurationFactory {
    /// - Returns: the default location collection configuration.
    static var defaultConfiguration: Configuration {
        Configuration(distanceInterval: ConfigurationConstants.distanceInterval,
                      timeInterval: ConfigurationConstants.timeInterval,
                      accuracy: ConfigurationConstants.accuracy,
                      startTime: ConfigurationConstants.startTime,
                      endTime: ConfigurationConstants.endTime)
    }
    
    static var hoursRange: ClosedRange<UInt> = 0...23
    static var minutesRange: ClosedRange<UInt> = 0...59
    static var distanceIntervalRange: ClosedRange<UInt> = 200...500
    static var timeIntervalRange: ClosedRange<UInt> = 60...1800
    static var minutesOutOfRange: ClosedRange<UInt> = 60...UInt.max
}

protocol GeoConfigurationStorage {
    func storeGeoConfiguration(configuration: Configuration) -> Bool
    func retrieveGeoConfigurationFromStorage() -> Configuration?
}

struct GeoConfigurationHelper: GeoConfigurationStorage {
    enum Constants {
        static let GeoConfigurationKey = "GeoConfiguration"
    }
    
    @discardableResult
    func storeGeoConfiguration(configuration: Configuration) -> Bool {
        
        var geoConfiguration = configuration
        // Range check for startTime
        if let startTime = geoConfiguration.startTime {
            switch startTime.hours {
            case ConfigurationFactory.hoursRange:
                if ConfigurationFactory.minutesOutOfRange ~= startTime.minutes {
                    geoConfiguration.startTime = GeoTime(hours: startTime.hours, minutes: ConfigurationConstants.startTime.minutes)
                }
            default:
                geoConfiguration.startTime = ConfigurationConstants.startTime
            }
        }
        
        // Range check for endTime
        if let endTime = geoConfiguration.endTime {
            switch endTime.hours {
            case ConfigurationFactory.hoursRange:
                if ConfigurationFactory.minutesOutOfRange ~= endTime.minutes {
                    geoConfiguration.endTime = GeoTime(hours: endTime.hours, minutes: ConfigurationConstants.endTime.minutes)
                }
            default:
                geoConfiguration.endTime = ConfigurationConstants.endTime
            }
        }
        
        // RangeCheck for distanceInterval
        if let distanceInterval = geoConfiguration.distanceInterval {
            switch distanceInterval {
            case ConfigurationFactory.distanceIntervalRange: break
            default:
                geoConfiguration.distanceInterval = ConfigurationConstants.distanceInterval
            }
        }
        
        // RangeCheck for timeInterval
        if let timeInterval = geoConfiguration.timeInterval {
            switch timeInterval {
            case ConfigurationFactory.timeIntervalRange: break
            default:
                geoConfiguration.timeInterval = ConfigurationConstants.timeInterval
            }
        }
        
        do {
            let geoConfigurationData = try JSONEncoder().encode(geoConfiguration)
            UserDefaults.standard.set(value: geoConfigurationData, forKey: Constants.GeoConfigurationKey)
            RLogger.debug(message: "Configuration stored into shared preference")
            return true
        } catch {
            RLogger.debug(message: "\(error.localizedDescription)")
        }
        return false
    }
    
    // Retrieve configuration from storage if present, else return nil
    func retrieveGeoConfigurationFromStorage() -> Configuration? {
        
        do {
            if let configurationData = UserDefaults.standard.data(forKey: Constants.GeoConfigurationKey) {
                let configuration = try JSONDecoder().decode(Configuration.self, from: configurationData)
                RLogger.debug(message: "Configuration retrieved from shared preference")
                return configuration
            }
        } catch {
            RLogger.debug(message: "\(error.localizedDescription)")
        }
        RLogger.debug(message: "No Configuration to retrieve from shared preference")
        return nil
    }
}

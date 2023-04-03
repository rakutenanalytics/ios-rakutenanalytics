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
    static var distanceIntervalRange: ClosedRange<UInt> = 200...500
    static var timeIntervalRange: ClosedRange<UInt> = 60...1800
    static var startHours: UInt = 0
    static var startMinutes: UInt = 0
    static var endHours: UInt = 23
    static var endMinutes: UInt = 59
}

protocol GeoConfigurationStorage {
    func store(configuration: Configuration) -> Bool
    func retrieveGeoConfigurationFromStorage() -> Configuration?
}

struct GeoConfigurationHelper: GeoConfigurationStorage {
    
    // The user storage handler
    private let userStorageHandler: UserStorageHandleable?
    
    private enum Constants {
        static let GeoConfigurationKey = "GeoConfiguration"
    }
    init(userStorageHandler: UserStorageHandleable) {
        self.userStorageHandler = userStorageHandler
    }
    
    @discardableResult
    func store(configuration: Configuration) -> Bool {
        
        var geoConfiguration = configuration
        // Range check for startTime and endTime
        let validTime = validateTime(startTime: geoConfiguration.startTime ?? ConfigurationConstants.startTime,
                                     endTime: geoConfiguration.endTime ?? ConfigurationConstants.endTime)
        
        geoConfiguration.startTime = validTime.startTime
        geoConfiguration.endTime = validTime.endTime
        
        // RangeCheck for distanceInterval
        if let distanceInterval = geoConfiguration.distanceInterval {
            switch distanceInterval {
            case ConfigurationFactory.distanceIntervalRange: ()
            default:
                geoConfiguration.distanceInterval = ConfigurationConstants.distanceInterval
            }
        }
        
        // RangeCheck for timeInterval
        if let timeInterval = geoConfiguration.timeInterval {
            switch timeInterval {
            case ConfigurationFactory.timeIntervalRange: ()
            default:
                geoConfiguration.timeInterval = ConfigurationConstants.timeInterval
            }
        }
        
        do {
            let geoConfigurationData = try JSONEncoder().encode(geoConfiguration)
            userStorageHandler?.set(value: geoConfigurationData, forKey: Constants.GeoConfigurationKey)
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
            if let configurationData = userStorageHandler?.data(forKey: Constants.GeoConfigurationKey) {
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
    
    func validateTime(startTime: GeoTime, endTime: GeoTime) -> (startTime: GeoTime, endTime: GeoTime) {
        
        // Check startTime range
        var startHours = startTime.hours
        var startMinutes = startTime.minutes
        if startHours > ConfigurationFactory.endHours || startMinutes > ConfigurationFactory.endMinutes {
            startHours = ConfigurationFactory.startHours
            startMinutes = ConfigurationFactory.startMinutes
        } else if startHours <= 23 && startMinutes > 59 {
            startMinutes = 0
        }
        
        // Check endTime range
        var endHours = endTime.hours
        var endMinutes = endTime.minutes
        if endHours > ConfigurationFactory.endHours || endMinutes > ConfigurationFactory.endMinutes {
            endHours = ConfigurationFactory.endHours
            endMinutes = ConfigurationFactory.endMinutes
        } else if endHours <= ConfigurationFactory.endHours && endMinutes > ConfigurationFactory.endMinutes {
            endMinutes = ConfigurationFactory.endMinutes
        }
        
        // Check additional conditions if endTime > startTime then store the default time of start and end
        if endHours < startHours || (endHours == startHours && endMinutes <= startMinutes) {
            startHours = ConfigurationFactory.startHours
            startMinutes = ConfigurationFactory.startMinutes
            endHours = ConfigurationFactory.endHours
            endMinutes = ConfigurationFactory.endMinutes
            // Print the debug warning
            RLogger.warning(message: "Configuration startTime > endTime, defaulting the startTime(00:00) and endTime(23:59)")
        }
        return (GeoTime(hours: startHours, minutes: startMinutes), GeoTime(hours: endHours, minutes: endMinutes))
    }
}

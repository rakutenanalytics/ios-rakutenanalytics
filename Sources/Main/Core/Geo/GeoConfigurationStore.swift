import Foundation

enum GeoConfigurationFactory {
    /// - Returns: the default location collection configuration.
    static var defaultConfiguration: GeoConfiguration {
        GeoConfiguration(distanceInterval: GeoConfigurationConstants.distanceInterval,
                         timeInterval: GeoConfigurationConstants.timeInterval,
                         accuracy: GeoConfigurationConstants.accuracy,
                         startTime: GeoConfigurationConstants.startTime,
                         endTime: GeoConfigurationConstants.endTime)
    }
    static var distanceIntervalRange: ClosedRange<UInt> = 200...500
    static var timeIntervalRange: ClosedRange<UInt> = 60...1800
    static var startHours: UInt = 0
    static var startMinutes: UInt = 0
    static var endHours: UInt = 23
    static var endMinutes: UInt = 59
}

protocol GeoConfigurationStorable {
    var configuration: GeoConfiguration { get }
    @discardableResult func store(configuration: GeoConfiguration) -> Bool
    func retrieveGeoConfigurationFromStorage() -> GeoConfiguration?
    func purgeConfiguration()
}

struct GeoConfigurationStore: GeoConfigurationStorable {

    private let userStorageHandler: UserStorageHandleable

    var configuration: GeoConfiguration {
        retrieveGeoConfigurationFromStorage() ?? GeoConfigurationFactory.defaultConfiguration
    }

    init(userStorageHandler: UserStorageHandleable) {
        self.userStorageHandler = userStorageHandler
    }
    
    @discardableResult
    func store(configuration: GeoConfiguration) -> Bool {
        
        var geoConfiguration = configuration
        // Range check for startTime and endTime
        let validTime = validateTime(startTime: geoConfiguration.startTime,
                                     endTime: geoConfiguration.endTime)
        
        geoConfiguration.startTime = validTime.startTime
        geoConfiguration.endTime = validTime.endTime
        
        // RangeCheck for distanceInterval
        if case (GeoConfigurationFactory.distanceIntervalRange) = geoConfiguration.distanceInterval {
            RLogger.debug(message: "distanceInterval is within range")
        } else {
            geoConfiguration.distanceInterval = GeoConfigurationFactory.defaultConfiguration.distanceInterval
        }
        
        // RangeCheck for timeInterval
        if case (GeoConfigurationFactory.timeIntervalRange) = geoConfiguration.timeInterval {
            RLogger.debug(message: "timeInterval is within range")
        } else {
            geoConfiguration.timeInterval = GeoConfigurationFactory.defaultConfiguration.timeInterval
        }
        
        do {
            let data = try JSONEncoder().encode(geoConfiguration)
            userStorageHandler.set(value: data, forKey: UserDefaultsKeys.configurationKey)
            RLogger.debug(message: "GeoConfiguration stored into shared preference")
            return true
        } catch {
            RLogger.debug(message: "\(error.localizedDescription)")
        }
        return false
    }
    
    // Retrieve configuration from storage if present, else return nil
    func retrieveGeoConfigurationFromStorage() -> GeoConfiguration? {
        do {
            if let data = userStorageHandler.data(forKey: UserDefaultsKeys.configurationKey) {
                let configuration = try JSONDecoder().decode(GeoConfiguration.self, from: data)
                RLogger.debug(message: "GeoConfiguration retrieved from shared preference")
                return configuration
            }
        } catch {
            RLogger.debug(message: "\(error.localizedDescription)")
        }
        RLogger.debug(message: "No GeoConfiguration to retrieve from shared preference")
        return nil
    }

    func purgeConfiguration() {
        userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
    }

    func validateTime(startTime: GeoTime, endTime: GeoTime) -> (startTime: GeoTime, endTime: GeoTime) {
        
        // Check startTime range
        var startHours = startTime.hours
        var startMinutes = startTime.minutes
        if startHours > GeoConfigurationFactory.endHours {
            startHours = GeoConfigurationFactory.startHours
            startMinutes = GeoConfigurationFactory.startMinutes
        } else if startHours <= GeoConfigurationFactory.endHours &&
                    startMinutes > GeoConfigurationFactory.endMinutes {
            startMinutes = GeoConfigurationFactory.startMinutes
        }
        
        // Check endTime range
        var endHours = endTime.hours
        var endMinutes = endTime.minutes
        if endHours > GeoConfigurationFactory.endHours {
            endHours = GeoConfigurationFactory.endHours
            endMinutes = GeoConfigurationFactory.endMinutes
        } else if endHours <= GeoConfigurationFactory.endHours &&
                    endMinutes > GeoConfigurationFactory.endMinutes {
            endMinutes = GeoConfigurationFactory.endMinutes
        }
        
        // Check additional conditions if startTime > endTime then store the default time of startTime and endTime
        if endHours < startHours || (endHours == startHours && endMinutes <= startMinutes) {
            startHours = GeoConfigurationFactory.startHours
            startMinutes = GeoConfigurationFactory.startMinutes
            endHours = GeoConfigurationFactory.endHours
            endMinutes = GeoConfigurationFactory.endMinutes
            // Print the debug warning
            RLogger.warning(message: "GeoConfiguration startTime > endTime, defaulting to startTime(00:00) and endTime(23:59)")
        }
        return (GeoTime(hours: startHours, minutes: startMinutes), GeoTime(hours: endHours, minutes: endMinutes))
    }
}

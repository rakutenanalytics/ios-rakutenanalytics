import Foundation

enum GeoTrackerConstants {
    static let tableName = "RAKUTEN_ANALYTICS_GEO_TABLE"
    static let databaseName = "RAnalyticsGeoTracker.db"
}

/// The GeoTracker is responsible for processing Location events received from GeoManager.
///
/// - Note: `NSObject` inheritance is needed in order to conform to `Tracker` protocol.
///
/// - Links:
/// https://jira.rakuten-it.com/jira/browse/CONRAT-28248
/// https://confluence.rakuten-it.com/confluence/display/RAT/analytics+sdk%3A+Implement+GeoTracker
final class GeoTracker: NSObject {
    /// The Sender used to send requests to RAT
    private var sender: RAnalyticsSender

    /// The RAT Automatic Fields Setter
    private let automaticFieldsBuilder: AutomaticFieldsBuildable

    /// The RAT endpoint URL
    var endpointURL: URL? {
        get {
            sender.endpointURL
        }
        set {
            sender.endpointURL = newValue
        }
    }

    /// Creates a new instance of `GeoTracker`.
    ///
    /// - Parameter dependenciesContainer: The dependencies container.
    /// - Parameter batchingDelay: The batching delay - default value: 15 minutes.
    /// - Parameter databaseConfiguration: The database configuration.
    ///
    /// - Returns: a new instance of `GeoTracker` or nil if the enpoint is nil.
    ///
    /// - Example of instanciation:
    /// ```
    /// guard let databaseConfiguration = DatabaseConfigurationHandler.create(databaseName: GeoTrackerConstants.databaseName,
    ///                                                                       tableName: GeoTrackerConstants.tableName,
    ///                                                                       databaseParentDirectory: Bundle.main.databaseParentDirectory) else {
    ///     return
    /// }
    ///
    /// let geoTracker = GeoTracker(dependenciesContainer: SimpleDependenciesContainer(),
    ///                             databaseConfiguration: databaseConfiguration)
    ///  ```
    init?(dependenciesContainer: GeoDependenciesContainable,
          batchingDelay: TimeInterval = RAnalyticsRATTracker.Constants.ratBatchingDelay,
          databaseConfiguration: DatabaseConfigurable) {
        guard let endpointURL = dependenciesContainer.bundle.endpointAddress else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.geoTrackerErrorDomain,
                                             code: ErrorCode.geoTrackerCreationFailed.rawValue,
                                             description: ErrorDescription.eventsNotProcessedByGeoTracker,
                                             reason: ErrorReason.endpointMissing))
            return nil
        }

        self.automaticFieldsBuilder = dependenciesContainer.automaticFieldsBuilder

        // maxUploadInterval equals to batchingDelay in order to send events every 900 seconds
        sender = RAnalyticsSender(endpoint: endpointURL,
                                  database: databaseConfiguration.database,
                                  databaseTable: databaseConfiguration.tableName,
                                  bundle: dependenciesContainer.bundle,
                                  session: dependenciesContainer.session,
                                  maxUploadInterval: batchingDelay,
                                  userStorageHandler: dependenciesContainer.userStorageHandler)
        sender.setBatchingDelayBlock(batchingDelay)
        sender.backgroundTimerEnabler = .enabled(startTimeKey: UserDefaultsKeys.geoScheduleStartTimeKey)

        super.init()

        self.endpointURL = endpointURL
    }
}

// MARK: - Tracker

extension GeoTracker: Tracker {
    /// Process an event and send it to the RAT Backend.
    ///
    /// - Parameters:
    ///    - event: the event to process
    ///    - state: the state associated to the event
    ///
    /// - Returns:
    ///    - `false` when event name is not `loc`
    ///    - `true` otherwise
    @discardableResult
    func process(event: RAnalyticsEvent, state: RAnalyticsState) -> Bool {
        let eventName = event.name

        // GeoTracker will only react to loc event.
        guard eventName == RAnalyticsEvent.Name.geoLocation else {
            RLogger.error(message: "GeoTracker can only send loc event.")
            return false
        }

        let payload = NSMutableDictionary()

        payload[PayloadParameterKeys.etype] = event.name

        automaticFieldsBuilder.addCommonParameters(payload, state: state)
        automaticFieldsBuilder.addLocation(payload,
                                           state: state,
                                           addActionParameters: true)

        sender.send(jsonObject: payload)

        return true
    }
}

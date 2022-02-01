import Foundation
#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsMain
#endif

enum SDKTrackerConstants {
    static let tableName = "RAKUTEN_ANALYTICS_SDK_TABLE"
    static let databaseName = "RAnalyticsSDKTracker.db"
}

final class SDKTracker: NSObject, Tracker {
    private var sender: RAnalyticsSender

    var endpointURL: URL? {
        get {
            sender.endpointURL
        }
        set {
            sender.endpointURL = newValue
        }
    }

    init?(bundle: EnvironmentBundle,
          session: SwiftySessionable,
          batchingDelay: TimeInterval = 60.0,
          databaseConfiguration: DatabaseConfigurable) {
        guard let endpointURL = bundle.endpointAddress else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.sdkTrackerErrorDomain,
                                             code: ErrorCode.sdkTrackerCreationFailed.rawValue,
                                             description: ErrorDescription.eventsNotProcessedBySDKTracker,
                                             reason: ErrorReason.endpointMissing))
            return nil
        }

        sender = RAnalyticsSender(endpoint: endpointURL,
                                  database: databaseConfiguration.database,
                                  databaseTable: databaseConfiguration.tableName,
                                  bundle: bundle,
                                  session: session)
        sender.setBatchingDelayBlock(batchingDelay) // default is 1 minute.

        super.init()

        self.endpointURL = endpointURL
    }

    func process(event: RAnalyticsEvent, state: RAnalyticsState) -> Bool {
        let eventName = event.name

        // SDKTracker will only react to rem_install event.
        if eventName != RAnalyticsEvent.Name.install {
            return false
        }

        sender.send(jsonObject: payload(for: event, state: state))

        return true
    }
}

// MARK: - Utils

private extension SDKTracker {
    func payload(for event: RAnalyticsEvent, state: RAnalyticsState) -> [String: Any] {
        let eventName = event.name

        var payload: [String: Any] = [:]
        var extra: [String: Any] = event.installParameters

        payload[PayloadParameterKeys.acc] = 477
        payload[PayloadParameterKeys.aid] = 1

        let substring = eventName["_rem".count..<eventName.count]
        let etype = "_rem_internal\(substring)"
        payload[PayloadParameterKeys.etype] = etype

        // If the event already had a 'cp' field, those values take precedence
        if let cpDictionary = payload[PayloadParameterKeys.cp] as? [String: Any] {
            extra += cpDictionary
        }

        payload[PayloadParameterKeys.cp] = extra

        payload[RAnalyticsConstants.sdkDependenciesKey] = CoreHelpers.sdkDependencies

        payload += CoreHelpers.sharedPayload(for: state)

        return payload
    }
}

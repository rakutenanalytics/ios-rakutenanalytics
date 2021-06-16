import Foundation

@objc final class SDKTracker: NSObject, Tracker {
    private static let SDKTableName = "RAKUTEN_ANALYTICS_SDK_TABLE"
    private static let SDKDatabaseName = "RAnalyticsSDKTracker.db"
    private var sender: RAnalyticsSender

    var endpointURL: URL {
        get {
            sender.endpointURL
        }
        set {
            sender.endpointURL = newValue
        }
    }

    init?(bundle: EnvironmentBundle, session: SwiftySessionable, batchingDelay: TimeInterval = 60.0) {
        guard let endpointURL = bundle.endpointAddress,
              let connection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: SDKTracker.SDKDatabaseName) else {
            return nil
        }
        let database = RAnalyticsDatabase.database(connection: connection)
        guard let aSender = RAnalyticsSender(endpoint: endpointURL,
                                             database: database,
                                             databaseTable: SDKTracker.SDKTableName,
                                             bundle: Bundle.main,
                                             session: session) else {
            return nil
        }
        sender = aSender
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

        var payload: [String: Any] = [:]
        var extra: [String: Any] = [:]

        payload["acc"] = 477
        payload["aid"] = 1

        let substring = eventName["_rem".count..<eventName.count]
        let etype = "_rem_internal\(substring)"
        payload["etype"] = etype

        let appAndSDKDict = CoreHelpers.applicationInfo

        if let sdkInfo = appAndSDKDict?[RAnalyticsConstants.RAnalyticsSDKInfoKey] as? [String: Any],
           !sdkInfo.isEmpty,
           let data = try? JSONSerialization.data(withJSONObject: sdkInfo, options: .prettyPrinted) {
            extra["sdk_info"] = String(data: data, encoding: .utf8)
        }

        if let appInfo = appAndSDKDict?[RAnalyticsConstants.RAnalyticsAppInfoKey] as? [String: Any],
           !appInfo.isEmpty,
           let data = try? JSONSerialization.data(withJSONObject: appInfo, options: .prettyPrinted) {
            extra["app_info"] = String(data: data, encoding: .utf8)
        }

        // If the event already had a 'cp' field, those values take precedence
        if let cpDictionary = payload["cp"] as? [String: Any] {
            extra += cpDictionary
        }

        payload["cp"] = extra

        payload += CoreHelpers.sharedPayload(for: state)

        sender.send(jsonObject: payload)

        return true
    }
}

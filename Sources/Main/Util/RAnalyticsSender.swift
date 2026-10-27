import Foundation
import UIKit

private enum SenderConstants {
    static let tableBlobLimit = UInt(5000)
    static let ratBatchSize = UInt(16)
    static let defaultUploadInterval = TimeInterval(0.0)
    static let minUploadInterval = TimeInterval(0.0)
    static let retryInterval = TimeInterval(10.0)
}

@objc public protocol AnalyticsSendable: NSObjectProtocol {
    var endpointURL: URL? { get set }
    func setBatchingDelayBlock(_ batchingDelayBlock: @escaping @autoclosure BatchingDelayBlock)
    func batchingDelayBlock() -> BatchingDelayBlock?
    @objc(sendJSONObject:) func send(jsonObject: Any)
}

enum SenderBackgroundTimerEnabler {
    case none
    case enabled(startTimeKey: String)
}

@objc public final class RAnalyticsSender: NSObject, EndpointSettable, AnalyticsSendable {
    @objc public var endpointURL: URL? {
        get {
            self.safeEndpointURL
        }
        set {
            self.safeEndpointURL = newValue
        }
    }

    /// Enables the background timer update.
    var backgroundTimerEnabler: SenderBackgroundTimerEnabler = .none

    private let userStorageHandler: UserStorageHandleable

    /// Closure that returns whether persisting and uploading analytics events is currently allowed.
    private let allowsAnalyticsSend: () -> Bool

    private var scheduleStartDate: Date?

    @AtomicGetSet private var safeEndpointURL: URL?
    /// Enable the experimental internal JSON serialization or not.
    /// The experimental internal JSON serialization fixes the float numbers decimals.
    private let enableInternalSerialization: Bool

    private let database: RAnalyticsDatabase
    private let databaseTableName: String
    private let session: SwiftySessionable

    /// The maximum upload time interval
    private let maxUploadInterval: TimeInterval

    @objc public private(set) var uploadTimerInterval = SenderConstants.defaultUploadInterval

    private var batchingDelayClosure: BatchingDelayBlock?
    private let batchingDelayQueue = DispatchQueue(label: "com.analytics.batchingDelayQueue")
    private let scheduleCoordinator: SenderScheduleCoordinator

    /// Whether batching/retry scheduling is idle. Test infrastructure uses this seam after uploads.
    var isUploadSchedulingIdle: Bool {
        scheduleCoordinator.isSchedulingIdle
    }

    /// Initialize Sender
    /// - Parameters:
    ///   - endpoint: endpoint URL
    ///   - database: database to read/write
    ///   - databaseTable: name of database
    ///   - bundle: the bundle
    ///   - session: the URL session
    ///   - maxUploadInterval: the maximum time interval. The default value is 60 seconds.
    ///   - userStorageHandler: the user storage handler.
    ///   - allowsAnalyticsSend: Whether persisting and uploading analytics events is allowed; inject for tests or custom policy.
    ///
    ///   - Note: if the batching delay is greater than `maxUploadInterval`, then `maxUploadInterval` is taken as the default batching delay.
    init(endpoint: URL,
         database: RAnalyticsDatabase,
         databaseTable: String,
         bundle: EnvironmentBundle,
         session: SwiftySessionable,
         maxUploadInterval: TimeInterval = TimeInterval(60.0),
         userStorageHandler: UserStorageHandleable,
         allowsAnalyticsSend: @escaping () -> Bool) {
        self.safeEndpointURL = endpoint
        self.database = database
        self.databaseTableName = databaseTable
        self.batchingDelayClosure = { return SenderConstants.defaultUploadInterval }
        self.enableInternalSerialization = bundle.enableInternalSerialization
        self.session = session
        self.maxUploadInterval = maxUploadInterval
        self.userStorageHandler = userStorageHandler
        self.allowsAnalyticsSend = allowsAnalyticsSend
        let scheduleTaskHandles = SenderScheduleTaskHandles()
        let scheduleIdleMirror = UploadSchedulingIdleMirror()
        self.scheduleCoordinator = SenderScheduleCoordinator(
            taskHandles: scheduleTaskHandles,
            idleMirror: scheduleIdleMirror
        )
        super.init()

        configureNotifications()
    }

    deinit {
        scheduleCoordinator.cancelAllWork()
    }

    /// Store event data in database to be sent later
    /// - Parameter jsonObject: json object
    @objc(sendJSONObject:)
    public func send(jsonObject: Any) {
        guard allowsAnalyticsSend() else {
            RLogger.error(message: "Analytics event dropped because manual initialization is enabled and the analytics SDK is not configured.")
            return
        }

        guard let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
              let payloadString = String(data: data, encoding: .utf8) else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.senderErrorDomain,
                                             code: ErrorCode.senderSendEventsHasFailed.rawValue,
                                             description: ErrorDescription.senderSendEventsHasFailed,
                                             reason: ErrorReason.senderSerializationFailure))
            return
        }

        #if DEBUG
        RLogger.verbose(message: "Storing event with the following payload: \(payloadString)")
        #endif

        insert(dataBlob: data)
    }

    /// Set the batching delay
    /// - Parameter batchingDelayBlock: batching delay block
    @objc public func setBatchingDelayBlock(_ batchingDelayBlock: @escaping @autoclosure BatchingDelayBlock) {
        batchingDelayQueue.async {
            self.batchingDelayClosure = batchingDelayBlock
        }
    }

    /// Batching delay
    /// - Returns: batching delay block
    @objc public func batchingDelayBlock() -> BatchingDelayBlock? {
        var delayBlock: BatchingDelayBlock?
        batchingDelayQueue.sync {
            delayBlock = self.batchingDelayClosure
        }
        return delayBlock
    }
}

// MARK: Scheduling
fileprivate extension RAnalyticsSender {
    func performBackgroundUpload(records: [Data], identifiers: [Int64]) async {
        /// If you make changes to the payload format, always confirm with RAT team
        /// that the server-side program will accept the updated format.
        guard let endpointURL = endpointURL,
              !records.isEmpty,
              let ratJsonRecords = [JsonRecord](ratDataRecords: records),
              !ratJsonRecords.isEmpty,
              let data = Data(ratJsonRecords: ratJsonRecords,
                              internalSerialization: enableInternalSerialization) else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.senderErrorDomain,
                                             code: ErrorCode.senderSendEventsHasFailed.rawValue,
                                             description: ErrorDescription.senderSendEventsHasFailed,
                                             reason: ErrorReason.senderRequestBodyCreationFailure))
            return
        }

        let request = URLRequest(url: endpointURL, body: data)

        do {
            let (_, response) = try await session.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode

            guard statusCode == 200 else {
                let nonOptionalStatusCode = statusCode ?? 0
                let error = ErrorConstants.statusCodeError(with: nonOptionalStatusCode)
                raise(error: error)
                await handleBackgroundUploadError(error, ratJsonRecords: ratJsonRecords)
                return
            }

            NotificationCenter.default.post(name: Notification.Name.rAnalyticsUploadSuccess, object: ratJsonRecords)
            logSentRecords(ratJsonRecords)

            database.enabled = allowsAnalyticsSend()
            await database.deleteBlobs(identifiers: identifiers, in: databaseTableName)
            await scheduleCoordinator.scheduleUploadOrPerformImmediately(appStateOrigin: .foreground, context: self)
        } catch {
            /// Connection failed. Request a new attempt before ending the upload.
            await scheduleCoordinator.markUploadRequested()
            raise(error: error)
            await handleBackgroundUploadError(error, ratJsonRecords: ratJsonRecords)
        }
    }

    private func raise(error: Error) {
        // Raise the native error
        ErrorRaiser.raise(.embeddedError(error as NSError))

        // Raise the sender error
        ErrorRaiser.raise(.detailedError(domain: ErrorDomain.senderErrorDomain,
                                         code: ErrorCode.senderSendEventsHasFailed.rawValue,
                                         description: (error as NSError).localizedDescription,
                                         reason: (error as NSError).localizedFailureReason ?? ""))
    }

    private func handleBackgroundUploadError(_ error: Error, ratJsonRecords: [JsonRecord]) async {
        NotificationCenter.default.post(name: Notification.Name.rAnalyticsUploadFailure,
                                        object: ratJsonRecords,
                                        userInfo: [NSUnderlyingErrorKey: error])
        await scheduleCoordinator.backgroundUploadEnded(context: self)
    }
}

// MARK: Database handling
extension RAnalyticsSender {
    func insert(dataBlob: Data) {
        database.enabled = allowsAnalyticsSend()
        let blob = dataBlob
        Task { [weak self] in
            guard let self else { return }
            await self.scheduleCoordinator.enqueueInsert(dataBlob: blob, context: self)
        }
    }

    @objc func fetchAndUpload() {
        Task { [weak self] in
            await self?.performFetchAndUpload()
        }
    }

    func performFetchAndUpload() async {
        // Remove schedule start time from UserDefaults
        if case .enabled(let startTimeKey) = backgroundTimerEnabler {
            userStorageHandler.removeObject(forKey: startTimeKey)
        }

        database.enabled = allowsAnalyticsSend()
        let (blobs, identifiers) = await database.fetchBlobs(SenderConstants.ratBatchSize, from: databaseTableName)

        assert(blobs?.count == identifiers?.count, "Sender error: number of blobs must equal number of identifiers.")

        /// Get a group of records and start uploading them.
        if let records = blobs, let identifiers = identifiers {
            RLogger.debug(message: "Events fetched from DB table %@ \(databaseTableName) now upload them")
            await performBackgroundUpload(records: records, identifiers: identifiers)
        } else {
            RLogger.debug(message: "No events found in DB table \(databaseTableName) so end upload")
            await scheduleCoordinator.backgroundUploadEnded(context: self)
        }
    }

    /// Cancels pending uploads and deletes all queued event payloads.
    func clearPendingEvents(completion: @escaping () -> Void) {
        Task { [weak self] in
            guard let self else {
                completion()
                return
            }
            await self.scheduleCoordinator.clearPendingScheduling()
            if case .enabled(let startTimeKey) = self.backgroundTimerEnabler {
                self.userStorageHandler.removeObject(forKey: startTimeKey)
            }
            self.database.enabled = self.allowsAnalyticsSend()
            self.database.deleteAllBlobs(in: self.databaseTableName, then: completion)
        }
    }
}

// MARK: Notification handling
extension RAnalyticsSender {
    fileprivate func configureNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    @objc func appDidBecomeActive() {
        Task { [weak self] in
            guard let self else { return }
            await self.scheduleCoordinator.scheduleUploadOrPerformImmediately(appStateOrigin: .background, context: self)
        }
    }
}

// MARK: Debug logging
extension RAnalyticsSender {
    func logSentRecords(_ records: [Any]) {
        #if DEBUG
        RLogger.debug(message: "Successfully sent the following \(records.count) event(s) to \(String(describing: endpointURL)) from \(description):")
        records.enumerated().forEach { RLogger.debug(message: "Record \($0) = \($1)") }
        #endif
    }
}

// MARK: Public API
extension RAnalyticsSender {
    @objc public convenience init?(endpoint: URL,
                                   databaseName: String,
                                   databaseTableName: String,
                                   databaseParentDirectory: FileManager.SearchPathDirectory = .documentDirectory,
                                   userStorageHandler: UserDefaults = UserDefaults.standard) {
        guard let connection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: databaseName,
                                                                          databaseParentDirectory: databaseParentDirectory) else {
            return nil
        }
        self.init(endpoint: endpoint,
                  database: RAnalyticsDatabase.database(connection: connection),
                  databaseTable: databaseTableName,
                  userStorageHandler: userStorageHandler)
    }
}

// MARK: Internal API
extension RAnalyticsSender {
    convenience init?(databaseConfiguration: DatabaseConfigurable?,
                      bundle: EnvironmentBundle,
                      session: SwiftySessionable,
                      userStorageHandler: UserStorageHandleable,
                      allowsAnalyticsSend: @escaping () -> Bool) {
        guard let databaseConfiguration = databaseConfiguration else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.senderErrorDomain,
                                             code: ErrorCode.senderCreationFailed.rawValue,
                                             description: ErrorDescription.senderCreationFailed,
                                             reason: ErrorReason.databaseConnectionIsNil))
            return nil
        }
        guard let endpointURL = bundle.endpointAddress else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.senderErrorDomain,
                                             code: ErrorCode.senderCreationFailed.rawValue,
                                             description: ErrorDescription.senderCreationFailed,
                                             reason: ErrorReason.endpointMissing))
            return nil
        }
        self.init(endpoint: endpointURL,
                  database: databaseConfiguration.database,
                  databaseTable: databaseConfiguration.tableName,
                  bundle: bundle,
                  session: session,
                  userStorageHandler: userStorageHandler,
                  allowsAnalyticsSend: allowsAnalyticsSend)
    }
}

// MARK: Schedule coordinator context
extension RAnalyticsSender: SenderScheduleContext {
    func senderMaxUploadInterval() -> TimeInterval {
        maxUploadInterval
    }

    func senderUploadTimerInterval() -> TimeInterval {
        uploadTimerInterval
    }

    func setSenderUploadTimerInterval(_ interval: TimeInterval) {
        uploadTimerInterval = interval
    }

    func batchingDelayInterval() -> TimeInterval? {
        batchingDelayBlock()?()
    }

    func scheduleElapsedTime(for startTimeKey: String) -> TimeInterval? {
        let scheduleStartTime = userStorageHandler.object(forKey: startTimeKey)

        guard let startedDateTime = scheduleStartTime as? NSNumber else {
            return nil
        }

        return Date().timeIntervalSince1970 - startedDateTime.doubleValue
    }

    func ensureBackgroundScheduleStartDate(for startTimeKey: String) {
        if let scheduleStartTime = userStorageHandler.object(forKey: startTimeKey) as? NSNumber {
            scheduleStartDate = Date(timeIntervalSince1970: scheduleStartTime.doubleValue)
        } else {
            let nowDate = Date()
            scheduleStartDate = nowDate
            userStorageHandler.set(value: NSNumber(value: nowDate.timeIntervalSince1970),
                                   forKey: startTimeKey)
        }
    }

    func performInsert(dataBlob: Data) async {
        await database.insert(blob: dataBlob, into: databaseTableName, limit: SenderConstants.tableBlobLimit)
    }
}

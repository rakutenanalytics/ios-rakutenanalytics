import Foundation
import UIKit

private enum SenderConstants {
    static let tableBlobLimit = UInt(5000)
    static let ratBatchSize = UInt(16)
    static let defaultUploadInterval = TimeInterval(0.0)
    static let minUploadInterval = TimeInterval(0.0)
    static let retryInterval = TimeInterval(10.0)
}

@objc public protocol Sendable: NSObjectProtocol {
    var endpointURL: URL? { get set }
    func setBatchingDelayBlock(_ batchingDelayBlock: @escaping @autoclosure BatchingDelayBlock)
    func batchingDelayBlock() -> BatchingDelayBlock?
    @objc(sendJSONObject:) func send(jsonObject: Any)
}

private enum AppStateOrigin {
    case foreground
    case background
}

enum SenderBackgroundTimerEnabler {
    case none
    case enabled(startTimeKey: String)
}

@objc public final class RAnalyticsSender: NSObject, EndpointSettable, Sendable {
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

    /// uploadTimer is used to throttle uploads. A call to scheduleBackgroundUpload
    /// will do nothing if uploadTimer is not nil.

    /// Since we don't want to start a new upload until the previous one has been fully
    /// processed, though, we only invalidate that timer at the very end of the HTTP
    /// request. That's why we also need uploadRequested, set by scheduleBackgroundUpload,
    /// so that we know we have to restart our timer at that point.
    @AtomicGetSet private(set) var uploadTimer: Timer?
    @objc public private(set) var uploadTimerInterval = SenderConstants.defaultUploadInterval

    private var batchingDelayClosure: BatchingDelayBlock?
    @AtomicGetSet private var uploadRequested = false
    @AtomicGetSet private var zeroBatchingDelayUploadInProgress = false

    /// Initialize Sender
    /// - Parameters:
    ///   - endpoint: endpoint URL
    ///   - database: database to read/write
    ///   - databaseTable: name of database
    ///   - userStorageHandler: the user storage handler.
    convenience init(endpoint: URL,
                     database: RAnalyticsDatabase,
                     databaseTable: String,
                     userStorageHandler: UserStorageHandleable) {
        self.init(endpoint: endpoint,
                  database: database,
                  databaseTable: databaseTable,
                  bundle: Bundle.main,
                  session: URLSession.shared,
                  userStorageHandler: userStorageHandler)
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
    ///
    ///   - Note: if the batching delay is greater than `maxUploadInterval`, then `maxUploadInterval` is taken as the default batching delay.
    init(endpoint: URL,
         database: RAnalyticsDatabase,
         databaseTable: String,
         bundle: EnvironmentBundle,
         session: SwiftySessionable,
         maxUploadInterval: TimeInterval = TimeInterval(60.0),
         userStorageHandler: UserStorageHandleable) {
        self.safeEndpointURL = endpoint
        self.database = database
        self.databaseTableName = databaseTable
        self.batchingDelayClosure = { return SenderConstants.defaultUploadInterval }
        self.enableInternalSerialization = bundle.enableInternalSerialization
        self.session = session
        self.maxUploadInterval = maxUploadInterval
        self.userStorageHandler = userStorageHandler
        super.init()

        configureNotifications()
    }

    deinit {
        uploadTimer?.invalidate()
    }

    /// Store event data in database to be sent later
    /// - Parameter jsonObject: json object
    @objc(sendJSONObject:)
    public func send(jsonObject: Any) {
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
        batchingDelayClosure = batchingDelayBlock
    }

    /// Batching delay
    /// - Returns: batching delay block
    @objc public func batchingDelayBlock() -> BatchingDelayBlock? {
        return batchingDelayClosure
    }
}

// MARK: Scheduling
fileprivate extension RAnalyticsSender {
    /// - Returns: the schedule elapsed time or `nil` if the elapsed time is not stored in the UserDefaults.
    private func scheduleElapsedTime(for startTimeKey: String) -> TimeInterval? {
        let scheduleStartTime = userStorageHandler.object(forKey: startTimeKey)

        guard let startedDateTime = scheduleStartTime as? NSNumber else {
            return nil
        }

        let elapsedTime = Date().timeIntervalSince1970 - startedDateTime.doubleValue

        return elapsedTime
    }

    /// Schedule an upload.
    ///
    /// - Parameter appStateOrigin: the app state origin needed for a background upload.
    func scheduleUploadOrPerformImmediately(appStateOrigin: AppStateOrigin) {
        if let delay = batchingDelayClosure?() {
            if case .enabled(let startTimeKey) = backgroundTimerEnabler,
               let elapsedTime = scheduleElapsedTime(for: startTimeKey) {
                if elapsedTime <= delay {
                    uploadTimerInterval = min(max(SenderConstants.minUploadInterval, delay - elapsedTime), maxUploadInterval)

                } else {
                    uploadTimerInterval = 0
                }

            } else {
                uploadTimerInterval = min(max(SenderConstants.minUploadInterval, delay), maxUploadInterval)
            }
        }

        /// Upload immediately if batching delay is 0 and a request isn't in progress.
        /// Otherwise, schedule the upload in background.
        if uploadTimerInterval <= 0, uploadTimer == nil || uploadTimer?.isValid == false, !zeroBatchingDelayUploadInProgress {
            zeroBatchingDelayUploadInProgress = true
            DispatchQueue.main.async {
                self.fetchAndUpload()
            }
        } else {
            scheduleBackgroundUpload(appStateOrigin: appStateOrigin)
        }
    }

    /// Schedule a new background upload, if none has already been scheduled or is currently being processed.
    ///
    /// - Parameter appStateOrigin: the app state origin. Only read when `backgroundTimerEnabler` is set to true.
    func scheduleBackgroundUpload(appStateOrigin: AppStateOrigin) {
        DispatchQueue.main.async {
            if self.uploadTimer?.isValid == true {
                if case .enabled(_) = self.backgroundTimerEnabler,
                   appStateOrigin == .background {
                    self.uploadTimer?.invalidate()
                    self.createUploadTimer()

                } else {
                    /// Background upload has already been scheduled or is underway
                    self.uploadRequested = true
                }
                return
            }

            if case .enabled(let startTimeKey) = self.backgroundTimerEnabler {
                if let scheduleStartTime = self.userStorageHandler.object(forKey: startTimeKey) as? NSNumber {
                    self.scheduleStartDate = Date(timeIntervalSince1970: scheduleStartTime.doubleValue)

                } else {
                    let nowDate = Date()
                    self.scheduleStartDate = nowDate
                    self.userStorageHandler.set(value: NSNumber(value: nowDate.timeIntervalSince1970),
                                                forKey: startTimeKey)
                }
            }

            self.createUploadTimer()
        }
    }

    /// Create an upload timer.
    private func createUploadTimer() {
        /// If timer interval is zero and we got here it means that there is an upload in progress.
        /// Therefore, schedule a timer with a 10s delay which is short-ish but long enough that
        /// the in progress upload will likely complete before the timer fires.
        let interval = self.uploadTimerInterval == 0 ? SenderConstants.retryInterval : self.uploadTimerInterval

        let uploadTimer = Timer(timeInterval: interval,
                                target: self,
                                selector: #selector(self.fetchAndUpload),
                                userInfo: nil,
                                repeats: false)
        self.uploadTimer = uploadTimer
        RunLoop.current.add(uploadTimer, forMode: .common)
        self.uploadRequested = false
    }

    /// Called whenever a background upload ends, successfully or not.
    /// If uploadRequested has been set, it schedules another upload.
    func backgroundUploadEnded() {
        uploadTimer?.invalidate()
        uploadTimer = nil
        zeroBatchingDelayUploadInProgress = false

        if uploadRequested {
            scheduleBackgroundUpload(appStateOrigin: .foreground)
        }
    }

    func doBackgroundUpload(records: [Data], identifiers: [Int64]) {
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

        let task = session.dataTask(with: request) { result in
            switch result {
            case .failure(let error):
                /// Connection failed. Request a new attempt before calling the completion.
                self.uploadRequested = true
                self.raise(error: error)
                self.handleBackgroundUploadError(error, ratJsonRecords: ratJsonRecords)

            case .success(let responseInfo):
                let statusCode = (responseInfo.response as? HTTPURLResponse)?.statusCode

                guard statusCode == 200 else {
                    let nonOptionalStatusCode = statusCode ?? 0
                    let error = ErrorConstants.statusCodeError(with: nonOptionalStatusCode)
                    self.raise(error: error)
                    self.handleBackgroundUploadError(error, ratJsonRecords: ratJsonRecords)
                    return
                }

                NotificationCenter.default.post(name: Notification.Name.RAnalyticsUploadSuccess, object: ratJsonRecords)
                self.logSentRecords(ratJsonRecords)

                self.database.deleteBlobs(identifiers: identifiers, in: self.databaseTableName) {
                    self.scheduleUploadOrPerformImmediately(appStateOrigin: .foreground)
                }
            }
        }
        task.resume()
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

    private func handleBackgroundUploadError(_ error: Error, ratJsonRecords: [JsonRecord]) {
        NotificationCenter.default.post(name: Notification.Name.RAnalyticsUploadFailure,
                                        object: ratJsonRecords,
                                        userInfo: [NSUnderlyingErrorKey: error])
        backgroundUploadEnded()
    }
}

// MARK: Database handling
extension RAnalyticsSender {
    func insert(dataBlob: Data) {
        database.insert(blob: dataBlob, into: databaseTableName, limit: SenderConstants.tableBlobLimit) {
            self.scheduleUploadOrPerformImmediately(appStateOrigin: .foreground)
        }
    }

    @objc func fetchAndUpload() {
        // Remove schedule start time from UserDefaults
        if case .enabled(let startTimeKey) = backgroundTimerEnabler {
            userStorageHandler.removeObject(forKey: startTimeKey)
        }

        database.fetchBlobs(SenderConstants.ratBatchSize, from: databaseTableName) { (blobs, identifiers) in

            assert(blobs?.count == identifiers?.count, "Sender error: number of blobs must equal number of identifiers.")

            /// Get a group of records and start uploading them.
            if let records = blobs, let identifiers = identifiers {
                RLogger.debug(message: "Events fetched from DB table %@ \(self.databaseTableName) now upload them")
                self.doBackgroundUpload(records: records, identifiers: identifiers)
            } else {
                RLogger.debug(message: "No events found in DB table \(self.databaseTableName) so end upload")
                self.backgroundUploadEnded()
            }
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
        scheduleUploadOrPerformImmediately(appStateOrigin: .background)
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
                      userStorageHandler: UserStorageHandleable) {
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
                  userStorageHandler: userStorageHandler)
    }
}

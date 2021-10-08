import Foundation
import RSDKUtils

private enum SenderConstants {
    static let tableBlobLimit = UInt(5000)
    static let ratBatchSize = UInt(16)
    static let defaultUploadInterval = TimeInterval(0.0)
    static let minUploadInterval = TimeInterval(0.0)
    static let maxUploadInterval = TimeInterval(60.0)
    static let retryInterval = TimeInterval(10.0)
}

@objc public protocol Sendable: NSObjectProtocol {
    var endpointURL: URL? { get set }
    func setBatchingDelayBlock(_ batchingDelayBlock: @escaping @autoclosure BatchingDelayBlock)
    func batchingDelayBlock() -> BatchingDelayBlock?
    @objc(sendJSONObject:) func send(jsonObject: Any)
}

@objc public final class RAnalyticsSender: NSObject, EndpointSettable, Sendable {
    @objc public var endpointURL: URL? {
        get {
            self._endpointURL
        }
        set {
            self._endpointURL = newValue
        }
    }

    @AtomicGetSet private var _endpointURL: URL?
    /// Enable the experimental internal JSON serialization or not.
    /// The experimental internal JSON serialization fixes the float numbers decimals.
    private let enableInternalSerialization: Bool

    private let database: RAnalyticsDatabase
    private let databaseTableName: String
    private let session: SwiftySessionable

    /// uploadTimer is used to throttle uploads. A call to scheduleBackgroundUpload
    /// will do nothing if uploadTimer is not nil.

    /// Since we don't want to start a new upload until the previous one has been fully
    /// processed, though, we only invalidate that timer at the very end of the HTTP
    /// request. That's why we also need uploadRequested, set by scheduleBackgroundUpload,
    /// so that we know we have to restart our timer at that point.
    @AtomicGetSet var uploadTimer: Timer?
    @objc public private(set) var uploadTimerInterval = SenderConstants.defaultUploadInterval

    private var batchingDelayClosure: BatchingDelayBlock?
    @AtomicGetSet private var uploadRequested = false
    @AtomicGetSet private var zeroBatchingDelayUploadInProgress = false

    /// Initialize Sender
    /// - Parameters:
    ///   - endpoint: endpoint URL
    ///   - database: database to read/write
    ///   - databaseTable: name of database
    convenience init(endpoint: URL,
                     database: RAnalyticsDatabase,
                     databaseTable: String) {
        self.init(endpoint: endpoint,
                  database: database,
                  databaseTable: databaseTable,
                  bundle: Bundle.main,
                  session: URLSession.shared)
    }

    /// Initialize Sender
    /// - Parameters:
    ///   - endpoint: endpoint URL
    ///   - database: database to read/write
    ///   - databaseTable: name of database
    ///   - bundle: the bundle
    ///   - session: the URL session
    init(endpoint: URL,
         database: RAnalyticsDatabase,
         databaseTable: String,
         bundle: EnvironmentBundle,
         session: SwiftySessionable) {
        self._endpointURL = endpoint
        self.database = database
        self.databaseTableName = databaseTable
        self.batchingDelayClosure = { return SenderConstants.defaultUploadInterval }
        self.enableInternalSerialization = bundle.enableInternalSerialization
        self.session = session
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
            RLogger.error("Sender failed to serialize event dictionary")
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
    func scheduleUploadOrPerformImmediately() {
        if let delay = batchingDelayClosure?() {
            uploadTimerInterval = min(max(SenderConstants.minUploadInterval, delay), SenderConstants.maxUploadInterval)
        }

        /// Upload immediately if batching delay is 0 and a request isn't in progress.
        /// Otherwise, schedule the upload in background.
        if uploadTimerInterval <= 0,
           (uploadTimer == nil || uploadTimer?.isValid == false),
           !zeroBatchingDelayUploadInProgress {
            zeroBatchingDelayUploadInProgress = true
            DispatchQueue.main.async {
                self.fetchAndUpload()
            }
        } else {
            scheduleBackgroundUpload()
        }
    }

    /// Schedule a new background upload, if none has already been scheduled or is currently being processed.
    func scheduleBackgroundUpload() {
        DispatchQueue.main.async {
            if self.uploadTimer?.isValid == true {
                /// Background upload has already been scheduled or is underway
                self.uploadRequested = true
                return
            }

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
    }

    /// Called whenever a background upload ends, successfully or not.
    /// If uploadRequested has been set, it schedules another upload.
    func backgroundUploadEnded() {
        uploadTimer?.invalidate()
        uploadTimer = nil
        zeroBatchingDelayUploadInProgress = false

        if uploadRequested {
            scheduleBackgroundUpload()
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
            RLogger.error("Sender error: failed to create RAT request body data")
            return
        }

        let request = URLRequest.ratRequest(url: endpointURL, body: data)

        let task = session.dataTask(with: request) { result in
            switch result {
            case .failure(let error):
                /// Connection failed. Request a new attempt before calling the completion.
                self.uploadRequested = true
                self.handleBackgroundUploadError(error, ratJsonRecords: ratJsonRecords)

            case .success(let responseInfo):
                let statusCode = (responseInfo.response as? HTTPURLResponse)?.statusCode

                guard statusCode == 200 else {
                    let reason = "Expected status code 200, got \(String(describing: statusCode))"
                    let userInfo = [NSLocalizedDescriptionKey: "invalid_response",
                                    NSLocalizedFailureReasonErrorKey: reason]
                    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: userInfo)

                    self.handleBackgroundUploadError(error, ratJsonRecords: ratJsonRecords)
                    return
                }

                NotificationCenter.default.post(name: Notification.Name.RAnalyticsUploadSuccess, object: ratJsonRecords)
                self.logSentRecords(ratJsonRecords)

                self.database.deleteBlobs(identifiers: identifiers, in: self.databaseTableName) {
                    self.scheduleUploadOrPerformImmediately()
                }
            }
        }
        task.resume()
    }

    private func handleBackgroundUploadError(_ error: Error, ratJsonRecords: [JsonRecord]) {
        NotificationCenter.default.post(name: NSNotification.Name.RAnalyticsUploadFailure,
                                        object: ratJsonRecords,
                                        userInfo: [NSUnderlyingErrorKey: error])
        backgroundUploadEnded()
    }
}

// MARK: Database handling
extension RAnalyticsSender {
    func insert(dataBlob: Data) {
        database.insert(blob: dataBlob, into: databaseTableName, limit: SenderConstants.tableBlobLimit) {
            self.scheduleUploadOrPerformImmediately()
        }
    }

    @objc func fetchAndUpload() {
        database.fetchBlobs(SenderConstants.ratBatchSize, from: databaseTableName) { (blobs, identifiers) in

            assert(blobs?.count == identifiers?.count, "Sender error: number of blobs must equal number of identifiers.")

            /// Get a group of records and start uploading them.
            if let records = blobs, let identifiers = identifiers {
                RLogger.debug("Events fetched from DB table %@ \(self.databaseTableName) now upload them")
                self.doBackgroundUpload(records: records, identifiers: identifiers)
            } else {
                RLogger.debug("No events found in DB table \(self.databaseTableName) so end upload")
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
        scheduleUploadOrPerformImmediately()
    }
}

// MARK: Debug logging
extension RAnalyticsSender {
    func logSentRecords(_ records: [Any]) {
        #if DEBUG
        var sentLog = "Successfully sent events to \(String(describing: self.endpointURL)) from \(self.description)."
        for (index, value) in records.enumerated() {
            sentLog.append("\n\(index), \(value)")
        }
        RLogger.debug(sentLog)
        #endif
    }
}

// MARK: Public API
extension RAnalyticsSender {
    @objc public convenience init?(endpoint: URL,
                                   databaseName: String,
                                   databaseTableName: String) {
        guard let connection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: databaseName) else {
            return nil
        }
        self.init(endpoint: endpoint,
                  database: RAnalyticsDatabase.database(connection: connection),
                  databaseTable: databaseTableName)
    }
}

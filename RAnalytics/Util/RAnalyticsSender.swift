import Foundation
import RLogger

private enum SenderConstants {
    static let tableBlobLimit = UInt(5000)
    static let ratBatchSize = UInt(16)
    static let defaultUploadInterval = TimeInterval(0.0)
    static let minUploadInterval = TimeInterval(0.0)
    static let maxUploadInterval = TimeInterval(60.0)
    static let retryInterval = TimeInterval(10.0)
}

@objc public final class RAnalyticsSender: NSObject, EndpointSettable {
    @objc public var endpointURL: URL

    private let database: RAnalyticsDatabase
    private let databaseTableName: String

    /// uploadTimer is used to throttle uploads. A call to scheduleBackgroundUpload
    /// will do nothing if uploadTimer is not nil.

    /// Since we don't want to start a new upload until the previous one has been fully
    /// processed, though, we only invalidate that timer at the very end of the HTTP
    /// request. That's why we also need uploadRequested, set by scheduleBackgroundUpload,
    /// so that we know we have to restart our timer at that point.

    // swiftlint:disable:next todo
    // FIXME: Make private again after tests are refactored
    @objc public var uploadTimer: Timer?
    @objc public var uploadTimerInterval = SenderConstants.defaultUploadInterval

    private var batchingDelayClosure: BatchingDelayBlock?
    private var uploadRequested = false
    private var zeroBatchingDelayUploadInProgress = false

    /// Initialize Sender
    /// - Parameters:
    ///   - endpoint: endpoint URL
    ///   - database: database to read/write
    ///   - databaseTable: name of database
    @objc public init?(endpoint: URL,
                       database: RAnalyticsDatabase,
                       databaseTable: String) {
        self.endpointURL = endpoint
        self.database = database
        self.databaseTableName = databaseTable
        self.batchingDelayClosure = { return SenderConstants.defaultUploadInterval }
        super.init()

        configureNotifications()
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

        RLogger.verbose("Storing event with the following payload: \(payloadString)")
        insert(dataBlob: data)
    }

    /// Set the batching delay
    /// - Parameter batchingDelayBlock: batching delay block
    @objc public func setBatchingDelayBlock(_ batchingDelayBlock: @escaping BatchingDelayBlock) {
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

            // swiftlint:disable:next todo
            // FIXME: add timer to common mode not default - re: request to send events while scrolling
            self.uploadTimer = Timer.scheduledTimer(timeInterval: interval,
                                                    target: self,
                                                    selector: #selector(self.fetchAndUpload),
                                                    userInfo: nil,
                                                    repeats: false)
            self.uploadRequested = false
        }
    }

    /// Called whenever a background upload ends, successfully or not.
    /// If uploadRequested has been set, it schedules another upload.
    func backgroundUploadEnded() {
        // swiftlint:disable:next todo
        // FIXME: does this need synced? how to synchronize?
        /// start @synchronized
        uploadTimer?.invalidate()
        uploadTimer = nil
        zeroBatchingDelayUploadInProgress = false
        /// end @synchronized

        if uploadRequested {
            scheduleBackgroundUpload()
        }
    }

    func doBackgroundUpload(records: [Data], identifiers: [Int64]) {
        /// When you make changes here, always check the server-side program will accept it.
        /// The source code is at https://git.rakuten-it.com/projects/RATR/repos/receiver/browse/receiver.c
        guard let recordGroup = NSMutableArray(ratDataRecords: records as [NSData]) as? [NSDictionary],
              let data = NSMutableData(ratRecords: recordGroup) else {
            return
        }

        let request = NSURLRequest.ratRequest(url: endpointURL, body: data as Data)

        let task = URLSession.shared.dataTask(with: request as URLRequest) {(_, response, error) in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                let innerError: Error
                if let connectionError = error {
                    /// Connection failed. Request a new attempt before calling the completion.
                    // swiftlint:disable:next todo
                    // FIXME: does this synchronized?
                    /// start @synchronized
                    innerError = connectionError
                    self.uploadRequested = true
                    /// end @synchronized
                } else {
                    let reason = "Expected status code 200, got \(String(describing: (response as? HTTPURLResponse)?.statusCode))"
                    let userInfo = [NSLocalizedDescriptionKey: "invalid_response",
                                    NSLocalizedFailureReasonErrorKey: reason]
                    innerError = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: userInfo)
                }
                let userInfo = [NSUnderlyingErrorKey: innerError]
                NotificationCenter.default.post(name: NSNotification.Name.RAnalyticsUploadFailure,
                                                object: recordGroup,
                                                userInfo: userInfo)
                self.backgroundUploadEnded()
                return
            }

            /// Success!
            NotificationCenter.default.post(name: Notification.Name.RAnalyticsUploadSuccess, object: recordGroup)
            self.logSentRecords(recordGroup)

            /// Delete the records from the local database.
            self.database.deleteBlobs(identifiers: identifiers, in: self.databaseTableName) {
                self.scheduleUploadOrPerformImmediately()
            }

        }
        task.resume()
    }
}

// MARK: Database handling
@objc extension RAnalyticsSender {
    public func insert(dataBlob: Data) {
        database.insert(blob: dataBlob, into: databaseTableName, limit: SenderConstants.tableBlobLimit) {
            self.scheduleUploadOrPerformImmediately()
        }
    }

    func fetchAndUpload() {
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
@objc extension RAnalyticsSender {
    fileprivate func configureNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    func appDidBecomeActive() {
        scheduleUploadOrPerformImmediately()
    }
}

// MARK: Debug logging
extension RAnalyticsSender {
    func logSentRecords(_ records: [Any]) {
        #if DEBUG
        var sentLog = "Successfully sent events to \(self.endpointURL) from \(self.description)."
        for (index, value) in records.enumerated() {
            sentLog.append("\n\(index), \(value)")
        }
        RLogger.debug(sentLog)
        #endif
    }
}

// MARK: Temporary for unit tests
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

import Foundation
import SQLite3
#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsMain
import RLogger
#endif
import UIKit

typealias SQlite3Pointer = OpaquePointer

///
/// Internal class used to centralize access to the analytics database.
///
/// All the methods below are executed on a background FIFO, so there is no
/// need to otherwise synchronize calls to them. Completion blocks are then
/// executed on the caller's operation queue.
///
final class RAnalyticsDatabase {
    private let connection: SQlite3Pointer
    private var tables = Set<String>()
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.rakuten.esd.sdk.analytics.database"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .default
        return queue
    }()
    @AtomicGetSet private var appWillTerminate = false

    ///
    /// Creates DB manager instance with SQLite connection
    ///
    /// - Parameter connection: SQLite DB connection
    ///
    @discardableResult
    static func database(connection: SQlite3Pointer) -> RAnalyticsDatabase {
        return RAnalyticsDatabase(connection: connection)
    }

    private init(connection: SQlite3Pointer) {
        self.connection = connection
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willTerminate),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }

    deinit {
        queue.cancelAllOperations()
    }

    ///
    /// Insert a new, single blob into a table.
    ///
    /// - Parameter blob:                  Blob to insert.
    /// - Parameter table:                 Name of the destination table.
    /// - Parameter maximumNumberOfBlobs:  Maximum number of blobs to keep in the table.
    /// - Parameter completion:            Block to call upon completion.
    ///
    func insert(blob: Data,
                into table: String,
                limit maximumNumberOfBlobs: UInt,
                then completion: @escaping () -> Void) {

        insert(blobs: [blob], into: table, limit: maximumNumberOfBlobs, then: completion)
    }

    ///
    /// Insert multiple new blobs into a table, in a single transaction.
    ///
    /// - Parameter blobs:                 Blobs to insert.
    /// - Parameter table:                 Name of the destination table.
    /// - Parameter maximumNumberOfBlobs:  Maximum number of blobs to keep in the table.
    /// - Parameter completion:            Block to call upon completion.
    ///
    func insert(blobs: [Data],
                into table: String,
                limit maximumNumberOfBlobs: UInt,
                then completion: @escaping () -> Void) {

        queue.addOperation { [weak self] in
            defer {
                completion()
            }
            guard let self = self else {
                return
            }

            let error = self.prepareTable(table)
            guard error == nil,
                  RAnalyticsDatabaseHelper.beginTransaction(connection: self.connection) else {
                return
            }
            defer {
                RAnalyticsDatabaseHelper.commitTransaction(connection: self.connection)
            }

            let query = "insert into \(table) (data) values(?)"
            var statement: SQlite3Pointer?
            guard RAnalyticsDatabaseHelper.prepareStatement(&statement, query: query, connection: self.connection) else {
                return
            }

            let op: (Data) -> Void = { blob in
                blob.withUnsafeBytes { bytes -> Void in
                    if sqlite3_bind_blob(statement, 1, bytes.baseAddress, Int32(bytes.count), nil) == SQLITE_OK {
                        sqlite3_step(statement)
                        sqlite3_clear_bindings(statement)
                    }
                    sqlite3_reset(statement)
                }
            }
            blobs.forEach(op)
            sqlite3_finalize(statement)

            if maximumNumberOfBlobs != 0 {
                // Truncate the table by removing older records (blobs)
                let query = "delete from \(table) where id not in (select id from \(table) order by id desc limit \(maximumNumberOfBlobs))"
                sqlite3_exec(self.connection, query, nil, nil, nil)
            }
        }
    }

    ///
    /// Try to fetch a number of blobs from a table, from the most ancient to the most recent.
    ///
    /// - Parameter maximumNumberOfBlobs:  Maximum number of blobs we want to read.
    /// - Parameter table:                 Name of the table.
    /// - Parameter completion:            Block to call upon completion.
    ///
    func fetchBlobs(_ maximumNumberOfBlobs: UInt,
                    from table: String,
                    then completion: @escaping (_ blobs: [Data]?, _ identifiers: [Int64]?) -> Void) {

        queue.addOperation { [weak self] in
            var blobs = [Data]()
            var identifiers = [Int64]()

            defer {
                completion(blobs.isEmpty ? nil : blobs,
                           identifiers.isEmpty ? nil : identifiers)
            }
            guard let self = self else {
                return
            }

            blobs.reserveCapacity(Int(maximumNumberOfBlobs))
            identifiers.reserveCapacity(Int(maximumNumberOfBlobs))

            let error = self.prepareTable(table)
            guard error == nil, maximumNumberOfBlobs > 0 else {
                return
            }

            let query = "select * from \(table) limit \(maximumNumberOfBlobs)"
            var statement: SQlite3Pointer?
            guard RAnalyticsDatabaseHelper.prepareStatement(&statement, query: query, connection: self.connection) else {
                return
            }

            while sqlite3_step(statement) == SQLITE_ROW {
                let primaryKey = sqlite3_column_int64(statement, 0)
                let bytes: UnsafeRawPointer = sqlite3_column_blob(statement, 1)
                let length = sqlite3_column_bytes(statement, 1)

                blobs.append(Data(bytes: bytes, count: Int(length)))
                identifiers.append(primaryKey)
            }
            sqlite3_finalize(statement)
        }
    }

    ///
    /// Delete blobs with the given identifier from a table.
    ///
    /// - Parameter identifiers:  Blob identifiers.
    /// - Parameter table:        Name of the table.
    /// - Parameter completion:   Block to call upon completion.
    ///
    func deleteBlobs(identifiers: [Int64],
                     in table: String,
                     then completion: @escaping () -> Void) {

        guard !appWillTerminate else {
            RLogger.debug(message: "RAnalyticsDatabase - deleteBlobs is cancelled because the app will terminate")
            completion()
            return
        }

        queue.addOperation { [weak self] in
            defer {
                completion()
            }
            guard let self = self else {
                return
            }

            guard self.isTablePresent(table),
                  RAnalyticsDatabaseHelper.beginTransaction(connection: self.connection) else {
                return
            }
            defer {
                RAnalyticsDatabaseHelper.commitTransaction(connection: self.connection)
            }

            let query = "delete from \(table) where id=?"
            var statement: SQlite3Pointer?
            guard RAnalyticsDatabaseHelper.prepareStatement(&statement, query: query, connection: self.connection) else {
                return
            }

            identifiers.forEach { identifier in
                sqlite3_bind_int64(statement, 1, identifier)
                sqlite3_step(statement)
                sqlite3_clear_bindings(statement)
                sqlite3_reset(statement)
            }
            sqlite3_finalize(statement)
        }
    }

    /// Safely closes DB connection after all operations are finished.
    /// Calling this method makes this RAnalyticsDatabase object unusable. Use for tests only.
    func closeConnection() {
        let operation = BlockOperation(block: {
            sqlite3_close_v2(self.connection)
        })
        queue.addOperations([operation], waitUntilFinished: true)
    }
}

private extension RAnalyticsDatabase {

    func isTablePresent(_ table: String) -> Bool {
        guard !tables.contains(table) else {
            return true
        }

        let query = "SELECT EXISTS(SELECT name FROM sqlite_master WHERE type='table' AND name='\(table)')"
        var statement: SQlite3Pointer?
        guard RAnalyticsDatabaseHelper.prepareStatement(&statement, query: query, connection: self.connection) else {
            assertionFailure()
            return false
        }

        sqlite3_step(statement)
        let tableCount = sqlite3_column_int(statement, 0)
        sqlite3_reset(statement)
        sqlite3_finalize(statement)

        let isPresent = tableCount > 0
        if isPresent {
            tables.insert(table)
        }
        return isPresent
    }

    func prepareTable(_ table: String) -> NSError? {
        guard !appWillTerminate else {
            let error = AnalyticsError.detailedError(domain: ErrorDomain.databaseErrorDomain,
                                                     code: ErrorCode.databaseAppWillTerminate.rawValue,
                                                     description: ErrorDescription.databasePrepareTableError,
                                                     reason: ErrorReason.databaseAppIsTerminatingError)
            ErrorRaiser.raise(error)
            return error.nsError()
        }

        assert(OperationQueue.current == queue)
        guard !tables.contains(table) else {
            return nil
        }

        let query = "create table if not exists \(table) (id integer primary key, data blob)"
        guard sqlite3_exec(connection, query, nil, nil, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(connection))
            let message = "Failed to create table: \(errorMsg), code \(sqlite3_errcode(connection))"
            let error = AnalyticsError.detailedError(domain: ErrorDomain.databaseErrorDomain,
                                                     code: ErrorCode.databaseTableCreationFailure.rawValue,
                                                     description: ErrorDescription.databaseError,
                                                     reason: message)
            ErrorRaiser.raise(error)
            return error.nsError()
        }

        tables.insert(table)
        return nil
    }
}

private extension RAnalyticsDatabase {

    @objc func willTerminate() {
        _appWillTerminate.mutate { $0 = true }
    }
}

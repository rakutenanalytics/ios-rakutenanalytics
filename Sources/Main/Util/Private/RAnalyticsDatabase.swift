import Foundation
import SQLite3
import UIKit

typealias SQlite3Pointer = OpaquePointer

/// Internal class used to centralize access to the analytics database.
///
/// All CRUD runs on a serial `OperationQueue`; async methods bridge via continuations.
/// `@unchecked Sendable` documents that queue contract for Swift concurrency.
final class RAnalyticsDatabase: @unchecked Sendable {
    private static var sharedConnection: SQlite3Pointer?
    private static let connectionQueue = DispatchQueue(label: "com.rakuten.esd.sdk.analytics.connectionQueue")

    private var connection: SQlite3Pointer?
    private var tables = Set<String>()
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.rakuten.esd.sdk.analytics.database"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .default
        return queue
    }()
    @AtomicGetSet private var appWillTerminate = false

    /// Enables the operations (fetch, insert and delete) over the database.
    ///
    /// - Note: This feature is created for enabling RAnalyticsDatabase operations only when AnalyticsManager is manually initialized.
    var enabled = false

    /// Creates DB manager instance with SQLite connection
    ///
    /// - Parameter connection: SQLite DB connection
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
        NotificationCenter.default.removeObserver(self)
    }

    /// Insert a new, single blob into a table.
    ///
    /// - Parameter blob:                  Blob to insert.
    /// - Parameter table:                 Name of the destination table.
    /// - Parameter maximumNumberOfBlobs:  Maximum number of blobs to keep in the table.
    func insert(blob: Data,
                into table: String,
                limit maximumNumberOfBlobs: UInt) async {
        await insert(blobs: [blob], into: table, limit: maximumNumberOfBlobs)
    }

    /// Insert multiple new blobs into a table, in a single transaction.
    ///
    /// - Parameter blobs:                 Blobs to insert.
    /// - Parameter table:                 Name of the destination table.
    /// - Parameter maximumNumberOfBlobs:  Maximum number of blobs to keep in the table.
    func insert(blobs: [Data],
                into table: String,
                limit maximumNumberOfBlobs: UInt) async {
        guard enabled else {
            RLogger.error(message: "Database insert operation blocked because manual initialization is enabled and AnalyticsManager is not configured.")
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.addOperation { [weak self] in
                defer {
                    continuation.resume()
                }
                self?.insertBlobsSync(blobs, into: table, limit: maximumNumberOfBlobs)
            }
        }
    }

    /// Try to fetch a number of blobs from a table, from the most ancient to the most recent.
    ///
    /// - Parameter maximumNumberOfBlobs:  Maximum number of blobs we want to read.
    /// - Parameter table:                 Name of the table.
    func fetchBlobs(_ maximumNumberOfBlobs: UInt, from table: String) async -> (blobs: [Data]?, identifiers: [Int64]?) {
        guard enabled else {
            RLogger.warning(message: "Database fetch operation blocked because manual initialization is enabled and AnalyticsManager is not configured.")
            return (nil, nil)
        }

        return await withCheckedContinuation { continuation in
            queue.addOperation { [weak self] in
                let result = self?.fetchBlobsSync(maximumNumberOfBlobs, from: table) ?? (nil, nil)
                continuation.resume(returning: result)
            }
        }
    }

    private func processStatement(_ statement: OpaquePointer?, blobs: inout [Data], identifiers: inout [Int64]) {
        while sqlite3_step(statement) == SQLITE_ROW {
            let primaryKey = sqlite3_column_int64(statement, 0)

            guard let bytes = sqlite3_column_blob(statement, 1) else {
                continue
            }

            let length = sqlite3_column_bytes(statement, 1)
            blobs.append(Data(bytes: bytes, count: Int(length)))
            identifiers.append(primaryKey)
        }
    }

    /// Delete all blobs from a table.
    ///
    /// - Parameter table:        Name of the table.
    /// - Parameter completion:   Block to call upon completion.
    func deleteAllBlobs(in table: String, then completion: @escaping () -> Void) {
        guard enabled else {
            completion()
            return
        }

        guard !appWillTerminate else {
            RLogger.debug(message: "RAnalyticsDatabase - deleteAllBlobs is cancelled because the app will terminate")
            completion()
            return
        }

        queue.addOperation { [weak self] in
            defer {
                completion()
            }
            guard let self = self, let connection = self.connection else {
                return
            }

            guard self.isTablePresent(table),
                  RAnalyticsDatabaseHelper.beginTransaction(connection: connection) else {
                return
            }
            defer {
                RAnalyticsDatabaseHelper.commitTransaction(connection: connection)
            }

            let query = "delete from \(table)"
            sqlite3_exec(connection, query, nil, nil, nil)
        }
    }

    /// Delete blobs with the given identifier from a table.
    ///
    /// - Parameter identifiers:  Blob identifiers.
    /// - Parameter table:        Name of the table.
    func deleteBlobs(identifiers: [Int64], in table: String) async {
        guard enabled else {
            RLogger.error(message: "Database delete operation blocked because manual initialization is enabled and AnalyticsManager is not configured.")
            return
        }

        guard !appWillTerminate else {
            RLogger.debug(message: "RAnalyticsDatabase - deleteBlobs is cancelled because the app will terminate")
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.addOperation { [weak self] in
                defer {
                    continuation.resume()
                }
                self?.deleteBlobsSync(identifiers: identifiers, in: table)
            }
        }
    }

    /// Safely closes DB connection after all operations are finished.
    /// Calling this method makes this RAnalyticsDatabase object unusable. Use for tests only.
    func closeConnection() {
        let operation = BlockOperation(block: { [weak self] in
            guard let connection = self?.connection else { return }
            _ = SQLiteConnectionLock.withLock(connection) {
                sqlite3_close_v2(connection)
            }
            self?.connection = nil
        })
        queue.addOperations([operation], waitUntilFinished: true)
    }
}

private extension RAnalyticsDatabase {

    func insertBlobsSync(_ blobs: [Data], into table: String, limit maximumNumberOfBlobs: UInt) {
        guard let connection = self.connection else {
            return
        }

        SQLiteConnectionLock.withLock(connection) {
            let error = self.prepareTable(table)
            guard error == nil,
                  RAnalyticsDatabaseHelper.beginTransaction(connection: connection) else {
                return
            }
            defer {
                RAnalyticsDatabaseHelper.commitTransaction(connection: connection)
            }

            let query = "insert into \(table) (data) values(?)"
            var statement: SQlite3Pointer?
            guard RAnalyticsDatabaseHelper.prepareStatement(&statement, query: query, connection: connection) else {
                return
            }

            blobs.forEach { blob in
                self.bindAndStep(blob: blob, statement: statement)
            }
            sqlite3_finalize(statement)

            if maximumNumberOfBlobs != 0 {
                let query = "delete from \(table) where id not in (select id from \(table) order by id desc limit \(maximumNumberOfBlobs))"
                sqlite3_exec(connection, query, nil, nil, nil)
            }
        }
    }

    func bindAndStep(blob: Data, statement: SQlite3Pointer?) {
        blob.withUnsafeBytes { bytes in
            if sqlite3_bind_blob(statement, 1, bytes.baseAddress, Int32(bytes.count), nil) == SQLITE_OK {
                sqlite3_step(statement)
                sqlite3_clear_bindings(statement)
            }
            sqlite3_reset(statement)
        }
    }

    func fetchBlobsSync(_ maximumNumberOfBlobs: UInt, from table: String) -> (blobs: [Data]?, identifiers: [Int64]?) {
        guard let connection = self.connection else {
            return (nil, nil)
        }

        var blobs = [Data]()
        var identifiers = [Int64]()

        SQLiteConnectionLock.withLock(connection) {
            blobs.reserveCapacity(Int(maximumNumberOfBlobs))
            identifiers.reserveCapacity(Int(maximumNumberOfBlobs))

            guard self.prepareTable(table) == nil, maximumNumberOfBlobs > 0 else { return }

            let query = "SELECT * FROM \(table) ORDER BY rowid ASC LIMIT \(maximumNumberOfBlobs)"
            var statement: OpaquePointer?

            guard RAnalyticsDatabaseHelper.prepareStatement(&statement, query: query, connection: connection) else {
                return
            }

            defer {
                if statement != nil {
                    sqlite3_finalize(statement)
                }
            }

            self.processStatement(statement, blobs: &blobs, identifiers: &identifiers)
        }

        return (blobs.isEmpty ? nil : blobs, identifiers.isEmpty ? nil : identifiers)
    }

    func deleteBlobsSync(identifiers: [Int64], in table: String) {
        guard let connection = self.connection else {
            return
        }

        SQLiteConnectionLock.withLock(connection) {
            guard self.isTablePresent(table),
                  RAnalyticsDatabaseHelper.beginTransaction(connection: connection) else {
                return
            }
            defer {
                RAnalyticsDatabaseHelper.commitTransaction(connection: connection)
            }

            let query = "delete from \(table) where id=?"
            var statement: SQlite3Pointer?
            guard RAnalyticsDatabaseHelper.prepareStatement(&statement, query: query, connection: connection) else {
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

    func isTablePresent(_ table: String) -> Bool {
        guard !tables.contains(table) else {
            return true
        }

        let query = "SELECT EXISTS(SELECT name FROM sqlite_master WHERE type='table' AND name='\(table)')"
        var statement: SQlite3Pointer?
        guard RAnalyticsDatabaseHelper.prepareStatement(&statement, query: query, connection: self.connection!) else {
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

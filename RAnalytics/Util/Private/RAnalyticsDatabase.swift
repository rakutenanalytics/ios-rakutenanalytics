import Foundation
import SQLite3
import RLogger

public typealias SQlite3Pointer = OpaquePointer

///
/// Internal class used to centralize access to the analytics database.
///
/// All the methods below are executed on a background FIFO, so there is no
/// need to otherwise synchronize calls to them. Completion blocks are then
/// executed on the caller's operation queue.
///
public final class RAnalyticsDatabase: NSObject {

    private static let RAnalyticsDBErrorDomain = "RAnalyticsDBErrorDomain"
    private static let RAnalyticsDBTableCreationFailureErrorCode = 1 //swiftlint:disable:this identifier_name

    private let connection: SQlite3Pointer
    private var tables = Set<String>()
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.rakuten.esd.sdk.analytics.database"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    ///
    /// Creates DB manager instance with SQLite connection
    ///
    /// - Parameter connection: SQLite DB connection
    ///
    @discardableResult
    @objc public static func database(connection: SQlite3Pointer) -> RAnalyticsDatabase {
        return RAnalyticsDatabase(connection: connection)
    }

    private init(connection: SQlite3Pointer) {
        self.connection = connection
    }

    ///
    /// Insert a new, single blob into a table.
    ///
    /// - Parameter blob:                  Blob to insert.
    /// - Parameter table:                 Name of the destination table.
    /// - Parameter maximumNumberOfBlobs:  Maximum number of blobs to keep in the table.
    /// - Parameter completion:            Block to call upon completion.
    ///
    @objc(insertBlob:into:limit:then:)
    public func insert(blob: Data,
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
    @objc(insertBlobs:into:limit:then:)
    public func insert(blobs: [Data],
                       into table: String,
                       limit maximumNumberOfBlobs: UInt,
                       then completion: @escaping () -> Void) {

        guard let callerQueue = OperationQueue.current else {
            assertionFailure("Caller's queue could not be obtained. insertBlobs operation could not be performed.")
            completion()
            return
        }

        queue.addOperation { [weak self] in

            guard let self = self else {
                return
            }
            defer {
                callerQueue.addOperation(completion)
            }

            let error = self.prepareTable(table)
            guard error == nil,
                  RAnalyticsDatabaseHelper.beginTransaction(connection: self.connection) else {
                return
            }

            let query = "insert into \(table) (data) values(?)"
            blobs.forEach { blob in

                var statement: SQlite3Pointer?
                guard RAnalyticsDatabaseHelper.prepareStatement(&statement, query: query, connection: self.connection) else {
                    return
                }

                blob.withUnsafeBytes { bytes -> Void in
                    if sqlite3_bind_blob(statement, 1, bytes.baseAddress, Int32(bytes.count), nil) == SQLITE_OK {
                        sqlite3_step(statement)
                        sqlite3_clear_bindings(statement)
                    }
                    sqlite3_reset(statement)
                    sqlite3_finalize(statement)
                }
            }

            if maximumNumberOfBlobs != 0 {
                let query = "delete from \(table) where id not in (select id from \(table) order by id desc limit \(maximumNumberOfBlobs))"
                sqlite3_exec(self.connection, query, nil, nil, nil)
            }

            RAnalyticsDatabaseHelper.commitTransaction(connection: self.connection)
        }
    }

    ///
    /// Try to fetch a number of blobs from a table, from the most ancient to the most recent.
    ///
    /// - Parameter maximumNumberOfBlobs:  Maximum number of blobs we want to read.
    /// - Parameter table:                 Name of the table.
    /// - Parameter completion:            Block to call upon completion.
    ///
    @objc public func fetchBlobs(_ maximumNumberOfBlobs: UInt,
                                 from table: String,
                                 then completion: @escaping (_ blobs: [Data]?, _ identifiers: [Int64]?) -> Void) {

        let callerQueue = OperationQueue.current
        queue.addOperation { [weak self] in
            guard let self = self else {
                return
            }

            var blobs = [Data]()
            blobs.reserveCapacity(Int(maximumNumberOfBlobs))
            var identifiers = [Int64]()
            identifiers.reserveCapacity(Int(maximumNumberOfBlobs))

            defer {
                callerQueue?.addOperation {
                    completion(blobs.isEmpty ? nil : blobs,
                               identifiers.isEmpty ? nil : identifiers)
                }
            }

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
    @objc(deleteBlobsWithIdentifiers:in:then:)
    public func deleteBlobs(identifiers: [Int64],
                            in table: String,
                            then completion: @escaping () -> Void) {

        let callerQueue = OperationQueue.current
        queue.addOperation { [weak self] in

            guard let self = self else {
                return
            }
            defer {
                callerQueue?.addOperation(completion)
            }

            let error = self.prepareTable(table)
            guard error == nil,
                  RAnalyticsDatabaseHelper.beginTransaction(connection: self.connection) else {
                return
            }

            let query = "delete from \(table) where id=?"
            identifiers.forEach { identifier in
                var statement: SQlite3Pointer?
                guard RAnalyticsDatabaseHelper.prepareStatement(&statement, query: query, connection: self.connection) else {
                    return
                }

                sqlite3_bind_int64(statement, 1, identifier)
                sqlite3_step(statement)
                sqlite3_clear_bindings(statement)
                sqlite3_reset(statement)
                sqlite3_finalize(statement)
            }

            RAnalyticsDatabaseHelper.commitTransaction(connection: self.connection)
        }
    }
}

private extension RAnalyticsDatabase {

    func prepareTable(_ table: String) -> NSError? {
        assert(OperationQueue.current == queue)
        guard !tables.contains(table) else {
            return nil
        }

        let query = "create table if not exists \(table) (id integer primary key, data blob)"
        guard sqlite3_exec(connection, query, nil, nil, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(connection))
            let message = "Failed to create table: \(errorMsg), code \(sqlite3_errcode(connection))"
            RLogger.error(message)
            return NSError(domain: RAnalyticsDatabase.RAnalyticsDBErrorDomain,
                           code: RAnalyticsDatabase.RAnalyticsDBTableCreationFailureErrorCode,
                           userInfo: [NSLocalizedDescriptionKey: message])
        }

        tables.insert(table)
        return nil
    }
}

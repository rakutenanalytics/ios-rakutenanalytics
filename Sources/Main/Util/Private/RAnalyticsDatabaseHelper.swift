import Foundation
import SQLite3

/// Serializes direct SQLite connection access across the database operation queue and test helpers.
enum SQLiteConnectionLock {
    private static var locks = [Int: NSLock]()
    private static let registryLock = NSLock()

    static func withLock<T>(_ connection: SQlite3Pointer, _ body: () throws -> T) rethrows -> T {
        let lock = lock(for: connection)
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    private static func lock(for connection: SQlite3Pointer) -> NSLock {
        let key = Int(bitPattern: connection)
        registryLock.lock()
        defer { registryLock.unlock() }
        if let existing = locks[key] {
            return existing
        }
        let lock = NSLock()
        locks[key] = lock
        return lock
    }
}

internal enum RAnalyticsDatabaseHelper {

    @discardableResult
    static func beginTransaction(connection: SQlite3Pointer) -> Bool {
        guard sqlite3_exec(connection, "begin exclusive transaction", nil, nil, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(connection))
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.databaseErrorDomain,
                                             code: ErrorCode.databaseBeginTransactionFailure.rawValue,
                                             description: ErrorDescription.databaseError,
                                             reason: "begin transaction failed with error \(errorMsg), code \(sqlite3_errcode(connection))"))
            return false
        }

        return true
    }

    @discardableResult
    static func commitTransaction(connection: SQlite3Pointer) -> Bool {
        guard sqlite3_exec(connection, "commit transaction", nil, nil, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(connection))
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.databaseErrorDomain,
                                             code: ErrorCode.databaseCommitTransactionFailure.rawValue,
                                             description: ErrorDescription.databaseError,
                                             reason: "commit transaction failed with error \(errorMsg), code \(sqlite3_errcode(connection))"))
            return false
        }

        return true
    }

    @discardableResult
    static func prepareStatement(_ statement: inout OpaquePointer?, query: String, connection: OpaquePointer) -> Bool {
        let result = sqlite3_prepare_v2(connection, query, -1, &statement, nil)
        if result != SQLITE_OK {
            let errorMsg = String(cString: sqlite3_errmsg(connection))
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.databaseErrorDomain,
                                             code: ErrorCode.databasePrepareStatementFailure.rawValue,
                                             description: ErrorDescription.databaseError,
                                             reason: "prepare statement failed with error \(errorMsg), code \(sqlite3_errcode(connection))"))
            return false
        }
        return true
    }
}

extension RAnalyticsDatabase {

    static func mkAnalyticsDBConnection(databaseName: String, databaseParentDirectory: FileManager.SearchPathDirectory) -> OpaquePointer? {
        var connection: OpaquePointer?
        let databaseFileURL = FileManager.default.databaseFileURL(databaseName: databaseName, databaseParentDirectory: databaseParentDirectory)

        let openFlags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        guard let databasePath = databaseFileURL,
              sqlite3_open_v2(databasePath.path, &connection, openFlags, nil) == SQLITE_OK else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.databaseErrorDomain,
                                             code: ErrorCode.databaseTableCreationFailure.rawValue,
                                             description: ErrorDescription.databaseError,
                                             reason: "Failed to open database: \(String(describing: databaseFileURL)). Using in-memory database."))

            return mkAnalyticsInMemoryDBConnection()
        }

        // Reduce flakiness under concurrent access (tests and SDK background work).
        sqlite3_busy_timeout(connection, 5_000)
        return connection
    }

    private static func mkAnalyticsInMemoryDBConnection() -> OpaquePointer? {
        var connection: OpaquePointer?
        let memFlags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_URI | SQLITE_OPEN_FULLMUTEX
        sqlite3_open_v2("file::memory:?cache=shared", &connection, memFlags, nil)

        sqlite3_busy_timeout(connection, 5_000)
        return connection
    }
}

import Foundation
import SQLite3

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
    static func prepareStatement(_ statement: inout SQlite3Pointer?, query: String, connection: SQlite3Pointer) -> Bool {
        guard sqlite3_prepare_v2(connection, query, -1, &statement, nil) == SQLITE_OK else {
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

    static func mkAnalyticsDBConnection(databaseName: String,
                                        databaseParentDirectory: FileManager.SearchPathDirectory) -> SQlite3Pointer? {
        var connection: SQlite3Pointer?
        let databaseFileURL = FileManager.default.databaseFileURL(databaseName: databaseName, databaseParentDirectory: databaseParentDirectory)

        guard let databasePath = databaseFileURL,
              sqlite3_open(databasePath.path, &connection) == SQLITE_OK,
              let databaseConnection = connection else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.databaseErrorDomain,
                                             code: ErrorCode.databaseTableCreationFailure.rawValue,
                                             description: ErrorDescription.databaseError,
                                             reason: "Failed to open database: \(String(describing: databaseFileURL)). Using in-memory database."))

            return mkAnalyticsInMemoryDBConnection()
        }

        return databaseConnection
    }

    private static func mkAnalyticsInMemoryDBConnection() -> SQlite3Pointer? {
        var connection: SQlite3Pointer?
        sqlite3_open("file::memory:?cache=shared", &connection)

        return connection
    }
}

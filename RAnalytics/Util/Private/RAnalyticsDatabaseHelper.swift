import Foundation
import SQLite3
import RLogger

internal enum RAnalyticsDatabaseHelper {

    @discardableResult
    static func beginTransaction(connection: SQlite3Pointer) -> Bool {
        guard sqlite3_exec(connection, "begin exclusive transaction", nil, nil, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(connection))
            RLogger.error("begin transaction failed with error \(errorMsg), code \(sqlite3_errcode(connection))")
            return false
        }

        return true
    }

    @discardableResult
    static func commitTransaction(connection: SQlite3Pointer) -> Bool {
        guard sqlite3_exec(connection, "commit transaction", nil, nil, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(connection))
            RLogger.error("commit transaction failed with error \(errorMsg), code \(sqlite3_errcode(connection))")
            return false
        }

        return true
    }

    @discardableResult
    static func prepareStatement(_ statement: inout SQlite3Pointer?, query: String, connection: SQlite3Pointer) -> Bool {
        guard sqlite3_prepare_v2(connection, query, -1, &statement, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(connection))
            RLogger.error("prepare statement failed with error \(errorMsg), code \(sqlite3_errcode(connection))")
            return false
        }

        return true
    }
}

extension RAnalyticsDatabase {

    static func mkAnalyticsDBConnection(databaseName: String) -> SQlite3Pointer? {

        let documentsDirectoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let databaseFilePath = documentsDirectoryPath?.appendingPathComponent(databaseName)

        var connection: SQlite3Pointer?
        guard let databasePath = databaseFilePath,
              sqlite3_open(databasePath.path, &connection) == SQLITE_OK,
              let databaseConnection = connection else {

            RLogger.error("Failed to open database: \(String(describing: databaseFilePath))")
            RLogger.error("Using in-memory database")
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

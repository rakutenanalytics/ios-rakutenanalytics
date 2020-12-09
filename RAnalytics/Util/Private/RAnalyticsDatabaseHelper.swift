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

@objc public extension RAnalyticsDatabase {

    @objc(mkAnalyticsDBConnectionWithName:)
    static func mkAnalyticsDBConnection(databaseName: String) -> SQlite3Pointer? {

        let documentsDirectoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let databasePath = documentsDirectoryPath?.appendingPathComponent(databaseName)

        var connection: SQlite3Pointer?
        guard sqlite3_open(databasePath?.path, &connection) == SQLITE_OK else {
            RLogger.error("Failed to open database: \(String(describing: databasePath))")
            sqlite3_close(connection)
            return nil
        }

        atexit_b {
            sqlite3_close(connection)
        }

        return connection
    }
}

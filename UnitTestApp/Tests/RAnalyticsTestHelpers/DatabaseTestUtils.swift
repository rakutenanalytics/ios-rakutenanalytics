import Foundation
import SQLite3
@testable import RakutenAnalytics

@objc public final class DatabaseTestUtils: NSObject {
    @objc public static func openRegularConnection() -> SQlite3Pointer? {
        return openConnection(SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX)
    }

    @objc public static func openReadonlyConnection() -> SQlite3Pointer? {
        return openConnection(SQLITE_OPEN_READONLY) // will fail if database is not created
    }

    @objc static func openConnection(_ flags: Int32) -> SQlite3Pointer? {
        var connection: SQlite3Pointer?

        // With 2 connections open we cannot use temporary databases because they are not shared.
        // Using memory databases allow sharing (cache=shared) but because of that the readonlyConnection is able to write the database.
        // https://stackoverflow.com/questions/40547077/is-it-possible-to-connect-to-an-in-memory-sqlite-db-in-read-only-mode
        assert(sqlite3_open_v2("file::memory:?cache=shared", &connection, flags, nil) == SQLITE_OK)
        if (flags & SQLITE_OPEN_READONLY) != 0 {
            assert(sqlite3_exec(connection, "PRAGMA query_only = 1", nil, nil, nil) == SQLITE_OK) // forces read-only behavior
        }

        return connection
    }

    public static func mkDatabase(connection: SQlite3Pointer) -> RAnalyticsDatabase {
        return RAnalyticsDatabase.database(connection: connection)
    }

    @objc public static func isTablePresent(_ table: String, connection: SQlite3Pointer) -> Bool {
        let query = "SELECT EXISTS(SELECT name FROM sqlite_master WHERE type='table' AND name='\(table)')"

        var statement: SQlite3Pointer?
        sqlite3_prepare_v3(connection, query, -1, 0, &statement, nil)
        sqlite3_step(statement)
        let tableCount = sqlite3_column_int(statement, 0)
        sqlite3_reset(statement)
        sqlite3_finalize(statement)

        return tableCount > 0
    }

    @objc public static func deleteTableIfExists(_ table: String, connection: SQlite3Pointer) {
        let query = "DROP TABLE IF EXISTS '\(table)'"

        var statement: SQlite3Pointer?
        sqlite3_prepare_v3(connection, query, -1, 0, &statement, nil)
        sqlite3_step(statement)
        sqlite3_reset(statement)
        sqlite3_finalize(statement)
    }

    @objc public static func fetchTableContents(_ table: String, connection: SQlite3Pointer, errorCallback: ((String) -> Void)? = nil) -> [Data] {
        var result = [Data]()
        let query = "select * from \(table)"

        var statement: SQlite3Pointer?
        
        let code = sqlite3_prepare_v3(connection, query, -1, 0, &statement, nil)
        switch code {
        case SQLITE_OK:
            while sqlite3_step(statement) == SQLITE_ROW {
                let bytes: UnsafeRawPointer = sqlite3_column_blob(statement, 1)
                let length = sqlite3_column_bytes(statement, 1)

                result.append(Data(bytes: bytes, count: Int(length)))
            }
            sqlite3_finalize(statement)
        default:
            var errorMessage = "DatabaseTestUtils: fetchTableContents() error. Unexpected sqlite code \(code)"
            if let sqliteError = sqlite3_errmsg(connection) {
                errorMessage += " - \(String(cString: sqliteError))"
            }
            errorCallback?(errorMessage)
        }

        return result
    }

    @objc public static func insert(blobs: [Data], table: String, connection: SQlite3Pointer) {
        assert(sqlite3_exec(connection, "begin exclusive transaction", nil, nil, nil) == SQLITE_OK)

        let createTableQuery = "create table if not exists \(table) (id integer primary key, data blob)"
        assert(sqlite3_exec(connection, createTableQuery, nil, nil, nil) == SQLITE_OK)

        let insertQuery = "insert into \(table) (data) values(?)"
        var statement: SQlite3Pointer?
        assert(sqlite3_prepare_v3(connection, insertQuery, -1, 0, &statement, nil) == SQLITE_OK)

        blobs.forEach { blob in
            blob.withUnsafeBytes { bytes -> Void in
                let status1 = sqlite3_bind_blob(statement, 1, bytes.baseAddress, Int32(blob.count), nil)
                let status2 = sqlite3_step(statement)
                let status3 = sqlite3_clear_bindings(statement)
                let status4 = sqlite3_reset(statement)
                assert([status1, status3, status4].allSatisfy({ $0 == SQLITE_OK }))
                assert(status2 == SQLITE_DONE)
            }
        }

        sqlite3_finalize(statement)
        assert(sqlite3_exec(connection, "commit transaction", nil, nil, nil) == SQLITE_OK)
    }

    @objc public static func databaseName(connection: SQlite3Pointer) -> String? {
        guard let dbName = sqlite3_db_filename(connection, nil) else {
            return nil
        }
        return String(cString: dbName)
    }
}

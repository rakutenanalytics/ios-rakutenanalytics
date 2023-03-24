import Foundation

protocol DatabaseConfigurable {
    var database: RAnalyticsDatabase { get }
    var tableName: String { get }
}

final class DatabaseConfiguration: DatabaseConfigurable {
    let database: RAnalyticsDatabase
    let tableName: String

    init(database: RAnalyticsDatabase, tableName: String) {
        self.database = database
        self.tableName = tableName
    }
}

enum DatabaseConfigurationHandler {
    /// Creates a database.
    ///
    /// - Parameter databaseName: The SQLite database name.
    /// - Parameter tableName: The SQLite table name.
    /// - Parameter databaseParentDirectory: The directory location of the SQLite database.
    ///
    /// - Returns: a new instance of `DatabaseConfiguration` or nil if the SQLite connection failed.
    static func create(databaseName: String,
                       tableName: String,
                       databaseParentDirectory: FileManager.SearchPathDirectory) -> DatabaseConfigurable? {
        guard let connection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: databaseName,
                                                                          databaseParentDirectory: databaseParentDirectory) else {
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.databaseErrorDomain,
                                             code: ErrorCode.databaseTableCreationFailure.rawValue,
                                             description: ErrorDescription.databaseError,
                                             reason: "\(databaseName): \(ErrorReason.databaseConnectionIsNil)"))
            return nil
        }
        let database = RAnalyticsDatabase.database(connection: connection)
        return DatabaseConfiguration(database: database, tableName: tableName)
    }
}

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

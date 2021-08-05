import Foundation

protocol DatabaseConfigurable {
    var database: RAnalyticsDatabase { get }
    var tableName: String { get }
}

final class DatabaseConfiguration: NSObject, DatabaseConfigurable {
    let database: RAnalyticsDatabase
    let tableName: String

    init(database: RAnalyticsDatabase, tableName: String) {
        self.database = database
        self.tableName = tableName
    }
}

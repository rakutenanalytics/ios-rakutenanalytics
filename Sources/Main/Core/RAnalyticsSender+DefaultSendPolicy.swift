import Foundation
import UIKit

extension RAnalyticsSender {
    convenience init(bundle: Bundle = .main,
                     endpoint: URL,
                     database: RAnalyticsDatabase,
                     databaseTable: String,
                     userStorageHandler: UserStorageHandleable) {
        self.init(endpoint: endpoint,
                  database: database,
                  databaseTable: databaseTable,
                  bundle: bundle,
                  session: URLSession.shared,
                  userStorageHandler: userStorageHandler,
                  allowsAnalyticsSend: AnalyticsSendPolicy.makeDefaultSendPredicate(for: bundle))
    }
}

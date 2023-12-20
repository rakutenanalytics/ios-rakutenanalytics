import Foundation

extension Array {

    /// Initializes JSON-formatted array of records from data array
    /// - Parameter ratDataRecords: array of RAT data records
    init?(ratDataRecords: [Data]) {
        self.init()
        /// Prepare the body of our RAT POST request as a JSON-formatted array of records.
        /// Note that the server doesn't accept pretty-formatted JSON.
        self = ratDataRecords.compactMap {
            try? JSONSerialization.jsonObject(with: $0, options: .init(rawValue: 0)) as? Element
        }
        if count != ratDataRecords.count {
            return nil
        }
    }
}

@objc public extension NSMutableArray {
    
    /// Initializes JSON-formatted array of records from data array
    /// - Parameter ratDataRecords: array of RAT data records
    convenience init(ratDataRecords: [NSData]) {
        self.init()
        /// Prepare the body of our RAT POST request as a JSON-formatted array of records.
        /// Note that the server doesn't accept pretty-formatted JSON.
        ratDataRecords.forEach { (dataRecord) in
            if let json = try? JSONSerialization.jsonObject(with: dataRecord as Data, options: .init(rawValue: 0)) {
                add(json)
            }
        }
    }
}

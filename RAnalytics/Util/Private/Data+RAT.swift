@objc public extension NSMutableData {

    /// Initializes RAT specific http body data from an array of dictionaries
    /// - Parameter ratRecords: array of RAT JSON-formatted records
    convenience init?(ratRecords: [NSDictionary]) {
        self.init()
        guard let initialData = "cpkg_none=".data(using: .utf8),
              let mainData = try? JSONSerialization.data(withJSONObject: ratRecords, options: .init(rawValue: 0)) else {
            return nil
        }
        append(initialData)
        append(mainData)
    }
}

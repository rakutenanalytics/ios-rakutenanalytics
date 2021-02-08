typealias JsonRecord = [String: AnyObject]

extension Data {

    /// Initializes RAT specific http body data from an array of dictionaries
    /// - Parameter ratJsonRecords: array of RAT JSON-formatted records
    init?(ratJsonRecords: [JsonRecord]) {
        self.init()
        guard !ratJsonRecords.isEmpty,
              let initialData = "cpkg_none=".data(using: .utf8),
              let mainData = try? JSONSerialization.data(withJSONObject: ratJsonRecords, options: .init(rawValue: 0)) else {
            return nil
        }
        append(initialData)
        append(mainData)
    }
}

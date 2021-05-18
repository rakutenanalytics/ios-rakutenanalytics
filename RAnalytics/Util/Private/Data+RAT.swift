typealias JsonRecord = [String: AnyObject]

extension Data {

    /// Initializes RAT specific http body data from an array of dictionaries
    /// - Parameters:
    ///     - ratJsonRecords: array of RAT JSON-formatted records
    ///     - internalSerialization: use the experimental internal JSON serialization or not. It fixes the float numbers decimals.
    init?(ratJsonRecords: [JsonRecord], internalSerialization: Bool = false) {
        self.init()
        guard !ratJsonRecords.isEmpty,
              let initialData = "cpkg_none=".data(using: .utf8) else {
            return nil
        }

        var mainData: Data?

        if internalSerialization {
            mainData = ratJsonRecords.toJsonString.data(using: .utf8)

        } else {
            mainData = try? JSONSerialization.data(withJSONObject: ratJsonRecords, options: .init(rawValue: 0))
        }

        guard let payloadData = mainData else {
            return nil
        }
        append(initialData)
        append(payloadData)
    }
}

private extension Array where Element == JsonRecord {
    var toJsonString: String {
        if isEmpty {
            return "[]"
        }
        let result = map { $0.toJsonString }
        return "[" + result.joined(separator: ", ") + "]"
    }
}

private extension Dictionary where Key == String, Value == AnyObject {
    var toJsonString: String {
        if isEmpty {
            return "{}"
        }

        let array = map { arg0 -> String in
            let (key, value) = arg0

            switch value {
            case _ as NSNull:
                return "\"\(key)\":null"
            case let value as JsonRecord:
                return "\"\(key)\":\(value.toJsonString)"
            case let value as [JsonRecord]:
                return "\"\(key)\":\(value.toJsonString)"
            case let value as String:
                return "\"\(key)\":\"\(value)\""
            case let value as Bool:
                return "\"\(key)\":\(value ? "true" : "false")"
            default:
                return "\"\(key)\":\(value)"
            }
        }

        return "{" + array.joined(separator: ", ") + "}"
    }
}

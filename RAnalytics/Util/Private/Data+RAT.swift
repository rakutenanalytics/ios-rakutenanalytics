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

private func convert(_ object: Any) -> Any {
    switch object {
    case _ as NSNull:
        return "null"

    case let value as JsonRecord:
        return value.toJsonString

    case let value as [AnyObject]:
        return value.toJsonString

    case let value as String:
        return "\"\(value)\""

    case let value as NSNumber:
        if CFGetTypeID(value) == CFBooleanGetTypeID() {
            return (value.boolValue ? "true" : "false")
        } else {
            return object
        }

    default:
        return object
    }
}

private extension Array where Element == JsonRecord {
    var toJsonString: String {
        if isEmpty {
            return "[]"
        }
        return "[" + map { $0.toJsonString }.joined(separator: ",") + "]"
    }
}

private extension Array where Element == AnyObject {
    var toJsonString: String {
        if isEmpty {
            return "[]"
        }
        let result = map { convert($0) as AnyObject }
        return "[\(result.map { "\($0)" }.joined(separator: ","))]"
    }
}

private extension Dictionary where Key == String, Value == AnyObject {
    var toJsonString: String {
        if isEmpty {
            return "{}"
        }

        let array = map { "\"\($0.key)\":\(convert($0.value))" }
        return "{" + array.joined(separator: ", ") + "}"
    }
}

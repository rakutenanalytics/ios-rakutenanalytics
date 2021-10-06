import Foundation

extension Dictionary {
    static func += (lhs: inout Dictionary, rhs: Dictionary) {
        for (key, value) in rhs {
            lhs[key] = value
        }
    }
}

extension Dictionary where Key == String, Value == String {
    var toRQuery: String {
        map { "\($0.key)=\($0.value)" }.joined(separator: "&")
    }
}

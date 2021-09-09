import Foundation

extension Dictionary where Key == String, Value == String {
    var toQuery: String {
        map { "\($0.key)=\($0.value)" }.joined(separator: "&")
    }
}

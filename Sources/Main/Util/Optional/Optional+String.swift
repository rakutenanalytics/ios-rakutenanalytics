import Foundation

extension Optional where Wrapped == String {
    /// Retrieve the hash value of a string.
    ///
    /// - Returns: The hash value or `0`.
    var safeHashValue: Int {
        guard let str = self else { return 0 }
        return str.hashValue
    }

    var isEmpty: Bool {
        guard let str = self else { return true }
        return str.isEmpty
    }

    /// Combine 2 optional strings
    ///
    /// - Returns: The combined string or ""
    func combine(with other: String?) -> String {
        switch (self, other) {
        case let (.some(first), .some(second)):
            return first + second
        case let (.some(first), _):
            return first
        case let (_, .some(second)):
            return second
        default:
            return ""
        }
    }
}

import Foundation

// MARK: - Encoding

extension CharacterSet {
    /// See https://www.ietf.org/rfc/rfc3986.txt section 2.2 and 3.4
    static let RFC3986ReservedCharacters = ":#[]@!$&'()*+,;="
    static let RFC3986UnreservedCharacters: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: RFC3986ReservedCharacters)
        return allowed
    }()
}

extension String {
    /// Encode a String following the RFC3986 specifications.
    ///
    /// - Returns: the RFC3986 encoded string.
    func addEncodingForRFC3986UnreservedCharacters() -> String? {
        addingPercentEncoding(withAllowedCharacters: CharacterSet.RFC3986UnreservedCharacters)
    }
}

// MARK: - Subscript

extension String {
    subscript (range: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[start ..< end])
    }
}

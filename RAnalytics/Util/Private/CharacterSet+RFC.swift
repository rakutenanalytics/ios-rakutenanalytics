import Foundation

/// - Note: This file has to be moved to https://github.com/rakutentech/ios-sdkutils

extension CharacterSet {
    /// See https://www.ietf.org/rfc/rfc3986.txt section 2.2 and 3.4
    static let RFC3986ReservedCharacters = ":#[]@!$&'()*+,;="
    static let RFC3986UnreservedCharacters: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: RFC3986ReservedCharacters)
        return allowed
    }()
}

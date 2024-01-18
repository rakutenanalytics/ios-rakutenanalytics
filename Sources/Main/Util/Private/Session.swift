import Foundation

enum Session {
    /// - Returns: the session identifier called `cks`.
    static func cks() -> String {
        NSUUID().uuidString
    }
}

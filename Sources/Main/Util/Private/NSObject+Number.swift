import Foundation

extension NSObject {
    /// - Returns: a positive number > 0 or `nil`.
    var positiveIntegerNumber: NSNumber? {
        switch self {
        case let object as Int where object > 0:
            return NSNumber(value: object)

        case let object as String:
            if let number = Int(object), number > 0 {
                return NSNumber(value: number)
            }
            return nil

        default:
            return nil
        }
    }
}

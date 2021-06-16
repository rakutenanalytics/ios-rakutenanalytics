import Foundation

extension Dictionary {
    static func += (lhs: inout Dictionary, rhs: Dictionary) {
        for (key, value) in rhs {
            lhs[key] = value
        }
    }
}

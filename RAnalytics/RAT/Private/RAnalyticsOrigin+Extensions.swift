import Foundation

extension RAnalyticsOrigin {
    var toString: String {
        switch self {
        case .internal:
            return "internal"

        case .external:
            return "external"

        case .push:
            return "push"
        }
    }
}

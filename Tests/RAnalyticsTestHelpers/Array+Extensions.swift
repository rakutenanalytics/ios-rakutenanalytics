import Foundation
@testable import RakutenAnalytics

public extension Array where Element == Data {
    func deserialize() -> [[String: Any]] {
        compactMap { data in
            try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: Any]
        }
    }
}

public extension Array where Element == [String: Any] {
    var pageVisitJSON: [String: Any]? {
        first(where: { $0[PayloadParameterKeys.etype] as? String == RAnalyticsEvent.Name.pageVisitForRAT })
    }

    var pushConversionJSON: [String: Any]? {
        first(where: { $0[PayloadParameterKeys.etype] as? String == RAnalyticsEvent.Name.pushNotificationConversion })
    }
}

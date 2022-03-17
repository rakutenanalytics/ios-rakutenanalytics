import Foundation
@testable import RAnalytics

extension Data {
    public var ratPayload: [[String: Any]]? {
        guard let str = String(data: self, encoding: .utf8),
              let jsonData = str[PayloadConstants.prefix.count..<str.count].data(using: .utf8) else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]]
    }
}

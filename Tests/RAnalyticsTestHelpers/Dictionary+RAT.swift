import Foundation
@testable import RAnalytics

public extension Dictionary where Key == String, Value == Any {
    var appInfo: String? {
        self[RAnalyticsConstants.appInfoKey] as? String
    }

    var sdkDependencies: [String: String] {
        reduce(into: [String: String]()) {
            if $1.key.hasPrefix(RAnalyticsConstants.sdkDependenciesPrefixKey), let value = $1.value as? String {
                $0[$1.key] = value
            }
        }
    }
}

import Foundation
import OSLog
import RakutenAnalytics

/// Shared Console + Instruments helpers for UIKit and SwiftUI viewable-impression samples.
enum ViewableImpressionsSampleMetrics {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "RAnalyticsSample"

    static let logger = Logger(subsystem: subsystem, category: "ViewableImpressionsPerf")
    static let signposter = OSSignposter(subsystem: subsystem, category: "ViewableImpressionsPerf")

    static func viewableItemCount(in eventParameters: [String: Any]?) -> Int {
        guard let eventParameters,
              let data = eventParameters[RAnalyticsEvent.Parameter.viewableData] as? [[String: Any]] else {
            return 0
        }
        return data.count
    }
}

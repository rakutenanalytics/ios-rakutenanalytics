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

    static func logRefreshCompleted(reason: String, listSize: Int, qualified: Int, durationMs: Double) {
        let durationLabel = String(format: "%.2f", durationMs)
        logger.notice(
            "viewable refresh reason=\(reason, privacy: .public) list_size=\(listSize, privacy: .public) "
                + "viewable_items_in_batch=\(qualified, privacy: .public) duration_ms=\(durationLabel, privacy: .public)"
        )
    }

    static func logPageVisitSent(qualified: Int) {
        logger.notice("sample RAT: sending pageVisit with viewable_data count=\(qualified, privacy: .public) (items in this event)")
    }

    static func logPageVisitSkipped() {
        logger.notice("sample RAT: no pageVisit sent — viewable_data empty (0 viewable impression items)")
    }
}

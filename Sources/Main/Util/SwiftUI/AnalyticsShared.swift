#if canImport(SwiftUI)
import Foundation
import SwiftUI

// MARK: - Shared Constants

@available(iOS 13.0, *)
public enum AnalyticsSwiftUIConstants {
    /// Minimum dwell time in seconds that items must remain visible to qualify as a viewable impression.
    public static let defaultMinimumDwellTime: TimeInterval = 1.5

    /// Minimum visibility percentage (0.0–1.0) required to consider an item visible. Default is 50%.
    public static let defaultMinimumVisibility: Double = 0.5

    /// Time window in seconds for batching viewable impression events before sending. A value of 0 disables batching.
    public static let viewableImpressionBatchWindow: TimeInterval = 0.0
}

#endif

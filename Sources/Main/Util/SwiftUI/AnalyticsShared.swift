#if canImport(SwiftUI)
import Foundation
import SwiftUI

// MARK: - Shared Constants

@available(iOS 13.0, *)
public enum AnalyticsSwiftUIConstants {
    public static let defaultMinimumDwellTime: TimeInterval = 1.5
    public static let defaultMinimumVisibility: Double = 0.5
    public static let viewableImpressionBatchWindow: TimeInterval = 0.0
}

#endif

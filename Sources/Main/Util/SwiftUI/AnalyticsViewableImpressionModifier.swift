#if canImport(SwiftUI)
import SwiftUI
import UIKit

// MARK: - Batching Coordinator

@available(iOS 13.0, *)
final class SwiftUIViewableImpressionBatchCoordinator {
    static let shared = SwiftUIViewableImpressionBatchCoordinator()

    private struct PendingImpression {
        let item: ViewableImpressionTrackable
        let dwellTime: TimeInterval
        let visibilityPercentage: Double
        let viewport: CGRect
        let itemPosition: Int
    }

    private let queue = DispatchQueue(label: "com.rakuten.analytics.swiftui.batching")
    private var pendingImpressions: [String: [PendingImpression]] = [:]
    private var scrollStopTimers: [String: DispatchWorkItem] = [:]

    private init() {}

    func registerImpression(item: ViewableImpressionTrackable,
                            dwellTime: TimeInterval,
                            visibilityPercentage: Double,
                            viewport: CGRect,
                            itemPosition: Int,
                            triggerReason: String,
                            scrollViewIdentifier: String?) {
        let batchKey = scrollViewIdentifier ?? "default"

        queue.async { [weak self] in
            guard let self = self else { return }

            let impression = PendingImpression(item: item,
                                               dwellTime: dwellTime,
                                               visibilityPercentage: visibilityPercentage,
                                               viewport: viewport,
                                               itemPosition: itemPosition)

            if self.pendingImpressions[batchKey] == nil {
                self.pendingImpressions[batchKey] = []
            }
            self.pendingImpressions[batchKey]?.append(impression)

            self.scrollStopTimers[batchKey]?.cancel()
            let task = DispatchWorkItem { [weak self] in
                self?.sendBatch(for: batchKey,
                                triggerReason: triggerReason,
                                scrollViewIdentifier: scrollViewIdentifier)
            }
            self.scrollStopTimers[batchKey] = task
            DispatchQueue.main.asyncAfter(deadline: .now() + AnalyticsSwiftUIConstants.viewableImpressionBatchWindow, execute: task)
        }
    }

    private func sendBatch(for batchKey: String,
                           triggerReason: String,
                           scrollViewIdentifier: String?) {
        queue.async { [weak self] in
            guard let self = self,
                  let impressions = self.pendingImpressions[batchKey],
                  !impressions.isEmpty else { return }

            self.pendingImpressions.removeValue(forKey: batchKey)
            self.scrollStopTimers.removeValue(forKey: batchKey)

            // SwiftUI doesn't have direct view access, so screenName is nil
            let items = impressions.map { ($0.item, $0.dwellTime, $0.visibilityPercentage, $0.viewport, $0.itemPosition, screenName: nil as String?) }
            _ = ViewableImpressionEventEmitter.trackBatch(
                items: items,
                triggerReason: triggerReason,
                scrollViewIdentifier: scrollViewIdentifier
            )
        }
    }
}

// MARK: - Manual Tracker (SwiftUI)

@available(iOS 13.0, *)
public final class SwiftUIManualViewableImpressionTracker: ObservableObject {
    private final class ManualTrackedItem {
        let item: ViewableImpressionTrackable
        var frame: CGRect
        var itemPosition: Int
        var isVisible: Bool
        var firstVisibleTime: Date
        var hasTriggered: Bool
        var visibilityPercentage: Double

        init(item: ViewableImpressionTrackable,
             frame: CGRect,
             itemPosition: Int,
             timestamp: Date = Date()) {
            self.item = item
            self.frame = frame
            self.itemPosition = itemPosition
            self.isVisible = false
            self.firstVisibleTime = timestamp
            self.hasTriggered = false
            self.visibilityPercentage = 0.0
        }

        var itemId: String { item.itemId }
    }

    public var minimumDwellTime: TimeInterval
    public var minimumVisibilityPercentage: Double
    public var scrollViewIdentifier: String?

    private let queue = DispatchQueue(label: "com.rakuten.analytics.swiftui.manualImpressions")
    private var itemsById: [String: ManualTrackedItem] = [:]

    public init(minimumDwellTime: TimeInterval = AnalyticsSwiftUIConstants.defaultMinimumDwellTime,
                minimumVisibilityPercentage: Double = AnalyticsSwiftUIConstants.defaultMinimumVisibility,
                scrollViewIdentifier: String? = nil) {
        self.minimumDwellTime = minimumDwellTime
        self.minimumVisibilityPercentage = minimumVisibilityPercentage
        self.scrollViewIdentifier = scrollViewIdentifier
    }

    public func update(item: ViewableImpressionTrackable, frame: CGRect, itemPosition: Int = 0) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let existing = self.itemsById[item.itemId] {
                existing.frame = frame
                existing.itemPosition = itemPosition
            } else {
                self.itemsById[item.itemId] = ManualTrackedItem(item: item, frame: frame, itemPosition: itemPosition)
            }
        }
    }

    public func unregister(itemId: String) {
        queue.async { [weak self] in
            self?.itemsById.removeValue(forKey: itemId)
        }
    }

    public func clear() {
        queue.async { [weak self] in
            self?.itemsById.removeAll()
        }
    }

    public func refreshState(viewport: CGRect? = nil,
                             viewportInsets: UIEdgeInsets? = nil,
                             triggerReason: String = "manual") {
        queue.async { [weak self] in
            guard let self = self else { return }

            let now = Date()
            let viewportRect = viewport ?? UIScreen.main.bounds
            let insetViewport = viewportInsets.map { viewportRect.inset(by: $0) } ?? viewportRect
            guard insetViewport.width > 0, insetViewport.height > 0 else { return }

            var qualifiedItems: [(item: ManualTrackedItem, dwellTime: TimeInterval, metrics: (visibility: Double, intersection: CGRect))] = []

            for (_, trackedItem) in self.itemsById {
                let intersection = insetViewport.intersection(trackedItem.frame)
                let area = trackedItem.frame.width * trackedItem.frame.height

                guard area > 0, !intersection.isNull else {
                    trackedItem.isVisible = false
                    trackedItem.firstVisibleTime = .distantPast
                    trackedItem.hasTriggered = false
                    trackedItem.visibilityPercentage = 0.0
                    continue
                }

                let visibility = (intersection.width * intersection.height) / area
                trackedItem.visibilityPercentage = Double(visibility)

                if visibility > self.minimumVisibilityPercentage {
                    if !trackedItem.isVisible {
                        trackedItem.isVisible = true
                        trackedItem.firstVisibleTime = now
                        trackedItem.hasTriggered = false
                    }

                    let visibleDuration = now.timeIntervalSince(trackedItem.firstVisibleTime)
                    if !trackedItem.hasTriggered, visibleDuration >= self.minimumDwellTime {
                        qualifiedItems.append((trackedItem, visibleDuration, (Double(visibility), intersection)))
                        trackedItem.hasTriggered = true
                    }
                } else {
                    trackedItem.isVisible = false
                    trackedItem.firstVisibleTime = .distantPast
                    trackedItem.hasTriggered = false
                }
            }

            guard !qualifiedItems.isEmpty else { return }

            // SwiftUI doesn't have direct view access, so screenName is nil
            let items: [(item: ViewableImpressionTrackable, dwellTime: TimeInterval, visibilityPercentage: Double, viewport: CGRect, itemPosition: Int, screenName: String?)] = qualifiedItems.map { qualifiedItem in
                (
                    item: qualifiedItem.item.item,
                    dwellTime: qualifiedItem.dwellTime,
                    visibilityPercentage: qualifiedItem.metrics.visibility,
                    viewport: qualifiedItem.metrics.intersection,
                    itemPosition: qualifiedItem.item.itemPosition,
                    screenName: nil
                )
            }

            _ = ViewableImpressionEventEmitter.trackBatch(
                items: items,
                triggerReason: triggerReason,
                scrollViewIdentifier: self.scrollViewIdentifier
            )
        }
    }
}

// MARK: - View Modifier

@available(iOS 13.0, *)
public struct AnalyticsManualViewableImpressionModifier<Item: ViewableImpressionTrackable>: ViewModifier {
    @ObservedObject private var tracker: SwiftUIManualViewableImpressionTracker
    private let item: Item
    private let itemPosition: Int

    public init(tracker: SwiftUIManualViewableImpressionTracker,
                item: Item,
                itemPosition: Int = 0) {
        self.tracker = tracker
        self.item = item
        self.itemPosition = itemPosition
    }

    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            tracker.update(item: item, frame: proxy.frame(in: .global), itemPosition: itemPosition)
                        }
                        .onDisappear {
                            tracker.unregister(itemId: item.itemId)
                        }
                        .onChange(of: proxy.frame(in: .global)) { newFrame in
                            tracker.update(item: item, frame: newFrame, itemPosition: itemPosition)
                        }
                }
            )
    }
}

@available(iOS 13.0, *)
public extension View {
    func analyticsViewableImpressionManual<Item: ViewableImpressionTrackable>(
        tracker: SwiftUIManualViewableImpressionTracker,
        item: Item,
        itemPosition: Int = 0
    ) -> some View {
        modifier(
            AnalyticsManualViewableImpressionModifier(
                tracker: tracker,
                item: item,
                itemPosition: itemPosition
            )
        )
    }
}

#endif

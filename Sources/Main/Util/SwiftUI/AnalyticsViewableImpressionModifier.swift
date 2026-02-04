#if canImport(SwiftUI)
import SwiftUI
import UIKit

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
    private let queue = DispatchQueue(label: "com.rakuten.analytics.swiftui.manualImpressions")
    private var itemsById: [String: ManualTrackedItem] = [:]
    private var pendingRefreshWorkItem: DispatchWorkItem?

    public init(minimumDwellTime: TimeInterval = AnalyticsSwiftUIConstants.defaultMinimumDwellTime,
                minimumVisibilityPercentage: Double = AnalyticsSwiftUIConstants.defaultMinimumVisibility) {
        self.minimumDwellTime = minimumDwellTime
        self.minimumVisibilityPercentage = minimumVisibilityPercentage
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

    /// Manually refresh visibility state once and receive results when ready.
    /// The completion is called immediately if items already qualify, or after
    /// the suggested dwell delay if items are still accumulating dwell time.
    public func refreshState(viewport: CGRect? = nil,
                             viewportInsets: UIEdgeInsets? = nil,
                             onResult: @escaping (_ eventParameters: [String: Any]?) -> Void) {
        let result = refreshStateInternal(
            viewport: viewport,
            viewportInsets: viewportInsets
        )
        deliverRefreshResult(result, onResult: onResult)
    }

    private func refreshStateInternal(viewport: CGRect?,
                                      viewportInsets: UIEdgeInsets?) -> ViewableImpressionRefreshResult {
        var result = ViewableImpressionRefreshResult.empty
        queue.sync {
            let now = Date()
            let viewportRect = viewport ?? UIScreen.main.bounds
            let insetViewport = viewportInsets.map { viewportRect.inset(by: $0) } ?? viewportRect
            guard insetViewport.width > 0, insetViewport.height > 0 else { return }

            var qualifiedItems: [(item: ViewableImpressionTrackable, dwellTime: TimeInterval, visibilityPercentage: Double, viewport: CGRect, itemPosition: Int, screenName: String?)] = []
            var nextRefreshDelay: TimeInterval?

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
                    if !trackedItem.hasTriggered {
                        if visibleDuration >= self.minimumDwellTime {
                            qualifiedItems.append(
                                (
                                    item: trackedItem.item,
                                    dwellTime: visibleDuration,
                                    visibilityPercentage: Double(visibility),
                                    viewport: intersection,
                                    itemPosition: trackedItem.itemPosition,
                                    screenName: nil
                                )
                            )
                            trackedItem.hasTriggered = true
                        } else if self.minimumDwellTime > 0 {
                            let remaining = self.minimumDwellTime - visibleDuration
                            if remaining > 0 {
                                nextRefreshDelay = min(nextRefreshDelay ?? remaining, remaining)
                            }
                        }
                    }
                } else {
                    trackedItem.isVisible = false
                    trackedItem.firstVisibleTime = .distantPast
                    trackedItem.hasTriggered = false
                }
            }

            let refreshAfterDwell: (() -> ViewableImpressionRefreshResult)? = nextRefreshDelay == nil ? nil : { [weak self] in
                guard let self = self else { return .empty }
                return self.refreshStateInternal(
                    viewport: viewport,
                    viewportInsets: viewportInsets
                )
            }

            let eventTimestamp = NSNumber(value: Date().toRatTimestamp)
            let eventData = ViewableImpressionEventEmitter.buildItemPayloads(
                items: qualifiedItems,
                eventTimestamp: eventTimestamp
            )
            let eventParameters = ViewableImpressionEventEmitter.buildEventParameters(
                viewableData: eventData
            )

            result = ViewableImpressionRefreshResult(
                eventData: eventData,
                refreshAfterDelay: nextRefreshDelay,
                refreshAfterDwell: refreshAfterDwell,
                eventParameters: eventParameters
            )
        }
        return result
    }

    private func deliverRefreshResult(_ result: ViewableImpressionRefreshResult,
                                      onResult: @escaping (_ eventParameters: [String: Any]?) -> Void) {
        if !result.eventData.isEmpty || result.refreshAfterDelay == nil {
            pendingRefreshWorkItem?.cancel()
            pendingRefreshWorkItem = nil
            DispatchQueue.main.async {
                onResult(result.eventParameters)
            }
            return
        }

        guard let delay = result.refreshAfterDelay,
              let refreshAfterDwell = result.refreshAfterDwell else {
            pendingRefreshWorkItem?.cancel()
            pendingRefreshWorkItem = nil
            DispatchQueue.main.async {
                onResult(result.eventParameters)
            }
            return
        }

        pendingRefreshWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            let followUp = refreshAfterDwell()
            onResult(followUp.eventParameters)
        }
        pendingRefreshWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
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

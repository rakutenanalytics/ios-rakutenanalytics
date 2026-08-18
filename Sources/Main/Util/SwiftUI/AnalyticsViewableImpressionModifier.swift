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

    /// Updates the frame and position of a trackable item, or registers it if not yet tracked.
    /// Call this when the item's on-screen bounds change (e.g. from a GeometryReader).
    ///
    /// - Parameters:
    ///   - item: The trackable item to update.
    ///   - frame: The item's current frame in screen coordinates.
    ///   - itemPosition: Optional position index for ordering (default: `0`).
    public func update(item: ViewableImpressionTrackable, frame: CGRect, itemPosition: Int = 0) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let existing = self.itemsById[item.itemId] else {
                self.itemsById[item.itemId] = ManualTrackedItem(item: item, frame: frame, itemPosition: itemPosition)
                return
            }
            existing.frame = frame
            existing.itemPosition = itemPosition
        }
    }

    /// Stops tracking the item with the given identifier.
    /// Call this when the item is removed from the view hierarchy (e.g. in onDisappear).
    ///
    /// - Parameter itemId: The unique identifier of the item to stop tracking.
    public func unregister(itemId: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            _ = self.itemsById.removeValue(forKey: itemId)
        }
    }

    /// Removes all tracked items from the tracker.
    /// Use this to reset tracking state when the view hierarchy changes significantly.
    public func clear() {
        queue.async { [weak self] in
            self?.itemsById.removeAll()
        }
    }

    /// Manually refresh visibility state once and receive results when ready.
    /// The completion is called immediately if items already qualify, or after
    /// the suggested dwell delay if items are still accumulating dwell time.
    ///
    /// - Parameters:
    ///   - viewport: Region in screen coordinates used for visibility; defaults to the active window scene screen bounds.
    ///   - viewportInsets: Insets applied to `viewport` before intersecting item frames.
    ///   - onResult: Called on the main queue with event parameters when viewable data is ready, or `nil` if none.
    public func refreshState(viewport: CGRect? = nil,
                             viewportInsets: UIEdgeInsets? = nil,
                             onResult: @escaping (_ eventParameters: [String: Any]?) -> Void) {
        let result = refreshStateInternal(
            viewport: viewport,
            viewportInsets: viewportInsets
        )
        ViewableImpressionRefreshScheduler.deliver(
            result: result,
            pendingWorkItem: &pendingRefreshWorkItem,
            onResult: onResult
        )
    }

    private func refreshStateInternal(viewport: CGRect?,
                                      viewportInsets: UIEdgeInsets?) -> ViewableImpressionRefreshResult {
        var result = ViewableImpressionRefreshResult.empty
        queue.sync {
            let now = Date()
            let viewportRect = viewport ?? UIScreen.screenableFromScene.bounds
            let insetViewport = viewportInsets.map { viewportRect.inset(by: $0) } ?? viewportRect
            guard insetViewport.width > 0, insetViewport.height > 0 else { return }

            var qualifiedItems: [ViewableImpressionQualifiedItemData] = []
            var nextRefreshDelay: TimeInterval?

            for (_, trackedItem) in self.itemsById {
                let intersection = insetViewport.intersection(trackedItem.frame)
                let area = trackedItem.frame.width * trackedItem.frame.height

                let visibility: Double? = if area <= 0 || intersection.isNull {
                    nil
                } else {
                    (intersection.width * intersection.height) / area
                }

                let state = ViewableImpressionStateAdapter(
                    item: trackedItem.item,
                    itemPosition: trackedItem.itemPosition,
                    screenName: nil,
                    getIsVisible: { trackedItem.isVisible },
                    setIsVisible: { trackedItem.isVisible = $0 },
                    getFirstVisibleTime: { trackedItem.firstVisibleTime },
                    setFirstVisibleTime: { trackedItem.firstVisibleTime = $0 },
                    getHasTriggered: { trackedItem.hasTriggered },
                    setHasTriggered: { trackedItem.hasTriggered = $0 },
                    getVisibilityPercentage: { trackedItem.visibilityPercentage },
                    setVisibilityPercentage: { trackedItem.visibilityPercentage = $0 }
                )
                let result = ViewableImpressionTrackStateProcessor.process(
                    item: state,
                    visibility: visibility,
                    now: now,
                    minimumVisibility: self.minimumVisibilityPercentage,
                    minimumDwell: self.minimumDwellTime
                )

                if let qualified = result.qualified {
                    qualifiedItems.append(qualified)
                } else if let remaining = result.remaining, remaining > 0 {
                    nextRefreshDelay = min(nextRefreshDelay ?? remaining, remaining)
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
}

// MARK: - View Modifier

/// Quantized global frame so `onChange` fires more reliably than raw `CGRect` during `LazyVStack` layout.
private struct ViewableGlobalFrameToken: Equatable {
    let minX: Int
    let minY: Int
    let width: Int
    let height: Int

    init(_ frame: CGRect) {
        func q(_ v: CGFloat) -> Int { Int((v * 4).rounded()) }
        minX = q(frame.minX)
        minY = q(frame.minY)
        width = q(frame.width)
        height = q(frame.height)
    }
}

private extension View {
    /// Two-parameter `onChange` is iOS/tvOS 17+; single-parameter form is iOS/tvOS 14–16.
    @ViewBuilder
    func onViewableGlobalFrameTokenChange(
        _ token: ViewableGlobalFrameToken,
        perform update: @escaping () -> Void
    ) -> some View {
        if #available(iOS 17.0, tvOS 17.0, *) {
            self.onChange(of: token) { _, _ in update() }
        } else if #available(iOS 14.0, tvOS 14.0, *) {
            self.onChange(of: token) { _ in update() }
        } else {
            self
        }
    }
}

@available(iOS 13.0, *)
public struct AnalyticsManualImpressionModifier<Item: ViewableImpressionTrackable>: ViewModifier {
    @ObservedObject private var tracker: SwiftUIManualViewableImpressionTracker
    private let item: Item
    private let itemPosition: Int

    /// - Parameters:
    ///   - tracker: The manual viewable-impression tracker that stores item geometry and qualification state.
    ///   - item: The trackable model for this row or cell.
    ///   - itemPosition: Zero-based position among tracked items for analytics ordering.
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
                    let frame = proxy.frame(in: .global)
                    Color.clear
                        .onAppear {
                            tracker.update(item: item, frame: frame, itemPosition: itemPosition)
                        }
                        .onDisappear {
                            tracker.unregister(itemId: item.itemId)
                        }
                        .onViewableGlobalFrameTokenChange(ViewableGlobalFrameToken(frame)) {
                            tracker.update(item: item, frame: frame, itemPosition: itemPosition)
                        }
                }
            )
    }
}

@available(iOS 13.0, *)
public extension View {
    /// Tracks viewable impressions for this view using manual geometry updates and `tracker.refreshState`.
    ///
    /// - Parameters:
    ///   - tracker: Shared ``SwiftUIManualViewableImpressionTracker`` for the screen or list.
    ///   - item: Trackable metadata for this view.
    ///   - itemPosition: Zero-based index for ordering in emitted analytics.
    func analyticsViewableImpressionManual<Item: ViewableImpressionTrackable>(
        tracker: SwiftUIManualViewableImpressionTracker,
        item: Item,
        itemPosition: Int = 0
    ) -> some View {
        modifier(
            AnalyticsManualImpressionModifier(
                tracker: tracker,
                item: item,
                itemPosition: itemPosition
            )
        )
    }
}

#endif

import Foundation
import UIKit

// MARK: - Public Protocols

/// Protocol for items that can be tracked for viewable impressions.
public protocol ViewableImpressionTrackable {
    /// Unique identifier for the item.
    var itemId: String { get }

    /// Title/name of the item.
    var itemTitle: String { get }

    /// Description of the item.
    var itemDescription: String? { get }

    /// Category of the item.
    var itemCategory: String? { get }

    /// Genre of the item.
    var itemGenre: String? { get }

    /// Price of the item.
    var itemPrice: String? { get }
}

struct ViewableImpressionRefreshResult {
    let eventData: [[String: Any]]
    let refreshAfterDelay: TimeInterval?
    let refreshAfterDwell: (() -> ViewableImpressionRefreshResult)?
    let eventParameters: [String: Any]?

    init(eventData: [[String: Any]],
         refreshAfterDelay: TimeInterval?,
         refreshAfterDwell: (() -> ViewableImpressionRefreshResult)?,
         eventParameters: [String: Any]?) {
        self.eventData = eventData
        self.refreshAfterDelay = refreshAfterDelay
        self.refreshAfterDwell = refreshAfterDwell
        self.eventParameters = eventParameters
    }

    static let empty = ViewableImpressionRefreshResult(
        eventData: [],
        refreshAfterDelay: nil,
        refreshAfterDwell: nil,
        eventParameters: nil
    )
}

// MARK: - Internal Models

private final class ManualTrackedItem {
    let item: ViewableImpressionTrackable
    weak var view: UIView?
    var itemPosition: Int
    var visibilityPercentage: Double
    var firstVisibleTime: Date
    var hasTriggeredViewableImpression: Bool
    var isVisible: Bool

    init(item: ViewableImpressionTrackable, view: UIView, itemPosition: Int, visibilityPercentage: Double, timestamp: Date = Date(), hasTriggered: Bool = false, isVisible: Bool = false) {
        self.item = item
        self.view = view
        self.itemPosition = itemPosition
        self.visibilityPercentage = visibilityPercentage
        self.firstVisibleTime = timestamp
        self.hasTriggeredViewableImpression = hasTriggered
        self.isVisible = isVisible
    }

    var itemId: String { item.itemId }
}

// MARK: - Viewable Impression Tracker (Manual)

@objc public final class ViewableImpressionTracker: NSObject {
    /// Minimum dwell time in seconds that items must remain visible.
    @objc public var minimumDwellTime: TimeInterval = 1.5

    /// Minimum visibility percentage required to consider an item visible. Default is 50%.
    @objc public var minimumVisibilityPercentage: Double = 0.5

    /// Indicates if tracking is currently active.
    @objc public private(set) var isEnabled: Bool = false

    // MARK: Private State

    private weak var viewportContextView: UIView?
    private let synchronizationQueue = DispatchQueue(label: "com.rakuten.analytics.viewableImpressions", attributes: .concurrent)
    private var manualItemsStorage: [String: ManualTrackedItem] = [:]
    private var pendingRefreshWorkItem: DispatchWorkItem?
    private var manualItemsByIdentifier: [String: ManualTrackedItem] {
        get { synchronizationQueue.sync { manualItemsStorage } }
        set { synchronizationQueue.sync(flags: .barrier) { self.manualItemsStorage = newValue } }
    }

    // MARK: Initialization

    /// Create a tracker without a specific viewport context.
    /// You can pass a viewport later via `refreshState(viewportView:onResult:)`.
    @objc public override init() {
        self.viewportContextView = nil
        super.init()
    }

    /// Create a tracker with an optional viewport context view.
    @objc public init(view: UIView?) {
        self.viewportContextView = view
        super.init()
    }

    /// Backwards-compatible initializer for scroll-view contexts.
    @objc public convenience init(scrollView: UIScrollView) {
        self.init(view: scrollView)
    }

    // MARK: Public API

    /// Enable viewable impression tracking.
    @objc public func enableTracking() {
        guard !isEnabled else { return }
        isEnabled = true
    }

    /// Disable viewable impression tracking.
    @objc public func disableTracking() {
        guard isEnabled else { return }
        isEnabled = false
        pendingRefreshWorkItem?.cancel()
        pendingRefreshWorkItem = nil
        synchronizationQueue.sync(flags: .barrier) {
            manualItemsStorage.removeAll()
        }
    }

    /// Register a view manually for viewable impression tracking.
    /// Call `refreshState(onResult:)` to evaluate visibility and receive results.
    public func track(view: UIView, item: ViewableImpressionTrackable, itemPosition: Int = 0) {
        guard isEnabled else { return }

        executeOnMain {
            self.synchronizationQueue.sync(flags: .barrier) {
                let reusedItemIds = self.manualItemsStorage
                    .filter { $0.value.view === view && $0.key != item.itemId }
                    .map { $0.key }
                reusedItemIds.forEach { self.manualItemsStorage.removeValue(forKey: $0) }

                self.manualItemsStorage[item.itemId] = ManualTrackedItem(
                    item: item,
                    view: view,
                    itemPosition: itemPosition,
                    visibilityPercentage: 0.0
                )
            }
        }
    }

    /// Unregister a manually tracked item by ID.
    public func untrack(itemId: String) {
        performBarrier {
            self.manualItemsStorage.removeValue(forKey: itemId)
        }
    }

    /// Clears all manually tracked items.
    public func clearManualTracking() {
        performBarrier {
            self.manualItemsStorage.removeAll()
        }
    }

    /// Manually refresh visibility state once and receive results when ready.
    /// The completion is called immediately if items already qualify, or after
    /// the suggested dwell delay if items are still accumulating dwell time.
    public func refreshState(viewportView: UIView? = nil,
                             viewportInsets: UIEdgeInsets = .zero,
                             onResult: @escaping (_ eventParameters: [String: Any]?) -> Void) {
        let result = refreshStateInternal(
            viewportView: viewportView,
            viewportInsets: viewportInsets
        )
        deliverRefreshResult(result, onResult: onResult)
    }

    // MARK: - Private Helpers

    private func visibilityMetrics(for view: UIView,
                                   in viewportView: UIView?,
                                   viewportInsets: UIEdgeInsets) -> (visibility: Double, intersection: CGRect, timestamp: Date)? {
        guard view.window != nil,
              !view.isHidden,
              view.alpha > 0.01,
              view.bounds.width > 0,
              view.bounds.height > 0 else {
            return nil
        }

        let viewport = viewportView?.bounds ?? UIScreen.main.bounds
        let insetViewport = viewport.inset(by: viewportInsets)
        guard insetViewport.width > 0, insetViewport.height > 0 else { return nil }

        let rectInViewport = view.convert(view.bounds, to: viewportView)
        let intersection = rectInViewport.intersection(insetViewport)
        guard !intersection.isNull else { return nil }

        let area = rectInViewport.width * rectInViewport.height
        guard area > 0 else { return nil }

        let visibility = (intersection.width * intersection.height) / area
        return (Double(visibility), intersection, Date())
    }

    private func executeOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }

    private func performBarrier(_ work: () -> Void) {
        synchronizationQueue.sync(flags: .barrier, execute: work)
    }

    private func refreshStateInternal(viewportView: UIView?,
                                      viewportInsets: UIEdgeInsets) -> ViewableImpressionRefreshResult {
        guard isEnabled else { return .empty }

        var result = ViewableImpressionRefreshResult.empty
        executeOnMain {
            let effectiveViewportView = viewportView ?? self.viewportContextView
            let now = Date()
            var qualifiedItems: [(item: ViewableImpressionTrackable, dwellTime: TimeInterval, visibilityPercentage: Double, viewport: CGRect, itemPosition: Int, screenName: String?)] = []
            var itemsToRemove: [String] = []
            var nextRefreshDelay: TimeInterval?

            let snapshot = self.manualItemsByIdentifier
            for (itemId, trackedItem) in snapshot {
                guard let view = trackedItem.view else {
                    itemsToRemove.append(itemId)
                    continue
                }

                guard view.isValidForTracking else {
                    trackedItem.isVisible = false
                    trackedItem.firstVisibleTime = .distantPast
                    trackedItem.hasTriggeredViewableImpression = false
                    trackedItem.visibilityPercentage = 0.0
                    continue
                }

                guard let metrics = self.visibilityMetrics(for: view, in: effectiveViewportView, viewportInsets: viewportInsets) else {
                    trackedItem.isVisible = false
                    trackedItem.firstVisibleTime = .distantPast
                    trackedItem.hasTriggeredViewableImpression = false
                    continue
                }

                let evaluation = ViewableImpressionEvaluation.evaluate(
                    visibility: metrics.visibility,
                    isVisible: trackedItem.isVisible,
                    firstVisibleTime: trackedItem.firstVisibleTime,
                    hasTriggered: trackedItem.hasTriggeredViewableImpression,
                    minimumVisibility: self.minimumVisibilityPercentage,
                    minimumDwell: self.minimumDwellTime,
                    now: now
                )

                trackedItem.isVisible = evaluation.isVisible
                trackedItem.firstVisibleTime = evaluation.firstVisibleTime
                trackedItem.hasTriggeredViewableImpression = evaluation.hasTriggered
                trackedItem.visibilityPercentage = metrics.visibility

                if evaluation.qualifies {
                    let screenName = trackedItem.view?.findViewController().map { String(describing: type(of: $0)) }
                    let visibleDuration = now.timeIntervalSince(trackedItem.firstVisibleTime)
                    qualifiedItems.append(
                        (
                            item: trackedItem.item,
                            dwellTime: visibleDuration,
                            visibilityPercentage: metrics.visibility,
                            viewport: metrics.intersection,
                            itemPosition: trackedItem.itemPosition,
                            screenName: screenName
                        )
                    )
                } else if let remaining = evaluation.remainingDwell, remaining > 0 {
                    nextRefreshDelay = min(nextRefreshDelay ?? remaining, remaining)
                }
            }

            if !itemsToRemove.isEmpty {
                self.synchronizationQueue.sync(flags: .barrier) {
                    itemsToRemove.forEach { self.manualItemsStorage.removeValue(forKey: $0) }
                }
            }

            let refreshAfterDwell: (() -> ViewableImpressionRefreshResult)? = nextRefreshDelay == nil ? nil : { [weak self] in
                guard let self = self else { return .empty }
                return self.refreshStateInternal(
                    viewportView: viewportView,
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

enum ViewableImpressionEventEmitter {
    static func buildItemPayloads(items: [(item: ViewableImpressionTrackable, dwellTime: TimeInterval, visibilityPercentage: Double, viewport: CGRect, itemPosition: Int, screenName: String?)],
                                  eventTimestamp: NSNumber) -> [[String: Any]] {
        guard !items.isEmpty else { return [] }
        return items.map { itemData in
            var itemParams: [String: Any] = [
                RAnalyticsEvent.Parameter.itemId: itemData.item.itemId,
                RAnalyticsEvent.Parameter.itemTitle: itemData.item.itemTitle,
                RAnalyticsEvent.Parameter.itemPosition: itemData.itemPosition,
                RAnalyticsEvent.Parameter.visibilityPercentage: itemData.visibilityPercentage,
                RAnalyticsEvent.Parameter.dwellTime: itemData.dwellTime,
                RAnalyticsEvent.Parameter.viewableImpressionTimestamp: eventTimestamp
                // viewport_bounds intentionally omitted from manual payload
            ]

            if let description = itemData.item.itemDescription {
                itemParams[RAnalyticsEvent.Parameter.itemDescription] = description
            }

            if let category = itemData.item.itemCategory {
                itemParams[RAnalyticsEvent.Parameter.itemCategory] = category
            }

            if let genre = itemData.item.itemGenre {
                itemParams[RAnalyticsEvent.Parameter.itemGenre] = genre
            }

            if let price = itemData.item.itemPrice {
                itemParams[RAnalyticsEvent.Parameter.itemPrice] = price
            }

            if let screenName = itemData.screenName, !screenName.isEmpty {
                itemParams[RAnalyticsEvent.Parameter.screenName] = screenName
            }

            return itemParams
        }
    }

    static func buildEventParameters(viewableData: [[String: Any]]) -> [String: Any]? {
        guard !viewableData.isEmpty else { return nil }
        return [
            RAnalyticsEvent.Parameter.viewableData: viewableData
        ]
    }

}

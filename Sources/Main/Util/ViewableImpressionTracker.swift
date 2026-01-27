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
    private var manualItemsByIdentifier: [String: ManualTrackedItem] {
        get { synchronizationQueue.sync { manualItemsStorage } }
        set { synchronizationQueue.sync(flags: .barrier) { self.manualItemsStorage = newValue } }
    }

    // MARK: Initialization

    /// Create a tracker without a specific viewport context.
    /// You can pass a viewport later via `refreshState(viewportView:)`.
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
        synchronizationQueue.sync(flags: .barrier) {
            manualItemsStorage.removeAll()
        }
    }

    /// Register a view manually for viewable impression tracking.
    /// Call `refreshState()` to evaluate visibility and emit events.
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

    /// Manually refresh visibility state and emit impressions when qualified.
    /// - Parameters:
    ///   - viewportView: Optional viewport view to evaluate visibility against (default: screen).
    ///   - viewportInsets: Optional insets to apply to the viewport.
    ///   - triggerReason: Optional reason for the impression trigger (default: "manual").
    public func refreshState(viewportView: UIView? = nil, viewportInsets: UIEdgeInsets = .zero, triggerReason: String = "manual") {
        guard isEnabled else { return }

        executeOnMain {
            let effectiveViewportView = viewportView ?? self.viewportContextView
            let now = Date()
            var qualifiedItems: [(item: ManualTrackedItem, dwellTime: TimeInterval, metrics: (visibility: Double, intersection: CGRect, timestamp: Date))] = []
            var itemsToRemove: [String] = []

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

                if metrics.visibility > self.minimumVisibilityPercentage {
                    if !trackedItem.isVisible {
                        trackedItem.isVisible = true
                        trackedItem.firstVisibleTime = now
                        trackedItem.hasTriggeredViewableImpression = false
                    }

                    trackedItem.visibilityPercentage = metrics.visibility

                    let visibleDuration = now.timeIntervalSince(trackedItem.firstVisibleTime)
                    if !trackedItem.hasTriggeredViewableImpression,
                       visibleDuration >= self.minimumDwellTime {
                        qualifiedItems.append((trackedItem, visibleDuration, metrics))
                        trackedItem.hasTriggeredViewableImpression = true
                    }
                } else {
                    trackedItem.isVisible = false
                    trackedItem.firstVisibleTime = .distantPast
                    trackedItem.hasTriggeredViewableImpression = false
                    trackedItem.visibilityPercentage = metrics.visibility
                }
            }

            if !itemsToRemove.isEmpty {
                self.synchronizationQueue.sync(flags: .barrier) {
                    itemsToRemove.forEach { self.manualItemsStorage.removeValue(forKey: $0) }
                }
            }

            if !qualifiedItems.isEmpty {
                let scrollViewIdentifier = (effectiveViewportView as? UIScrollView)?.scrollViewIdentifier
                let items: [(item: ViewableImpressionTrackable, dwellTime: TimeInterval, visibilityPercentage: Double, viewport: CGRect, itemPosition: Int, screenName: String?)] = qualifiedItems.map { qualifiedItem in
                    let screenName = qualifiedItem.item.view?.findViewController().map { String(describing: type(of: $0)) }
                    return (
                        item: qualifiedItem.item.item,
                        dwellTime: qualifiedItem.dwellTime,
                        visibilityPercentage: qualifiedItem.metrics.visibility,
                        viewport: qualifiedItem.metrics.intersection,
                        itemPosition: qualifiedItem.item.itemPosition,
                        screenName: screenName
                    )
                }

                _ = ViewableImpressionEventEmitter.trackBatch(
                    items: items,
                    triggerReason: triggerReason,
                    scrollViewIdentifier: scrollViewIdentifier
                )
            }
        }
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
}

enum ViewableImpressionEventEmitter {
    @discardableResult
    static func trackBatch(items: [(item: ViewableImpressionTrackable, dwellTime: TimeInterval, visibilityPercentage: Double, viewport: CGRect, itemPosition: Int, screenName: String?)],
                          triggerReason: String,
                          scrollViewIdentifier: String?) -> Bool {
        guard !items.isEmpty else { return false }

        let eventDate = Date()

        let itemsData: [[String: Any]] = items.map { itemData in
            var itemParams: [String: Any] = [
                RAnalyticsEvent.Parameter.itemId: itemData.item.itemId,
                RAnalyticsEvent.Parameter.itemTitle: itemData.item.itemTitle,
                RAnalyticsEvent.Parameter.itemPosition: itemData.itemPosition,
                RAnalyticsEvent.Parameter.visibilityPercentage: itemData.visibilityPercentage,
                RAnalyticsEvent.Parameter.dwellTime: itemData.dwellTime,
                RAnalyticsEvent.Parameter.viewportBounds: [
                    "x": itemData.viewport.origin.x,
                    "y": itemData.viewport.origin.y,
                    "width": itemData.viewport.width,
                    "height": itemData.viewport.height
                ]
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

            if !triggerReason.isEmpty {
                itemParams[RAnalyticsEvent.Parameter.triggerReason] = triggerReason
            }

            return itemParams
        }

        var topLevelObject: [String: Any] = [
            "event_data": itemsData,
            "item_count": items.count,
            RAnalyticsEvent.Parameter.viewableImpressionTimestamp: eventDate.toRatTimestamp
        ]

        if let scrollViewIdentifier = scrollViewIdentifier {
            topLevelObject[RAnalyticsEvent.Parameter.scrollViewIdentifier] = scrollViewIdentifier
        }

        let customEventParameters: [String: Any] = [
            RAnalyticsEvent.Parameter.eventName: RAnalyticsEvent.Name.viewableImpression,
            RAnalyticsEvent.Parameter.topLevelObject: topLevelObject
        ]

        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom, parameters: customEventParameters)
        let success = event.track()
        if success {
            RLogger.debug(message: "✅ VIEWABLE IMPRESSIONS: \(items.count) item(s), reason: \(triggerReason)")
            items.forEach { item in
                let visibilityStr = String(format: "%.0f%%", item.visibilityPercentage * 100)
                let dwellStr = String(format: "%.2fs", item.dwellTime)
                RLogger.debug(message: "   • \(item.item.itemTitle) (ID: \(item.item.itemId)) - Dwell: \(dwellStr), Visibility: \(visibilityStr)")
            }
        } else {
            RLogger.debug(message: "❌ Failed to send viewable impressions, reason: \(triggerReason)")
        }
        return success
    }
}

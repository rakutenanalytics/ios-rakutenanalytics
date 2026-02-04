import UIKit
import Testing
@preconcurrency @testable import RakutenAnalytics

private struct MockTrackableItem: ViewableImpressionTrackable {
    let itemId: String
    let itemTitle: String
    let itemDescription: String? = nil
    let itemCategory: String? = nil
    let itemGenre: String? = nil
    let itemPrice: String? = nil
}

@Suite("ViewableImpressionTracker")
struct ViewableImpressionTrackerTests {
    @MainActor
    private static func eventData(from eventParameters: [String: Any]?) -> [[String: Any]] {
        return eventParameters?[RAnalyticsEvent.Parameter.viewableData] as? [[String: Any]] ?? []
    }

    @MainActor
    private static func refreshResult(_ tracker: ViewableImpressionTracker, viewportView: UIView? = nil) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            tracker.refreshState(viewportView: viewportView) { eventParameters in
                continuation.resume(returning: eventParameters)
            }
        }
    }
    
    @Suite("Manual Tracking")
    struct ManualTrackingTests {
        @MainActor
        @Test("findViewControllerName returns owning view controller name")
        func testFindViewControllerNameReturnsOwner() {
            let root = UIViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = root
            window.makeKeyAndVisible()

            let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
            root.view.addSubview(view)

            #expect(view.findViewControllerName() == "UIViewController")
        }

        @MainActor
        @Test("manual tracking uses viewport context when none provided")
        func testManualUsesViewportContext() async throws {
            let root = UIViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = root
            window.makeKeyAndVisible()

            let impressionTracker = ViewableImpressionTracker(view: root.view)
            impressionTracker.minimumDwellTime = 0
            impressionTracker.minimumVisibilityPercentage = 0
            impressionTracker.enableTracking()

            let item = MockTrackableItem(itemId: "manual-context", itemTitle: "Manual Context")
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            root.view.addSubview(view)

            impressionTracker.track(view: view, item: item, itemPosition: 0)
            let eventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker)
            let eventData = ViewableImpressionTrackerTests.eventData(from: eventParameters)
            #expect(eventData.count == 1)
            #expect(eventData.first?[RAnalyticsEvent.Parameter.itemId] as? String == item.itemId)
        }

        @MainActor
        @Test("manual track + refreshState returns qualified items")
        func testManualTrackAndRefreshReturnsQualifiedItems() async throws {
            let root = UIViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = root
            window.makeKeyAndVisible()

            let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            root.view.addSubview(scrollView)

            let impressionTracker = ViewableImpressionTracker()
            impressionTracker.minimumDwellTime = 0
            impressionTracker.minimumVisibilityPercentage = 0
            impressionTracker.enableTracking()

            let item = MockTrackableItem(itemId: "manual-1", itemTitle: "Manual 1")
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            scrollView.addSubview(view)

            impressionTracker.track(view: view, item: item, itemPosition: 3)
            let eventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker, viewportView: scrollView)
            let eventData = ViewableImpressionTrackerTests.eventData(from: eventParameters)
            #expect(eventData.count == 1)
            let qualified = eventData.first
            #expect(qualified?[RAnalyticsEvent.Parameter.itemId] as? String == item.itemId)
            #expect(qualified?[RAnalyticsEvent.Parameter.itemPosition] as? Int == 3)
            let timestamp = qualified?[RAnalyticsEvent.Parameter.viewableImpressionTimestamp] as? NSNumber
            #expect(timestamp != nil)
        }

        @MainActor
        @Test("manual tracking includes screen_name at item level")
        func testManualIncludesScreenName() async throws {
            let root = UIViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = root
            window.makeKeyAndVisible()

            let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            root.view.addSubview(scrollView)

            let impressionTracker = ViewableImpressionTracker()
            impressionTracker.minimumDwellTime = 0
            impressionTracker.minimumVisibilityPercentage = 0
            impressionTracker.enableTracking()

            let item = MockTrackableItem(itemId: "manual-identifier", itemTitle: "Manual Identifier")
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            scrollView.addSubview(view)

            impressionTracker.track(view: view, item: item, itemPosition: 1)
            let eventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker, viewportView: scrollView)
            let eventData = ViewableImpressionTrackerTests.eventData(from: eventParameters)
            #expect(eventData.first?[RAnalyticsEvent.Parameter.screenName] as? String == "UIViewController")
        }

        @MainActor
        @Test("manual untrack prevents qualified impressions")
        func testManualUntrackPreventsEvent() async throws {
            let root = UIViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = root
            window.makeKeyAndVisible()

            let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            root.view.addSubview(scrollView)

            let impressionTracker = ViewableImpressionTracker()
            impressionTracker.minimumDwellTime = 0
            impressionTracker.minimumVisibilityPercentage = 0
            impressionTracker.enableTracking()

            let item = MockTrackableItem(itemId: "manual-2", itemTitle: "Manual 2")
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            scrollView.addSubview(view)

            impressionTracker.track(view: view, item: item, itemPosition: 1)
            impressionTracker.untrack(itemId: item.itemId)
            let eventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker, viewportView: scrollView)
            let eventData = ViewableImpressionTrackerTests.eventData(from: eventParameters)
            #expect(eventData.isEmpty)
        }

        @MainActor
        @Test("manual untrack allows tracking again")
        func testManualUntrackAllowsTrackingAgain() async throws {
            let root = UIViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = root
            window.makeKeyAndVisible()

            let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            root.view.addSubview(scrollView)

            let impressionTracker = ViewableImpressionTracker()
            impressionTracker.minimumDwellTime = 0
            impressionTracker.minimumVisibilityPercentage = 0
            impressionTracker.enableTracking()

            let item = MockTrackableItem(itemId: "manual-untrack-retrack", itemTitle: "Manual Untrack Retrack")
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            scrollView.addSubview(view)

            impressionTracker.track(view: view, item: item, itemPosition: 0)
            impressionTracker.untrack(itemId: item.itemId)
            let firstEventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker, viewportView: scrollView)
            let firstEventData = ViewableImpressionTrackerTests.eventData(from: firstEventParameters)
            #expect(firstEventData.isEmpty)

            impressionTracker.track(view: view, item: item, itemPosition: 0)
            let secondEventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker, viewportView: scrollView)
            let secondEventData = ViewableImpressionTrackerTests.eventData(from: secondEventParameters)
            #expect(secondEventData.count == 1)
        }

        @MainActor
        @Test("manual disableTracking prevents qualified impressions")
        func testManualDisableTrackingPreventsEvent() async throws {
            let root = UIViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = root
            window.makeKeyAndVisible()

            let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            root.view.addSubview(scrollView)

            let impressionTracker = ViewableImpressionTracker()
            impressionTracker.minimumDwellTime = 0
            impressionTracker.minimumVisibilityPercentage = 0
            impressionTracker.enableTracking()

            let item = MockTrackableItem(itemId: "manual-disable", itemTitle: "Manual Disable")
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            scrollView.addSubview(view)

            impressionTracker.track(view: view, item: item, itemPosition: 0)
            impressionTracker.disableTracking()
            let eventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker, viewportView: scrollView)
            let eventData = ViewableImpressionTrackerTests.eventData(from: eventParameters)
            #expect(eventData.isEmpty)
        }

        @MainActor
        @Test("manual clear removes all tracked items")
        func testManualClearRemovesAllTrackedItems() async throws {
            let root = UIViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = root
            window.makeKeyAndVisible()

            let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            root.view.addSubview(scrollView)

            let impressionTracker = ViewableImpressionTracker()
            impressionTracker.minimumDwellTime = 0
            impressionTracker.minimumVisibilityPercentage = 0
            impressionTracker.enableTracking()

            let item = MockTrackableItem(itemId: "manual-3", itemTitle: "Manual 3")
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            scrollView.addSubview(view)

            impressionTracker.track(view: view, item: item, itemPosition: 2)
            impressionTracker.clearManualTracking()
            let eventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker, viewportView: scrollView)
            let eventData = ViewableImpressionTrackerTests.eventData(from: eventParameters)
            #expect(eventData.isEmpty)
        }

        @MainActor
        @Test("manual clear allows tracking again")
        func testManualClearAllowsTrackingAgain() async throws {
            let root = UIViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = root
            window.makeKeyAndVisible()

            let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            root.view.addSubview(scrollView)

            let impressionTracker = ViewableImpressionTracker()
            impressionTracker.minimumDwellTime = 0
            impressionTracker.minimumVisibilityPercentage = 0
            impressionTracker.enableTracking()

            let item = MockTrackableItem(itemId: "manual-clear-retrack", itemTitle: "Manual Clear Retrack")
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            scrollView.addSubview(view)

            impressionTracker.track(view: view, item: item, itemPosition: 0)
            impressionTracker.clearManualTracking()
            let firstEventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker, viewportView: scrollView)
            let firstEventData = ViewableImpressionTrackerTests.eventData(from: firstEventParameters)
            #expect(firstEventData.isEmpty)

            impressionTracker.track(view: view, item: item, itemPosition: 0)
            let secondEventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker, viewportView: scrollView)
            let secondEventData = ViewableImpressionTrackerTests.eventData(from: secondEventParameters)
            #expect(secondEventData.count == 1)
        }

        @MainActor
        @Test("manual respects visibility threshold")
        func testManualRespectsVisibilityThreshold() async throws {
            let root = UIViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = root
            window.makeKeyAndVisible()

            let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            root.view.addSubview(scrollView)

            let impressionTracker = ViewableImpressionTracker()
            impressionTracker.minimumDwellTime = 0
            impressionTracker.minimumVisibilityPercentage = 0.9
            impressionTracker.enableTracking()

            let item = MockTrackableItem(itemId: "manual-threshold", itemTitle: "Manual Threshold")
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            scrollView.addSubview(view)

            impressionTracker.track(view: view, item: item, itemPosition: 0)
            let eventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker, viewportView: scrollView)
            let eventData = ViewableImpressionTrackerTests.eventData(from: eventParameters)
            #expect(eventData.isEmpty)
        }

        @MainActor
        @Test("manual refresh resets dwell when view becomes invalid")
        func testManualRefreshResetsWhenViewInvalid() async throws {
            let root = UIViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = root
            window.makeKeyAndVisible()

            let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            root.view.addSubview(scrollView)

            let impressionTracker = ViewableImpressionTracker()
            impressionTracker.minimumDwellTime = 0.2
            impressionTracker.minimumVisibilityPercentage = 0
            impressionTracker.enableTracking()

            let item = MockTrackableItem(itemId: "manual-4", itemTitle: "Manual 4")
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            scrollView.addSubview(view)

            impressionTracker.track(view: view, item: item, itemPosition: 0)
            let firstEventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker, viewportView: scrollView)
            let firstEventData = ViewableImpressionTrackerTests.eventData(from: firstEventParameters)
            #expect(firstEventData.count == 1)

            view.isHidden = true
            let hiddenEventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker, viewportView: scrollView)
            let hiddenEventData = ViewableImpressionTrackerTests.eventData(from: hiddenEventParameters)
            #expect(hiddenEventData.isEmpty)

            view.isHidden = false
            let visibleEventParameters = await ViewableImpressionTrackerTests.refreshResult(impressionTracker, viewportView: scrollView)
            let visibleEventData = ViewableImpressionTrackerTests.eventData(from: visibleEventParameters)
            #expect(visibleEventData.count == 1)
        }
    }
}

import UIKit
import Testing
@preconcurrency @testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

private struct MockTrackableItem: ViewableImpressionTrackable {
    let itemId: String
    let itemTitle: String
    let itemDescription: String? = nil
    let itemCategory: String? = nil
    let itemGenre: String? = nil
    let itemPrice: String? = nil
}

private func extractViewableImpressionPayload(from requests: [URLRequest]) -> [String: Any]? {
    for request in requests {
        guard let payload = request.httpBody?.ratPayload else { continue }
        for json in payload where (json[PayloadParameterKeys.etype] as? String) == RAnalyticsEvent.Name.viewableImpression {
            return json
        }
    }
    return nil
}

@Suite("ViewableImpressionTracker")
struct ViewableImpressionTrackerTests {
    @MainActor
    private static func installRATTrackerForSharedManager() -> (AnalyticsManager, Tracker) {
        let manager = AnalyticsManager.shared()
        let container = SimpleContainerMock()
        container.bundle = BundleMock.create()
        let tracker = RAnalyticsRATTracker(dependenciesContainer: container)
        manager.add(tracker)
        return (manager, tracker)
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
            let (manager, ratTracker) = ViewableImpressionTrackerTests.installRATTrackerForSharedManager()
            defer { manager.remove(ratTracker) }

            URLSessionMock.startMockingURLSession()
            defer { URLSessionMock.stopMockingURLSession() }

            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            sessionMock.stubResponse(statusCode: 200)
            var requests: [URLRequest] = []
            sessionMock.onCompletedTask = {
                if let request = sessionMock.sentRequest { requests.append(request) }
            }

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
            impressionTracker.refreshState()

            try await TestingHelpers.eventuallyOnMain(timeout: 6.0) {
                extractViewableImpressionPayload(from: requests) != nil
            }
        }

        @MainActor
        @Test("manual track + refreshState emits a viewable impression event")
        func testManualTrackAndRefreshEmitsEvent() async throws {
            let (manager, tracker) = ViewableImpressionTrackerTests.installRATTrackerForSharedManager()
            defer { manager.remove(tracker) }

            URLSessionMock.startMockingURLSession()
            defer { URLSessionMock.stopMockingURLSession() }

            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            sessionMock.stubResponse(statusCode: 200)
            var requests: [URLRequest] = []
            sessionMock.onCompletedTask = {
                if let request = sessionMock.sentRequest { requests.append(request) }
            }

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
            impressionTracker.refreshState(viewportView: scrollView, triggerReason: "manual")

            try await TestingHelpers.eventuallyOnMain(timeout: 6.0) {
                extractViewableImpressionPayload(from: requests) != nil
            }
        }

        @MainActor
        @Test("manual tracking includes scrollViewIdentifier and screen_name at item level")
        func testManualIncludesScrollViewIdentifierAndScreenName() async throws {
            let (manager, tracker) = ViewableImpressionTrackerTests.installRATTrackerForSharedManager()
            defer { manager.remove(tracker) }

            URLSessionMock.startMockingURLSession()
            defer { URLSessionMock.stopMockingURLSession() }

            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            sessionMock.stubResponse(statusCode: 200)
            var requests: [URLRequest] = []
            sessionMock.onCompletedTask = {
                if let request = sessionMock.sentRequest { requests.append(request) }
            }

            let root = UIViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = root
            window.makeKeyAndVisible()

            let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            scrollView.scrollViewIdentifier = "viewable-scroll"
            root.view.addSubview(scrollView)

            let impressionTracker = ViewableImpressionTracker()
            impressionTracker.minimumDwellTime = 0
            impressionTracker.minimumVisibilityPercentage = 0
            impressionTracker.enableTracking()

            let item = MockTrackableItem(itemId: "manual-identifier", itemTitle: "Manual Identifier")
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            scrollView.addSubview(view)

            impressionTracker.track(view: view, item: item, itemPosition: 1)
            impressionTracker.refreshState(viewportView: scrollView, triggerReason: "manual")

            var payload: [String: Any]?
            try await TestingHelpers.eventuallyOnMain(timeout: 6.0) {
                if let found = extractViewableImpressionPayload(from: requests) {
                    payload = found
                    return true
                }
                return false
            }

            let resolvedPayload = try #require(payload)
            #expect(resolvedPayload[RAnalyticsEvent.Parameter.scrollViewIdentifier] as? String == "viewable-scroll")
            
            let eventData = resolvedPayload["event_data"] as? [[String: Any]]
            let firstItem = try #require(eventData?.first)
            #expect(firstItem[RAnalyticsEvent.Parameter.screenName] as? String == "UIViewController")
            // trigger_reason is also at item level
            #expect(firstItem[RAnalyticsEvent.Parameter.triggerReason] as? String == "manual")
        }

        @MainActor
        @Test("manual untrack prevents viewable impression event")
        func testManualUntrackPreventsEvent() async throws {
            let (manager, tracker) = ViewableImpressionTrackerTests.installRATTrackerForSharedManager()
            defer { manager.remove(tracker) }

            URLSessionMock.startMockingURLSession()
            defer { URLSessionMock.stopMockingURLSession() }

            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            sessionMock.stubResponse(statusCode: 200)
            var requests: [URLRequest] = []
            sessionMock.onCompletedTask = {
                if let request = sessionMock.sentRequest { requests.append(request) }
            }

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
            impressionTracker.refreshState(viewportView: scrollView)

            try await Task.sleep(nanoseconds: 400_000_000)
            #expect(extractViewableImpressionPayload(from: requests) == nil)
        }

        @MainActor
        @Test("manual untrack allows tracking again")
        func testManualUntrackAllowsTrackingAgain() async throws {
            let (manager, tracker) = ViewableImpressionTrackerTests.installRATTrackerForSharedManager()
            defer { manager.remove(tracker) }

            URLSessionMock.startMockingURLSession()
            defer { URLSessionMock.stopMockingURLSession() }

            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            sessionMock.stubResponse(statusCode: 200)
            var requests: [URLRequest] = []
            sessionMock.onCompletedTask = {
                if let request = sessionMock.sentRequest { requests.append(request) }
            }

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
            impressionTracker.refreshState(viewportView: scrollView)

            try await Task.sleep(nanoseconds: 400_000_000)
            #expect(extractViewableImpressionPayload(from: requests) == nil)

            impressionTracker.track(view: view, item: item, itemPosition: 0)
            impressionTracker.refreshState(viewportView: scrollView)

            try await TestingHelpers.eventuallyOnMain(timeout: 6.0) {
                extractViewableImpressionPayload(from: requests) != nil
            }
        }

        @MainActor
        @Test("manual disableTracking prevents viewable impression event")
        func testManualDisableTrackingPreventsEvent() async throws {
            let (manager, tracker) = ViewableImpressionTrackerTests.installRATTrackerForSharedManager()
            defer { manager.remove(tracker) }

            URLSessionMock.startMockingURLSession()
            defer { URLSessionMock.stopMockingURLSession() }

            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            sessionMock.stubResponse(statusCode: 200)
            var requests: [URLRequest] = []
            sessionMock.onCompletedTask = {
                if let request = sessionMock.sentRequest { requests.append(request) }
            }

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
            impressionTracker.refreshState(viewportView: scrollView)

            try await Task.sleep(nanoseconds: 400_000_000)
            #expect(extractViewableImpressionPayload(from: requests) == nil)
        }

        @MainActor
        @Test("manual clear removes all tracked items")
        func testManualClearRemovesAllTrackedItems() async throws {
            let (manager, tracker) = ViewableImpressionTrackerTests.installRATTrackerForSharedManager()
            defer { manager.remove(tracker) }

            URLSessionMock.startMockingURLSession()
            defer { URLSessionMock.stopMockingURLSession() }

            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            sessionMock.stubResponse(statusCode: 200)
            var requests: [URLRequest] = []
            sessionMock.onCompletedTask = {
                if let request = sessionMock.sentRequest { requests.append(request) }
            }

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
            impressionTracker.refreshState(viewportView: scrollView)

            try await Task.sleep(nanoseconds: 400_000_000)
            #expect(extractViewableImpressionPayload(from: requests) == nil)
        }

        @MainActor
        @Test("manual clear allows tracking again")
        func testManualClearAllowsTrackingAgain() async throws {
            let (manager, tracker) = ViewableImpressionTrackerTests.installRATTrackerForSharedManager()
            defer { manager.remove(tracker) }

            URLSessionMock.startMockingURLSession()
            defer { URLSessionMock.stopMockingURLSession() }

            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            sessionMock.stubResponse(statusCode: 200)
            var requests: [URLRequest] = []
            sessionMock.onCompletedTask = {
                if let request = sessionMock.sentRequest { requests.append(request) }
            }

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
            impressionTracker.refreshState(viewportView: scrollView)

            try await Task.sleep(nanoseconds: 400_000_000)
            #expect(extractViewableImpressionPayload(from: requests) == nil)

            impressionTracker.track(view: view, item: item, itemPosition: 0)
            impressionTracker.refreshState(viewportView: scrollView)

            try await TestingHelpers.eventuallyOnMain(timeout: 6.0) {
                extractViewableImpressionPayload(from: requests) != nil
            }
        }

        @MainActor
        @Test("manual respects visibility threshold")
        func testManualRespectsVisibilityThreshold() async throws {
            let (manager, tracker) = ViewableImpressionTrackerTests.installRATTrackerForSharedManager()
            defer { manager.remove(tracker) }

            URLSessionMock.startMockingURLSession()
            defer { URLSessionMock.stopMockingURLSession() }

            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            sessionMock.stubResponse(statusCode: 200)
            var requests: [URLRequest] = []
            sessionMock.onCompletedTask = {
                if let request = sessionMock.sentRequest { requests.append(request) }
            }

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
            impressionTracker.refreshState(viewportView: scrollView)

            try await Task.sleep(nanoseconds: 400_000_000)
            #expect(extractViewableImpressionPayload(from: requests) == nil)
        }

        @MainActor
        @Test("manual refresh resets dwell when view becomes invalid")
        func testManualRefreshResetsWhenViewInvalid() async throws {
            let (manager, tracker) = ViewableImpressionTrackerTests.installRATTrackerForSharedManager()
            defer { manager.remove(tracker) }

            URLSessionMock.startMockingURLSession()
            defer { URLSessionMock.stopMockingURLSession() }

            let sessionMock = URLSessionMock.mock(originalInstance: .shared)
            sessionMock.stubResponse(statusCode: 200)
            var requests: [URLRequest] = []
            sessionMock.onCompletedTask = {
                if let request = sessionMock.sentRequest { requests.append(request) }
            }

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
            impressionTracker.refreshState(viewportView: scrollView)

            view.isHidden = true
            impressionTracker.refreshState(viewportView: scrollView)

            view.isHidden = false
            impressionTracker.refreshState(viewportView: scrollView)
            impressionTracker.refreshState(viewportView: scrollView)

            #expect(extractViewableImpressionPayload(from: requests) == nil)

            try await Task.sleep(nanoseconds: 300_000_000)
            impressionTracker.refreshState(viewportView: scrollView)

            try await TestingHelpers.eventuallyOnMain(timeout: 6.0) {
                extractViewableImpressionPayload(from: requests) != nil
            }
        }
    }
}

import UIKit
import SwiftUI
import Testing
@preconcurrency @testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("AnalyticsViewableImpressionModifier")
struct AnalyticsViewableImpressionModifierTests {
    private struct TestItem: ViewableImpressionTrackable {
        let itemId: String
        let itemTitle: String
        let itemDescription: String?
        let itemCategory: String?
        let itemGenre: String?
        let itemPrice: String?
    }

    @MainActor
    private final class ManualModifierModel: ObservableObject {
        @Published var showItem = true
        let tracker = SwiftUIManualViewableImpressionTracker(
            minimumDwellTime: 0,
            minimumVisibilityPercentage: 0,
            scrollViewIdentifier: "manual-scroll"
        )
    }

    @MainActor
    private func installRATTrackerForSharedManager() -> (AnalyticsManager, Tracker) {
        let manager = AnalyticsManager.shared()
        let container = SimpleContainerMock()
        container.bundle = BundleMock.create()
        let tracker = RAnalyticsRATTracker(dependenciesContainer: container)
        manager.add(tracker)
        return (manager, tracker)
    }

    @Test("manual SwiftUI tracker batches impressions")
    @MainActor
    func manualTrackerBatchesImpressions() async throws {
        let (manager, tracker) = installRATTrackerForSharedManager()
        defer { manager.remove(tracker) }

        URLSessionMock.startMockingURLSession()
        defer { URLSessionMock.stopMockingURLSession() }

        let sessionMock = URLSessionMock.mock(originalInstance: .shared)
        sessionMock.stubResponse(statusCode: 200)
        var requests: [URLRequest] = []
        sessionMock.onCompletedTask = {
            if let request = sessionMock.sentRequest { requests.append(request) }
        }

        let manualTracker = SwiftUIManualViewableImpressionTracker(
            minimumDwellTime: 0,
            minimumVisibilityPercentage: 0,
            scrollViewIdentifier: "manual-scroll"
        )

        let item1 = TestItem(itemId: "m-1", itemTitle: "Manual 1", itemDescription: nil, itemCategory: nil, itemGenre: nil, itemPrice: nil)
        let item2 = TestItem(itemId: "m-2", itemTitle: "Manual 2", itemDescription: nil, itemCategory: nil, itemGenre: nil, itemPrice: nil)

        manualTracker.update(item: item1, frame: CGRect(x: 0, y: 0, width: 100, height: 100), itemPosition: 0)
        manualTracker.update(item: item2, frame: CGRect(x: 0, y: 120, width: 100, height: 100), itemPosition: 1)
        try await Task.sleep(nanoseconds: 50_000_000)
        manualTracker.refreshState(viewport: CGRect(x: 0, y: 0, width: 200, height: 400))

        var impressionPayload: [String: Any]?
        try await TestingHelpers.eventuallyOnMain(timeout: 6.0) {
            for request in requests {
                guard let payload = request.httpBody?.ratPayload else { continue }
                for json in payload where (json[PayloadParameterKeys.etype] as? String) == RAnalyticsEvent.Name.viewableImpression {
                    let items = json["event_data"] as? [[String: Any]]
                    let itemIds = items?.compactMap { $0[RAnalyticsEvent.Parameter.itemId] as? String }.sorted()
                    if itemIds == ["m-1", "m-2"] {
                        impressionPayload = json
                        return true
                    }
                }
            }
            return false
        }

        let payload = try #require(impressionPayload)
        #expect(payload["item_count"] as? Int == 2)
    }

    @Test("manual SwiftUI tracker respects visibility threshold")
    @MainActor
    func manualTrackerRespectsVisibilityThreshold() async throws {
        let (manager, tracker) = installRATTrackerForSharedManager()
        defer { manager.remove(tracker) }

        URLSessionMock.startMockingURLSession()
        defer { URLSessionMock.stopMockingURLSession() }

        let sessionMock = URLSessionMock.mock(originalInstance: .shared)
        sessionMock.stubResponse(statusCode: 200)
        var requests: [URLRequest] = []
        sessionMock.onCompletedTask = {
            if let request = sessionMock.sentRequest { requests.append(request) }
        }

        let manualTracker = SwiftUIManualViewableImpressionTracker(
            minimumDwellTime: 0,
            minimumVisibilityPercentage: 0.9,
            scrollViewIdentifier: "manual-scroll"
        )

        let item = TestItem(itemId: "m-3", itemTitle: "Manual 3", itemDescription: nil, itemCategory: nil, itemGenre: nil, itemPrice: nil)
        manualTracker.update(item: item, frame: CGRect(x: 0, y: 0, width: 100, height: 100), itemPosition: 0)
        manualTracker.refreshState(viewport: CGRect(x: 0, y: 0, width: 50, height: 50))

        try await Task.sleep(nanoseconds: 400_000_000)
        let payload = requests.compactMap { $0.httpBody?.ratPayload }
            .flatMap { $0 }
            .first { ($0[PayloadParameterKeys.etype] as? String) == RAnalyticsEvent.Name.viewableImpression }
        #expect(payload == nil)
    }

    @Test("manual SwiftUI tracker clear removes tracked items")
    @MainActor
    func manualTrackerClearRemovesTrackedItems() async throws {
        let (manager, tracker) = installRATTrackerForSharedManager()
        defer { manager.remove(tracker) }

        URLSessionMock.startMockingURLSession()
        defer { URLSessionMock.stopMockingURLSession() }

        let sessionMock = URLSessionMock.mock(originalInstance: .shared)
        sessionMock.stubResponse(statusCode: 200)
        var requests: [URLRequest] = []
        sessionMock.onCompletedTask = {
            if let request = sessionMock.sentRequest { requests.append(request) }
        }

        let manualTracker = SwiftUIManualViewableImpressionTracker(
            minimumDwellTime: 0,
            minimumVisibilityPercentage: 0,
            scrollViewIdentifier: "manual-scroll"
        )

        let item = TestItem(itemId: "m-clear", itemTitle: "Manual Clear", itemDescription: nil, itemCategory: nil, itemGenre: nil, itemPrice: nil)
        manualTracker.update(item: item, frame: CGRect(x: 0, y: 0, width: 100, height: 100), itemPosition: 0)
        manualTracker.clear()
        manualTracker.refreshState(viewport: CGRect(x: 0, y: 0, width: 200, height: 200))

        try await Task.sleep(nanoseconds: 400_000_000)
        let payload = requests.compactMap { $0.httpBody?.ratPayload }
            .flatMap { $0 }
            .first { ($0[PayloadParameterKeys.etype] as? String) == RAnalyticsEvent.Name.viewableImpression }
        #expect(payload == nil)
    }

    @Test("manual SwiftUI tracker unregister removes a single item")
    @MainActor
    func manualTrackerUnregisterRemovesSingleItem() async throws {
        let (manager, tracker) = installRATTrackerForSharedManager()
        defer { manager.remove(tracker) }

        URLSessionMock.startMockingURLSession()
        defer { URLSessionMock.stopMockingURLSession() }

        let sessionMock = URLSessionMock.mock(originalInstance: .shared)
        sessionMock.stubResponse(statusCode: 200)
        var requests: [URLRequest] = []
        sessionMock.onCompletedTask = {
            if let request = sessionMock.sentRequest { requests.append(request) }
        }

        let manualTracker = SwiftUIManualViewableImpressionTracker(
            minimumDwellTime: 0,
            minimumVisibilityPercentage: 0,
            scrollViewIdentifier: "manual-scroll"
        )

        let item = TestItem(itemId: "m-unregister", itemTitle: "Manual Unregister", itemDescription: nil, itemCategory: nil, itemGenre: nil, itemPrice: nil)
        manualTracker.update(item: item, frame: CGRect(x: 0, y: 0, width: 100, height: 100), itemPosition: 0)
        manualTracker.unregister(itemId: item.itemId)
        manualTracker.refreshState(viewport: CGRect(x: 0, y: 0, width: 200, height: 200))

        try await Task.sleep(nanoseconds: 400_000_000)
        let payload = requests.compactMap { $0.httpBody?.ratPayload }
            .flatMap { $0 }
            .first { ($0[PayloadParameterKeys.etype] as? String) == RAnalyticsEvent.Name.viewableImpression }
        #expect(payload == nil)
    }

    @Test("manual SwiftUI modifier unregisters on disappear")
    @MainActor
    func manualModifierUnregistersOnDisappear() async throws {
        let (manager, tracker) = installRATTrackerForSharedManager()
        defer { manager.remove(tracker) }

        URLSessionMock.startMockingURLSession()
        defer { URLSessionMock.stopMockingURLSession() }

        let sessionMock = URLSessionMock.mock(originalInstance: .shared)
        sessionMock.stubResponse(statusCode: 200)
        var requests: [URLRequest] = []
        sessionMock.onCompletedTask = {
            if let request = sessionMock.sentRequest { requests.append(request) }
        }

        let model = ManualModifierModel()
        let item = TestItem(itemId: "m-disappear", itemTitle: "Manual Disappear", itemDescription: nil, itemCategory: nil, itemGenre: nil, itemPrice: nil)

        struct HostView: View {
            @ObservedObject var model: ManualModifierModel
            let item: TestItem

            var body: some View {
                VStack {
                    if model.showItem {
                        Text("Item")
                            .frame(width: 100, height: 100)
                            .analyticsViewableImpressionManual(
                                tracker: model.tracker,
                                item: item,
                                itemPosition: 0
                            )
                    }
                }
            }
        }

        let host = UIHostingController(rootView: HostView(model: model, item: item))
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()

        host.beginAppearanceTransition(true, animated: false)
        host.endAppearanceTransition()
        host.view.layoutIfNeeded()

        model.showItem = false
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: 100_000_000)

        model.tracker.refreshState(viewport: UIScreen.main.bounds)

        try await Task.sleep(nanoseconds: 400_000_000)
        let payload = requests.compactMap { $0.httpBody?.ratPayload }
            .flatMap { $0 }
            .first { ($0[PayloadParameterKeys.etype] as? String) == RAnalyticsEvent.Name.viewableImpression }
        #expect(payload == nil)
    }
}

import UIKit
import SwiftUI
import Testing
@preconcurrency @testable import RakutenAnalytics

@Suite("AnalyticsViewableImpressionModifier")
struct AnalyticsViewableImpressionModifierTests {
    @MainActor
    private func eventData(from eventParameters: [String: Any]?) -> [[String: Any]] {
        return eventParameters?[RAnalyticsEvent.Parameter.viewableData] as? [[String: Any]] ?? []
    }

    @MainActor
    private func refreshResult(_ tracker: SwiftUIManualViewableImpressionTracker,
                               viewport: CGRect? = nil) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            tracker.refreshState(viewport: viewport) { eventParameters in
                continuation.resume(returning: eventParameters)
            }
        }
    }
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
            minimumVisibilityPercentage: 0
        )
    }

    @Test("manual SwiftUI tracker batches impressions")
    @MainActor
    func manualTrackerBatchesImpressions() async throws {
        let manualTracker = SwiftUIManualViewableImpressionTracker(
            minimumDwellTime: 0,
            minimumVisibilityPercentage: 0
        )

        let item1 = TestItem(itemId: "m-1", itemTitle: "Manual 1", itemDescription: nil, itemCategory: nil, itemGenre: nil, itemPrice: nil)
        let item2 = TestItem(itemId: "m-2", itemTitle: "Manual 2", itemDescription: nil, itemCategory: nil, itemGenre: nil, itemPrice: nil)

        manualTracker.update(item: item1, frame: CGRect(x: 0, y: 0, width: 100, height: 100), itemPosition: 0)
        manualTracker.update(item: item2, frame: CGRect(x: 0, y: 120, width: 100, height: 100), itemPosition: 1)
        try await Task.sleep(nanoseconds: 50_000_000)
        let eventParameters = await refreshResult(manualTracker, viewport: CGRect(x: 0, y: 0, width: 200, height: 400))
        let eventData = eventData(from: eventParameters)
        let itemIds = eventData.compactMap { $0[RAnalyticsEvent.Parameter.itemId] as? String }.sorted()
        #expect(itemIds == ["m-1", "m-2"])
        let timestamp = eventData.first?[RAnalyticsEvent.Parameter.viewableImpressionTimestamp] as? NSNumber
        #expect(timestamp != nil)
    }

    @Test("manual SwiftUI tracker respects visibility threshold")
    @MainActor
    func manualTrackerRespectsVisibilityThreshold() async throws {
        let manualTracker = SwiftUIManualViewableImpressionTracker(
            minimumDwellTime: 0,
            minimumVisibilityPercentage: 0.9
        )

        let item = TestItem(itemId: "m-3", itemTitle: "Manual 3", itemDescription: nil, itemCategory: nil, itemGenre: nil, itemPrice: nil)
        manualTracker.update(item: item, frame: CGRect(x: 0, y: 0, width: 100, height: 100), itemPosition: 0)
        let eventParameters = await refreshResult(manualTracker, viewport: CGRect(x: 0, y: 0, width: 50, height: 50))
        let eventData = eventData(from: eventParameters)
        #expect(eventData.isEmpty)
    }

    @Test("manual SwiftUI tracker clear removes tracked items")
    @MainActor
    func manualTrackerClearRemovesTrackedItems() async throws {
        let manualTracker = SwiftUIManualViewableImpressionTracker(
            minimumDwellTime: 0,
            minimumVisibilityPercentage: 0
        )

        let item = TestItem(itemId: "m-clear", itemTitle: "Manual Clear", itemDescription: nil, itemCategory: nil, itemGenre: nil, itemPrice: nil)
        manualTracker.update(item: item, frame: CGRect(x: 0, y: 0, width: 100, height: 100), itemPosition: 0)
        manualTracker.clear()
        let eventParameters = await refreshResult(manualTracker, viewport: CGRect(x: 0, y: 0, width: 200, height: 200))
        let eventData = eventData(from: eventParameters)
        #expect(eventData.isEmpty)
    }

    @Test("manual SwiftUI tracker unregister removes a single item")
    @MainActor
    func manualTrackerUnregisterRemovesSingleItem() async throws {
        let manualTracker = SwiftUIManualViewableImpressionTracker(
            minimumDwellTime: 0,
            minimumVisibilityPercentage: 0
        )

        let item = TestItem(itemId: "m-unregister", itemTitle: "Manual Unregister", itemDescription: nil, itemCategory: nil, itemGenre: nil, itemPrice: nil)
        manualTracker.update(item: item, frame: CGRect(x: 0, y: 0, width: 100, height: 100), itemPosition: 0)
        manualTracker.unregister(itemId: item.itemId)
        let eventParameters = await refreshResult(manualTracker, viewport: CGRect(x: 0, y: 0, width: 200, height: 200))
        let eventData = eventData(from: eventParameters)
        #expect(eventData.isEmpty)
    }

    @Test("manual SwiftUI modifier unregisters on disappear")
    @MainActor
    func manualModifierUnregistersOnDisappear() async throws {
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

        let eventParameters = await refreshResult(model.tracker, viewport: window.bounds)
        let eventData = eventData(from: eventParameters)
        #expect(eventData.isEmpty)
    }
}

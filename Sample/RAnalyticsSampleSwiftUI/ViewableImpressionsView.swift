import RakutenAnalytics
import SwiftUI

struct ViewableImpressionsView: View {
    struct ViewableItem: ViewableImpressionTrackable, Identifiable {
        var id: String { itemId }
        let itemId: String
        let itemTitle: String
        let itemDescription: String?
        let itemCategory: String?
        let itemGenre: String?
        let itemPrice: String?
    }

    /// Lazy stacks only build visible rows. Stress presets use a plain `VStack` so every row stays registered.
    private enum RowPreset: String, CaseIterable, Identifiable {
        case rows20 = "20"
        case rows50 = "50"
        case rows100 = "100"
        case rows200 = "200"
        case rows1000 = "1000"
        case stress200AllRegistered = "200+ (all reg.)"
        case stress1000AllRegistered = "1000+ (all reg.)"

        var id: String { rawValue }

        var listCount: Int {
            switch self {
            case .rows20: return 20
            case .rows50: return 50
            case .rows100: return 100
            case .rows200: return 200
            case .rows1000: return 1000
            case .stress200AllRegistered: return 200
            case .stress1000AllRegistered: return 1000
            }
        }

        var usesLazyStack: Bool {
            switch self {
            case .stress200AllRegistered, .stress1000AllRegistered: return false
            default: return true
            }
        }

        /// Matches the UIKit sample stats panel (table vs stress wording).
        var metricsSecondaryLine: String {
            if usesLazyStack {
                return "Data source rows: \(listCount)"
            }
            return "Registered for refresh: \(listCount)"
        }
    }

    @StateObject private var tracker = SwiftUIManualViewableImpressionTracker(
        minimumDwellTime: 0.5,
        minimumVisibilityPercentage: 0.5
    )

    @State private var preset: RowPreset = .rows20
    @State private var lastDurationMs: Double?
    @State private var lastQualified: Int?
    @State private var lastReason = "—"
    /// Suppresses debounced `scroll_settled` right after appear / preset change (layout churn).
    @State private var scrollSettleGateDate = Date.distantPast

    private var items: [ViewableItem] {
        (1...preset.listCount).map { index in
            ViewableItem(
                itemId: "viewable-\(index)",
                itemTitle: "Viewable Item \(index)",
                itemDescription: "Sample",
                itemCategory: "Sample",
                itemGenre: "A",
                itemPrice: "\(index * 10)"
            )
        }
    }

    var body: some View {
        ScrollView {
            listStack
                .padding()
        }
        .coordinateSpace(name: "viewableScroll")
        .onDebouncedScrollSettle(delay: 0.35) {
            guard Date().timeIntervalSince(scrollSettleGateDate) >= 0.75 else { return }
            triggerDwellRefresh(reason: "scroll_settled")
        }
        .navigationTitle("Viewable Impressions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    ForEach(RowPreset.allCases) { option in
                        Button(option.rawValue) {
                            preset = option
                        }
                    }
                } label: {
                    Text(preset.rawValue)
                        .font(.subheadline)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            metricsPanel
        }
        .onAppear {
            scrollSettleGateDate = Date()
            triggerDwellRefresh(reason: "onAppear")
        }
        .onChange(of: preset) { _ in
            scrollSettleGateDate = Date()
            tracker.clear()
            lastDurationMs = nil
            lastQualified = nil
            lastReason = "preset_changed"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                triggerDwellRefresh(reason: "preset_changed")
            }
        }
    }

    @ViewBuilder
    private var listStack: some View {
        if preset.usesLazyStack {
            LazyVStack(alignment: .leading, spacing: 12) {
                ScrollMinYReporter()
                rowContent
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ScrollMinYReporter()
                rowContent
            }
        }
    }

    @ViewBuilder
    private var rowContent: some View {
        ForEach(Array(items.enumerated()), id: \.element.itemId) { index, item in
            ViewableItemRow(item: item)
                .analyticsViewableImpressionManual(
                    tracker: tracker,
                    item: item,
                    itemPosition: index
                )
        }
    }

    private var metricsPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Last trigger: \(lastReason)")
                .font(.caption.monospaced())
            Text(preset.metricsSecondaryLine)
                .font(.caption.monospaced())
            if let lastDurationMs {
                Text(String(format: "Last refresh→callback: %.2f ms", lastDurationMs))
                    .font(.caption.monospaced())
            } else {
                Text("Last refresh→callback: —")
                    .font(.caption.monospaced())
            }
            if let lastQualified {
                Text("Qualified in last batch: \(lastQualified)")
                    .font(.caption.monospaced())
            } else {
                Text("Qualified in last batch: —")
                    .font(.caption.monospaced())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial)
    }

    private func triggerDwellRefresh(reason: String) {
        lastReason = reason
        let start = CFAbsoluteTimeGetCurrent()
        let listSize = items.count
        let signpostID = ViewableImpressionsSampleMetrics.signposter.makeSignpostID()
        let intervalState = ViewableImpressionsSampleMetrics.signposter.beginInterval("refreshState", id: signpostID)

        tracker.refreshState(viewport: UIScreen.main.bounds) { eventParameters in
            ViewableImpressionsSampleMetrics.signposter.endInterval("refreshState", intervalState)

            let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1_000
            let qualified = ViewableImpressionsSampleMetrics.viewableItemCount(in: eventParameters)
            let durationLabel = String(format: "%.2f", elapsedMs)
            ViewableImpressionsSampleMetrics.logger.notice(
                "viewable refresh reason=\(reason, privacy: .public) list_size=\(listSize, privacy: .public) viewable_items_in_batch=\(qualified, privacy: .public) duration_ms=\(durationLabel, privacy: .public)"
            )

            DispatchQueue.main.async {
                lastDurationMs = elapsedMs
                lastQualified = qualified
            }

            if let eventParameters {
                ViewableImpressionsSampleMetrics.logger.notice(
                    "sample RAT: sending pageVisit with viewable_data count=\(qualified, privacy: .public) (items in this event)"
                )
                RAnalyticsRATTracker.shared()
                    .event(withEventType: RAnalyticsEvent.Name.pageVisitForRAT, parameters: eventParameters)
                    .track()
            } else {
                ViewableImpressionsSampleMetrics.logger.notice(
                    "sample RAT: no pageVisit sent — viewable_data empty (0 viewable impression items)"
                )
            }
        }
    }
}

#Preview {
    NavigationView {
        ViewableImpressionsView()
    }
}

import SwiftUI
import RakutenAnalytics

struct ViewableImpressionsView: View {
    struct ViewableItem: ViewableImpressionTrackable, Identifiable {
        let id = UUID()
        let itemId: String
        let itemTitle: String
        let itemDescription: String?
        let itemCategory: String?
        let itemGenre: String?
        let itemPrice: String?
    }

    @StateObject private var tracker = SwiftUIManualViewableImpressionTracker(
        minimumDwellTime: 0.5,
        minimumVisibilityPercentage: 0.5
    )

    @State private var isDragging = false
    private let items: [ViewableItem] = (1...20).map { index in
        ViewableItem(
            itemId: "viewable-\(index)",
            itemTitle: "Viewable Item \(index)",
            itemDescription: "Sample",
            itemCategory: "Sample",
            itemGenre: "A",
            itemPrice: "\(index * 10)"
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    ViewableItemRow(item: item)
                        .analyticsViewableImpressionManual(
                            tracker: tracker,
                            item: item,
                            itemPosition: index
                        )
                }
            }
            .padding()
        }
        .navigationTitle("Viewable Impressions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh") {
                    triggerDwellRefresh(reason: "manual")
                }
            }
        }
        .onAppear {
            triggerDwellRefresh(reason: "pv")
        }
        .gesture(
            DragGesture()
                .onChanged { _ in
                    isDragging = true
                }
                .onEnded { _ in
                    isDragging = false
                    triggerDwellRefresh(reason: "scroll_stop")
                }
        )
    }

    private func triggerDwellRefresh(reason: String) {
        tracker.refreshState(viewport: UIScreen.main.bounds) { eventParameters in
            guard let eventParameters = eventParameters else { return }
            _ = RAnalyticsRATTracker.shared()
                .event(withEventType: RAnalyticsEvent.Name.pageVisitForRAT, parameters: eventParameters)
                .track()
        }
    }

}

private struct ViewableItemRow: View {
    let item: ViewableImpressionsView.ViewableItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.itemTitle)
                .font(.headline)
                .foregroundColor(.primary)

            Text("ID: \(item.itemId)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Text("Category: \(item.itemCategory ?? "N/A")")
                Text("Price: \(item.itemPrice ?? "N/A")")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding(12)
        .background(Color.blue.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(10)
    }
}

#Preview {
    NavigationView {
        ViewableImpressionsView()
    }
}

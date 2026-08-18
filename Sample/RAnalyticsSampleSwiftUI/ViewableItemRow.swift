import RakutenAnalytics
import SwiftUI

struct ViewableItemRow: View {
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

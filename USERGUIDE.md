# Viewable Impressions

Quick guide for integrating **manual viewable impressions** in your iOS app. Register any view and call `refreshState(onResult:)` to receive items when they are ready.

---

## What is Viewable Impressions?

Tracks items users **actually saw**, not items they scrolled past.

**Example:** User pauses on 3 items for 2 seconds → all 3 are returned in a single refresh result.
**Key Feature:** Multiple qualifying items are grouped into one array, preserving per‑item metrics so you can decide what to do with them.

---

## How it works

Manual tracking is explicit and predictable:

1. **Register items** with `track(view:item:itemPosition:)` — this only registers the view for tracking, it does **not** check visibility.
2. **Call `refreshState(onResult:)` once** to receive items when they are ready. The SDK will wait for dwell time if needed.

### Timing (default)
- **Minimum visibility:** 50% (strictly greater than)
- **Minimum dwell time:** 1.5s

### When items qualify

Items are returned only when **all** conditions are met:
- ✅ View is registered via `track()`
- ✅ View is visible (>50% by default)
- ✅ View has been visible for at least `minimumDwellTime` (1.5s by default)
- ✅ `refreshState(onResult:)` is called to evaluate

**Important:** Calling `refreshState(onResult:)` immediately after `track()` will start dwell tracking. The completion fires when items qualify or when no items are pending dwell.

**Example timeline:**
```
t=0s: track(view:cell, item:product) → Registers view
t=0s: refreshState(onResult:) → Starts dwell timer (if visible)
t=1.5s: completion → ✅ Items qualify (if still visible)
```

---

## Supported Views

Manual tracking works with **any `UIView`**:
- `UITableViewCell` / `UICollectionViewCell`
- Plain `UIView` in any screen
- Custom layouts with no scroll view

If you pass a `UIScrollView` as the viewport, it is only used for visibility evaluation.

---

## Public API Overview

Use these steps to operate the manual viewable impressions flow.

### UIKit (manual)
1. **Create a tracker**
   - `ViewableImpressionTracker()`
2. **Configure thresholds**
   - `minimumDwellTime`
   - `minimumVisibilityPercentage`
3. **Enable tracking**
   - `enableTracking()`
4. **Register views**
   - `track(view:item:itemPosition:)`
5. **Refresh and get result**
   - `refreshState(viewportView:viewportInsets:onResult:)`

### SwiftUI (manual)
1. **Create a tracker**
   - `SwiftUIManualViewableImpressionTracker(...)`
2. **Attach tracking**
   - `analyticsViewableImpressionManual(tracker:item:itemPosition:)`
3. **Refresh and get result**
   - `refreshState(viewport:viewportInsets:onResult:)`

### Shared types
- `ViewableImpressionTrackable` — protocol for required item fields (`item_id`, `item_title`, etc.)

---

## Configuration

| Setting | Default | Notes |
| --- | --- | --- |
| `minimumDwellTime` | `1.5` seconds | Minimum time an item stays visible |
| `minimumVisibilityPercentage` | `0.5` (50%) | Visibility must be **greater than** this value |

---

## UIKit Integration

### 1) Make your model trackable

```swift
struct Product: ViewableImpressionTrackable {
    let id: String
    let name: String
    let description: String?
    let category: String
    let price: String

    var itemId: String { id }
    var itemTitle: String { name }
    var itemDescription: String? { description }
    var itemCategory: String? { category }
    var itemGenre: String? { nil }
    var itemPrice: String? { price }
}
```

### 2) Create and configure tracker

```swift
let tracker = ViewableImpressionTracker()
tracker.minimumDwellTime = 1.5
tracker.minimumVisibilityPercentage = 0.5
tracker.enableTracking()
```

### 3) Register views and refresh

```swift
// Register the view for tracking
tracker.track(view: cell.contentView, item: product, itemPosition: indexPath.row)

tracker.refreshState(viewportView: listContainer) { eventParameters in
    handleQualifiedItems(eventParameters)
}
```

**Common pattern:** Call `refreshState(onResult:)` on scroll stop and handle the payload:

```swift
func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    tracker.refreshState(viewportView: scrollView) { eventParameters in
        handleQualifiedItems(eventParameters)
    }
}
```

---

## SwiftUI Integration

```swift
@StateObject private var tracker = SwiftUIManualViewableImpressionTracker(
    minimumDwellTime: 1.5,
    minimumVisibilityPercentage: 0.5
)

ItemView().analyticsViewableImpressionManual(tracker: tracker, item: item, itemPosition: 0)

tracker.refreshState(viewport: UIScreen.main.bounds) { eventParameters in
    handleQualifiedItems(eventParameters)
}
```

---

## Refresh Result

`refreshState(onResult:)` returns:
- `eventParameters` — prebuilt parameters for `RAnalyticsRATTracker.shared().event(withEventType:parameters:)`

**Behavior note:** The callback fires when the first batch of items qualifies, or immediately if no items are pending dwell. If you need repeated batches over time, call `refreshState(onResult:)` again on the next scroll stop or interaction.

**One-shot refresh (recommended):**
```swift
tracker.refreshState(viewportView: listContainer) { eventParameters in
    handleQualifiedItems(eventParameters)
}
```

**Attaching to a PV event:**
```swift
if let eventParameters = eventParameters {
    RAnalyticsRATTracker.shared().event(withEventType: RAnalyticsEvent.Name.pageVisitForRAT, parameters: eventParameters).track()
}
```

**Example payload (eventParameters result in refreshState():**
```json
{
  "viewable_data": [
    {
      "item_position": 5,
      "item_description": "Sample",
      "item_price": "60",
      "item_title": "Viewable Item 6",
      "item_id": "viewable-6",
      "item_category": "Sample",
      "dwell_time": 0.52,
      "visibility_percentage": 1,
      "item_genre": "A",
      "screen_name": "ViewableImpressionsViewController",
      "viewable_impression_timestamp": 1769478711163
    },
    {
      "item_position": 0,
      "item_description": "Sample",
      "item_id": "viewable-1",
      "item_price": "10",
      "item_title": "Viewable Item 1",
      "item_category": "Sample",
      "dwell_time": 0.52,
      "visibility_percentage": 1,
      "screen_name": "ViewableImpressionsViewController",
      "item_genre": "A",
      "viewable_impression_timestamp": 1769478711163
    }
  ]
}
```

Each entry in `eventParameters` `viewable_data` includes:
- `item_id` — unique, stable item ID
- `item_title` — display name/title
- `visibility_percentage` — visible area ratio (0.0–1.0)
- `dwell_time` — visible time in seconds
- `item_position` — position in the list (iOS-specific)
- `screen_name` — view controller name (UIKit only, if available)
- `viewable_impression_timestamp` — batch timestamp (same for all items)

---

## Sample Apps

The Sample apps include **Viewable Impressions** demos demonstrating different integration patterns (UIKit and SwiftUI)

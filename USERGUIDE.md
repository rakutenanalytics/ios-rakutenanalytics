# Viewable Impressions

Quick guide for integrating **manual viewable impressions** in your iOS app. Register any view and call `refreshState()` when you want to evaluate visibility.

---

## What is Viewable Impressions?

Tracks items users **actually saw**, not items they scrolled past.

**Example:** User pauses on 3 items for 2 seconds → all 3 are sent in **one batched event**.
**Key Feature:** Multiple qualifying items are grouped into a **single `viewable_impression` event** to reduce network overhead while preserving per‑item metrics.

---

## How it works

Manual tracking is explicit and predictable:

1. **Register items** with `track(view:item:itemPosition:)` — this only registers the view for tracking, it does **not** check visibility or fire events.
2. **Call `refreshState()`** to evaluate visibility. The first call starts tracking dwell time if the view is visible.
3. **Call `refreshState()` again** after the minimum dwell time has elapsed to fire the event.

### Timing (default)
- **Minimum visibility:** 50% (strictly greater than)
- **Minimum dwell time:** 1.5s

### When events fire

An event fires only when **all** conditions are met:
- ✅ View is registered via `track()`
- ✅ View is visible (>50% by default)
- ✅ View has been visible for at least `minimumDwellTime` (1.5s by default)
- ✅ `refreshState()` is called to evaluate and emit

**Important:** Calling `refreshState()` immediately after `track()` will **not** fire an event because dwell time starts counting from when the view first becomes visible. You must call `refreshState()` again after the dwell time has elapsed.

**Example timeline:**
```
t=0s:   track(view:cell, item:product)           → Registers view
t=0s:   refreshState()                           → Starts dwell timer (if visible)
t=1.5s: refreshState()                           → ✅ Event fires (if still visible)
```

---

## Supported Views

Manual tracking works with **any `UIView`**:
- `UITableViewCell` / `UICollectionViewCell`
- Plain `UIView` in any screen
- Custom layouts with no scroll view

If you pass a `UIScrollView` as the viewport, the SDK will add `scroll_view_identifier` to the payload (if set).

---

## Public API Overview

This feature adds public APIs for UIKit and SwiftUI integrations.

### UIKit: Viewable Impressions (Manual)

**Tracker**
- `ViewableImpressionTracker()` — create a tracker without a fixed viewport
- `ViewableImpressionTracker(view:)` — set a default viewport context view
- `ViewableImpressionTracker(scrollView:)` — convenience init for scroll-view contexts
- `minimumDwellTime` — seconds an item must stay visible before firing
- `minimumVisibilityPercentage` — required visible ratio (0.0–1.0)
- `isEnabled` — whether tracking is currently active
- `enableTracking()` — start tracking (required before calling `track`)
- `disableTracking()` — stop tracking and clear all items
- `track(view:item:itemPosition:)` — register a view and its item metadata
- `refreshState(viewportView:viewportInsets:triggerReason:)` — evaluate visibility and send impressions (triggerReason is included in event payload)
- `untrack(itemId:)` — remove a single item from tracking
- `clearManualTracking()` — remove all tracked items

**Protocol**
- `ViewableImpressionTrackable` — model contract for impression metadata (`item_id`, `item_title`, etc.)

### SwiftUI: Viewable Impressions (Manual)

**Manual tracker**
- `SwiftUIManualViewableImpressionTracker` — SwiftUI tracker for manual impressions
- `update(item:frame:itemPosition:)` — register/update an item's frame
- `refreshState(viewport:viewportInsets:triggerReason:)` — evaluate visibility and send impressions (triggerReason is included in event payload)
- `unregister(itemId:)` — stop tracking a specific item
- `clear()` — remove all tracked items

**View modifier**
- `analyticsViewableImpressionManual(tracker:item:itemPosition:)` — attach item tracking to a view

---

## Configuration

| Setting | Default | Notes |
| --- | --- | --- |
| `minimumDwellTime` | `1.5` seconds | Minimum time an item stays visible |
| `minimumVisibilityPercentage` | `0.5` (50%) | Visibility must be **greater than** this value |
| `triggerReason` | `"manual"` | Reason for triggering the impression. Included in event payload if provided and not empty. |
| `scrollViewIdentifier` | `nil` | Optional payload field |

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

// First call: starts tracking dwell time if view is visible
tracker.refreshState(viewportView: listContainer, triggerReason: "manual")

// Second call (after minimumDwellTime): fires event if view is still visible
// Typically called on scroll stop or via a timer after 1.5+ seconds
tracker.refreshState(viewportView: listContainer, triggerReason: "manual")
```

**Common pattern:** Call `refreshState()` immediately when registering, then schedule another call after `minimumDwellTime`:

```swift
func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    // First check - starts dwell timer
    tracker.refreshState(viewportView: scrollView, triggerReason: "scroll_stop")
    
    // Schedule second check after dwell time
    let dwellTime = tracker.minimumDwellTime
    guard dwellTime > 0 else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + dwellTime) {
        tracker.refreshState(viewportView: scrollView, triggerReason: "scroll_stop")
    }
}
```

---

## SwiftUI Integration

```swift
@StateObject private var tracker = SwiftUIManualViewableImpressionTracker(
    minimumDwellTime: 1.5,
    minimumVisibilityPercentage: 0.5,
    scrollViewIdentifier: "home_scroll"
)

ItemView().analyticsViewableImpressionManual(tracker: tracker, item: item, itemPosition: 0)

// First check: starts tracking dwell time if visible
tracker.refreshState(viewport: UIScreen.main.bounds, triggerReason: "manual")

// Second check (after minimumDwellTime): fires event if still visible
// Schedule this call after 1.5+ seconds have elapsed
tracker.refreshState(viewport: UIScreen.main.bounds, triggerReason: "manual")
```

---

## Event Payload (viewable_impression)

Top‑level payload:
- `etype`: `"viewable_impression"`
- `viewable_impression_timestamp` (ms)
- `item_count`
- `event_data` (array of items)
- `scroll_view_identifier` (optional)

### Payload parameters

| Field | Location | Type | Required | Description |
| --- | --- | --- | --- | --- |
| `etype` | Root | String | Yes | Event identifier (`viewable_impression`) |
| `viewable_impression_timestamp` | Root | Number (ms) | Yes | Timestamp when items became eligible |
| `item_count` | Root | Number | Yes | Number of items in the batch |
| `event_data` | Root | Array | Yes | Array of item payloads |
| `scroll_view_identifier` | Root | String | No | Optional scroll view identifier |
| `item_id` | `event_data[]` | String | Yes | Unique, stable item ID |
| `item_title` | `event_data[]` | String | Yes | Display name/title |
| `visibility_percentage` | `event_data[]` | Number | Yes | Visible area ratio (0.0–1.0) |
| `dwell_time` | `event_data[]` | Number | Yes | Visible time in seconds |
| `item_description` | `event_data[]` | String | No | Description. Only included if provided and not empty. |
| `screen_name` | `event_data[]` | String | No | View controller name (extracted from view). Only included if available and not empty. | `"ProductListViewController"` |
| `trigger_reason` | `event_data[]` | String | No | Reason why the impression was triggered. Only included if present and not empty. | `"manual"`, `"scroll_stop"`, `"pv"` |
| `item_position` | `event_data[]` | Number | Yes | Position in the list (iOS-specific) |
| `viewport_bounds` | `event_data[]` | Object | Yes | Visible viewport (`x`, `y`, `width`, `height`) (iOS-specific) |
| `item_category` | `event_data[]` | String | No | Category (iOS-specific) |
| `item_genre` | `event_data[]` | String | No | Genre (iOS-specific) |
| `item_price` | `event_data[]` | String | No | Price (iOS-specific) |

---

## Verification (Debug Logs)

```swift
AnalyticsManager.shared().set(loggingLevel: .debug)
```

When logging is `.debug`, you will see the `triggerReason` in the log output:

```
✅ VIEWABLE IMPRESSIONS: 3 item(s), reason: manual
   • Product A (ID: PROD_123) - Dwell: 1.50s, Visibility: 80%
   • Product B (ID: PROD_124) - Dwell: 1.50s, Visibility: 75%
```

> **Note:** The `triggerReason` shown in debug logs (e.g., `"manual"`, `"scroll_stop"`, `"pv"`) is also included in the event payload for each item in the `event_data` array, allowing you to track what triggered each impression.

---

## Sample Apps

The Sample apps include **Viewable Impressions** demos demonstrating different integration patterns:

### UIKit

A complete example using `UITableView` with automatic scroll tracking:
- **20 sample items** displayed in a table view
- **Automatic tracking** on scroll stop (`scrollViewDidEndDragging` and `scrollViewDidEndDecelerating`)
- **Manual refresh button** in the navigation bar
- **Dwell time pattern**: Calls `refreshState()` immediately, then schedules a second call after `minimumDwellTime` (0.5s)
- Demonstrates tracking in `willDisplay` cell delegate method
- Shows how to handle page view (`pv`) trigger reason on `viewDidAppear`

### SwiftUI

A SwiftUI implementation using `ScrollView`:
- **20 sample items** in a `LazyVStack`
- Uses `analyticsViewableImpressionManual` view modifier for declarative tracking
- **Drag gesture tracking** to detect scroll stop
- **Manual refresh button** in the toolbar
- Demonstrates `SwiftUIManualViewableImpressionTracker` usage
- Shows how to use `UIScreen.main.bounds` as viewport for SwiftUI views


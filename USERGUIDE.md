---
sidebar_position: 22
id: ios-analytics-viewable-impressions
slug: /analytics-sdk/ios/ios-viewable-impressions
title: Viewable impressions
added_version: 11.1.0
updated_version: 11.1.0
changelog: ./CHANGELOG.md
---

## Viewable impressions

Manual viewable impressions allow client applications to register on-screen views and call `refreshState` to receive items when visibility and dwell rules are satisfied. RakutenAnalytics **11.1.0** exposes this flow for UIKit and SwiftUI.

The sections below first summarize what the feature measures, then cover integration steps, APIs, configuration, example payloads, and technical behavior (including limits and `pgid` correlation).

### In simple terms

**Viewable impressions** address the question: *which items did the end user actually see on screen—not only scroll past?*

The SDK can return a list of items that remained visible long enough and with sufficient on-screen area. That list supports analytics and stakeholder conversations. It is **not** equivalent to “every row rendered,” and measurement is **not** fully automatic: **client code** decides **when** to evaluate visibility and **when** to send results into the analytics pipeline.

### Integration steps (overview)

1. **Register** each in-scope item by linking an on-screen view to product or content data (`track` / SwiftUI modifier).
2. **Request evaluation** when appropriate—commonly when scrolling **settles** or after an explicit interaction. The SDK applies visibility and dwell rules and returns qualifying items in a batch when ready.

Registration alone does not emit data until **`refreshState`** runs; the SDK does not poll continuously in the background.

### Default measurement rules

Default thresholds apply out of the box; client applications may override them in code.

| What is measured | Default | Plain-language meaning |
| --- | --- | --- |
| On-screen share of the item | More than half (`50%`) | A thin strip at the edge does not qualify. |
| Time at or above that visibility | `1.5` seconds | The item must remain in view long enough to count as “viewed.” |

For an item to appear in a result, **all** of the following must hold:

- It was registered.
- Enough of it is visible (above the configured threshold).
- It remained visible for at least the dwell time.
- **`refreshState`** was invoked so the SDK could evaluate.

**Example timeline**

```text
Row becomes visible  →  integration registers it
refreshState runs   →  SDK starts dwell measurement if the row is visible
After ~1.5s (defaults)  →  row may appear in the result if still visible enough
```

### Recommendations

These recommendations follow from the current implementation and aim to limit UI overhead and ambiguous analytics.

:::tip When to call `refreshState`

Call **`refreshState`** when scrolling **settles**—for example from **`scrollViewDidEndDecelerating`** and, when there is no deceleration, **`scrollViewDidEndDragging`**—not from **`scrollViewDidScroll`** on every frame. Tying refresh to **continuous** scrolling multiplies work; cost scales with **call frequency × number of registered items**.

:::

:::tip `UITableView` / `UICollectionView` and reuse

With normal **cell reuse**, registrations usually track **roughly the live cell pool** (on the order of a **screenful**), not “every row in the data source.” Each reuse replaces the previous item for that view. **`refreshState`** still evaluates **each** entry currently in the tracker, but that set stays **small** in typical list screens. **Custom** layouts that **`track`** many **non‑reused** views (or that never **`untrack`**) can grow registration count and cost per refresh.

:::

:::tip SwiftUI refresh cadence

Do **not** drive **`refreshState`** from **high‑frequency** gestures (e.g. every drag end) or tight **`onChange`** loops. Prefer the same **scroll‑stop** idea as UIKit—**manual** actions, or patterns that fire when scrolling **finishes**—and use **`unregister`** / **`clear`** when rows leave the hierarchy so registrations stay bounded.

:::

:::tip Scope of registered items

Each **`refreshState`** pass considers **every** registered item, not only rows that happen to be visible in the viewport. Remove registrations when items are no longer in scope (`untrack` / `clear` / `disable` patterns) so stale or off‑screen content does not stay in the map unnecessarily—especially important when reuse does **not** apply.

:::

:::tip Downstream batch size

A single refresh can produce **many** rows in one `viewable_data` array; the SDK does **not** split batches. If reporting pipelines or backends impose **payload or queue limits**, align with the **analytics program** and platform owners **before** production rollout, and plan splitting or trimming **in client code** if required.

:::

:::tip Correlating with page visits (`pgid`)

When reporting must link “what was viewed” to “which page visit,” the **same** **`pgid`** should appear on the page-visit event and on the event carrying **`viewable_data`**. The SDK does **not** inject `pgid`; it is supplied in the same parameter dictionary passed to `RAnalyticsRATTracker.shared().event(withEventType:parameters:)`. See [Correlating events (`pgid`)](#correlating-events-pgid).

:::

:::note Sample applications

Bundled samples attach `viewable_data` to a **manual** page-visit event to illustrate wiring. **Product-specific** rules may use a different event type or timing—the sample demonstrates integration shape, not a mandatory product policy.

:::

### Supported on-screen content

Manual tracking supports **any standard UIKit view**, including table and collection cells, plain views, and custom layouts. When a scroll view is supplied as the viewport, it is used only for **visibility evaluation**, not to alter layout.

---

### API overview (developers)

#### UIKit (manual)

1. Create a `ViewableImpressionTracker`.
2. Optionally set `minimumDwellTime` and `minimumVisibilityPercentage`.
3. Call `enableTracking()`.
4. Register with `track(view:item:itemPosition:)`.
5. Call `refreshState(viewportView:viewportInsets:onResult:)`.

#### SwiftUI (manual)

1. Create a `SwiftUIManualViewableImpressionTracker(...)`.
2. Apply `analyticsViewableImpressionManual(tracker:item:itemPosition:)`.
3. Call `refreshState(viewport:viewportInsets:onResult:)`.

#### Shared types

- `ViewableImpressionTrackable` — trackable item models must expose id, title, category, and related fields per the protocol.

### Configuration (code)

| Setting | Default | Role |
| --- | --- | --- |
| `minimumDwellTime` | `1.5` seconds | Minimum time the item stays visible. |
| `minimumVisibilityPercentage` | `0.5` | Visibility must be **strictly greater** than this (default ≈ more than half of the item). |

### UIKit integration

#### Trackable model

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
    var itemPrice: String { price }
}
```

#### Tracker setup

```swift
let tracker = ViewableImpressionTracker()
tracker.minimumDwellTime = 1.5
tracker.minimumVisibilityPercentage = 0.5
tracker.enableTracking()
```

#### Registration and refresh

```swift
tracker.track(view: cell.contentView, item: product, itemPosition: indexPath.row)

tracker.refreshState(viewportView: listContainer) { eventParameters in
    handleQualifiedItems(eventParameters)
}
```

Typical pattern: refresh after scrolling stops:

```swift
func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    tracker.refreshState(viewportView: scrollView) { eventParameters in
        handleQualifiedItems(eventParameters)
    }
}
```

### SwiftUI integration

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

### Refresh result

`refreshState` supplies `eventParameters` suitable for `RAnalyticsRATTracker.shared().event(withEventType:parameters:)`.

- If items are still accumulating dwell time, the completion handler may run **once** after a short delay (there is **no** continuous background poll).
- To obtain a **later** batch (e.g. after further scrolling), call **`refreshState`** again.

**Minimal handling**

```swift
tracker.refreshState(viewportView: listContainer) { eventParameters in
    handleQualifiedItems(eventParameters)
}
```

**Example: page-visit (PV) event**

```swift
if let eventParameters = eventParameters {
    RAnalyticsRATTracker.shared().event(
        withEventType: RAnalyticsEvent.Name.pageVisitForRAT,
        parameters: eventParameters
    ).track()
}
```

**Example JSON** (`eventParameters` from `refreshState`):

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
    }
  ]
}
```

**Field reference**

| Field | Meaning |
| --- | --- |
| `item_id` | Stable product or content id |
| `item_title` | Title shown to the end user |
| `visibility_percentage` | Share of the item visible (`0.0`–`1.0`) |
| `dwell_time` | Time visible (seconds) |
| `item_position` | List position (iOS) |
| `screen_name` | View controller type name when available (UIKit) |
| `viewable_impression_timestamp` | Single timestamp for the batch |

### SDK behavior (technical reference)

The following reflects **current SDK implementation** so engineering and analytics can align expectations. **Quantitative** performance budgets (frame times, maximum safe registration counts) require profiling on target hardware per application.

#### Batch size

One successful refresh yields **one** `viewable_data` array containing **all** qualifying items from that pass. The SDK does **not** cap or split the array.

:::warning Large batches and platform limits

Downstream reporting or transport layers may apply **independent** limits on payload size or queue depth; those are **not** enforced in the viewable tracker. For potentially **very large** batches, limits should be confirmed with **RAT / platform owners**, with splitting or trimming implemented **client-side** if necessary.

:::

#### Cost per refresh

Each `refreshState` invocation processes **every** registered item. Cost grows with registration count and refresh frequency. On UIKit, visibility evaluation for registered views runs on the **main thread**, so aggressive refresh patterns can affect scroll smoothness.

:::caution High-frequency refresh during scroll

Without profiling data, **`refreshState`** should not be invoked continuously during fast scrolling when many rows remain registered. **Scroll-end** or **throttled** refresh patterns are preferred; registrations should remain limited to **in-scope** items.

:::

#### Re-qualification

After an item has qualified **once** while visible, it does **not** re-emit on every subsequent refresh until visibility **drops below** the threshold (resetting state) and the item qualifies again.

#### Clearing and cell reuse (UIKit)

- `untrack(itemId:)` — remove one item.
- `clearManualTracking()` — clear all registrations.
- `disableTracking()` — disable tracking, clear state, cancel pending dwell work.

When a **recycled** cell is bound to a **new** item id, `track` removes conflicting registrations for that view so obsolete ids are not reported.

#### Clearing (SwiftUI)

`unregister(itemId:)` or `clear()` when content is removed; the manual modifier calls `unregister` from `onDisappear`.

#### Dwell follow-up

If nothing qualifies but dwell is still counting down, the SDK schedules **one** follow-up evaluation after the **shortest** remaining wait—not a permanent poll.

### Correlating events (`pgid`) {#correlating-events-pgid}

:::info Role of `pgid`

`pgid` is a **page-level identifier** attached to events so reporting can relate a page visit to other events on the same screen (e.g. a viewable batch).

:::

- The viewable tracker does **not** set `pgid`; it must be merged into the same `parameters` passed to `RAnalyticsRATTracker.shared().event(withEventType:parameters:)`.

:::caution `pgid` format validation

The RAT layer validates `pgid`. Expected shape: **`{deviceIdentifier}_{timestamp}`**—exactly **two** segments separated by `_`, first segment equal to the SDK **device identifier (ckp)**, second segment a valid **time** value. **Invalid** values are **omitted** from the transmitted payload, so correlation in reports may be lost without an obvious client-side error.

:::

### Automatic page visits

No SDK flag **automatically** sends a page visit when viewable thresholds are met. **Product and client teams** define when page visits fire and whether `viewable_data` is attached to PV or to another event type.

### Sample applications

The repository includes **Viewable impressions** demos for UIKit and SwiftUI.

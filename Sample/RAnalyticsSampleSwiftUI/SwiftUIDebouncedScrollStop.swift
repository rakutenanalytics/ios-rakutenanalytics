import SwiftUI

// MARK: - Scroll offset → debounced “scroll settled” (pure SwiftUI)

/// Vertical scroll offset of the scroll content’s leading edge in the named coordinate space.
/// Place `ScrollMinYReporter` as the **first** subview inside `ScrollView` content, and put
/// `.coordinateSpace(name:)` on the same `ScrollView`.
enum ScrollContentMinYPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Zero-height sentinel that reports `minY` of the scroll content in `coordinateSpaceName`.
struct ScrollMinYReporter: View {
    var coordinateSpaceName: String = "viewableScroll"

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: ScrollContentMinYPreferenceKey.self,
                    value: proxy.frame(in: .named(coordinateSpaceName)).minY
                )
        }
        .frame(height: 0)
    }
}

extension View {
    /// When the scroll offset stops changing for `delay` seconds (user stopped dragging / deceleration finished),
    /// runs `action`. Typical host-app pattern instead of a manual Refresh button.
    ///
    /// Requirements: `ScrollView` uses `.coordinateSpace(name:)`, and the scroll content’s first child is
    /// `ScrollMinYReporter(coordinateSpaceName:)` with the **same** name.
    func onDebouncedScrollSettle(
        delay: TimeInterval = 0.35,
        action: @escaping () -> Void
    ) -> some View {
        modifier(DebouncedScrollSettleModifier(delay: delay, action: action))
    }
}

private struct DebouncedScrollSettleModifier: ViewModifier {
    let delay: TimeInterval
    let action: () -> Void

    @State private var pendingWorkItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content.onPreferenceChange(ScrollContentMinYPreferenceKey.self) { _ in
            pendingWorkItem?.cancel()
            let work = DispatchWorkItem { action() }
            pendingWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }
    }
}

import Foundation
import UIKit

// MARK: - StatusBarOrientationGettable

protocol StatusBarOrientationGettable {
    var analyticsIsLandscape: Bool { get }
}

/// Resolves the application when an event payload is built.
///
/// The SDK can be initialized before `UIApplication.shared` is available, so retaining the
/// application instance during dependency construction would permanently use the portrait fallback.
final class RAnalyticsApplicationOrientationProvider: StatusBarOrientationGettable {
    private let application: () -> StatusBarOrientationGettable?

    init(application: @escaping () -> StatusBarOrientationGettable? = {
        UIApplication.RAnalyticsSharedApplication
    }) {
        self.application = application
    }

    var analyticsIsLandscape: Bool {
        application()?.analyticsIsLandscape ?? false
    }
}

extension UIApplication: StatusBarOrientationGettable {
    var analyticsIsLandscape: Bool {
        #if os(iOS)
        return activeWindowScene?.interfaceOrientation.isLandscape ?? false
        #elseif os(tvOS)
        // Apple TV UI is landscape-first; `UIInterfaceOrientation` is unavailable on tvOS.
        return true
        #endif
    }

    /// The window scene UIKit considers most representative of the foreground UI, when one exists.
    ///
    /// Order: foreground‑active scenes (preferring one that contains the key window), then
    /// foreground‑inactive, then any remaining window scene.
    ///
    /// If there are no connected window scenes, falls back to
    /// ``UIApplicationDelegate/window``’s scene when present.
    var activeWindowScene: UIWindowScene? {
        let windowScenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        guard !windowScenes.isEmpty else {
            return delegate?.window??.windowScene
        }

        func pickPreferringKeyWindow(from pool: [UIWindowScene]) -> UIWindowScene? {
            if let withKeyWindow = pool.first(where: { $0.windows.contains(where: \.isKeyWindow) }) {
                return withKeyWindow
            }
            return pool.first
        }

        let foregroundActive = windowScenes.filter { $0.activationState == .foregroundActive }
        if let scene = pickPreferringKeyWindow(from: foregroundActive) {
            return scene
        }

        let foregroundInactive = windowScenes.filter { $0.activationState == .foregroundInactive }
        if let scene = pickPreferringKeyWindow(from: foregroundInactive) {
            return scene
        }

        return pickPreferringKeyWindow(from: windowScenes)
    }
}

// MARK: - ApplicationStateGettable
protocol ApplicationStateGettable {
    var applicationState: UIApplication.State { get }
}

extension UIApplication: ApplicationStateGettable {}

// MARK: - RAnalyticsSharedApplication

extension UIApplication {
    static var RAnalyticsSharedApplication: UIApplication? {
        UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication
    }
}

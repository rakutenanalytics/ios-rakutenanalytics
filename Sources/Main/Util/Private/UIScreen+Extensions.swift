import Foundation
import UIKit

protocol Screenable {
    var bounds: CGRect { get }
}

extension UIScreen: Screenable {}

extension UIScreen {
    /// A ``Screenable`` backed by ``UIWindowScene/screen`` when a scene exists.
    ///
    /// Prefer ``UIWindowScene/screen`` via ``UIApplication/activeWindowScene`` when available.
    /// Resolves bounds on each read so early SDK initialization (before a window scene exists) does not
    /// permanently capture `0×0`. If no window scene can be resolved, uses zero ``CGRect`` bounds
    /// (avoids deprecated ``UIScreen/main``).
    static var screenableFromScene: Screenable {
        SceneBackedScreen()
    }
}

private struct SceneBackedScreen: Screenable {
    var bounds: CGRect {
        guard let scene = UIApplication.RAnalyticsSharedApplication?.activeWindowScene else {
            return .zero
        }
        return scene.screen.bounds
    }
}

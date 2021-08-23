import UIKit

// MARK: - RMoriType
enum RMoriType: Int {
    case portrait = 1
    case landscape = 2
}

// MARK: - MoriGettable
protocol MoriGettable: AnyObject {
    var mori: RMoriType { get }
}

// MARK: - RStatusBarOrientationHandler

/// A class to handle the status bar orientation
/// The injected dependency has to conform to StatusBarOrientationGettable
/// Initialization example: RStatusBarOrientationHandler(UIApplication.shared)
final class RStatusBarOrientationHandler {
    private let application: StatusBarOrientationGettable?

    init(application: StatusBarOrientationGettable?) {
        self.application = application
    }
}

extension RStatusBarOrientationHandler: MoriGettable {
    private var unsafeMori: RMoriType {
        guard let application = application else {
            // Note: [UIApplication sharedApplication] is not available for App Extension
            return .portrait // default value
        }
        return application.analyticsStatusBarOrientation.isLandscape ? .landscape : .portrait
    }

    /// Executes a closure on the main thread
    ///
    /// - Returns: `RMoriType.portrait` if the status bar orientation is in portrait mode
    /// `RMoriType.landscape` if the status bar orientation is in landscape mode
    ///
    /// - Note: returns RMoriType.portrait if UIApplication.shared is not available
    var mori: RMoriType {
        MainThreadExecutor.run { unsafeMori }
    }
}

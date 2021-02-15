import UIKit

// MARK: - AnalyticsStatusBarOrientationGettable
@objc public protocol AnalyticsStatusBarOrientationGettable {
    var analyticsStatusBarOrientation: UIInterfaceOrientation { get }
}

@objc extension UIApplication: AnalyticsStatusBarOrientationGettable {
    public var analyticsStatusBarOrientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *) {
            guard let interfaceOrientation = windows.first?.windowScene?.interfaceOrientation else {
                return .portrait // default value
            }
            return interfaceOrientation

        } else {
            return statusBarOrientation
        }
    }
}

// MARK: - RMoriType
@objc public enum RMoriType: Int {
    case portrait = 1
    case landscape = 2
}

// MARK: - MoriGettable
@objc public protocol MoriGettable: class {
    var mori: RMoriType { get }
}

// MARK: - RStatusBarOrientationHandler

/// A class to handle the status bar orientation
/// The injected dependency has to conform to AnalyticsStatusBarOrientationGettable
/// Initialization example: RStatusBarOrientationHandler(UIApplication.shared)
@objc public final class RStatusBarOrientationHandler: NSObject {
    private let application: AnalyticsStatusBarOrientationGettable?

    @objc public init(application: AnalyticsStatusBarOrientationGettable?) {
        self.application = application
        super.init()
    }
}

@objc extension RStatusBarOrientationHandler: MoriGettable {
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
    public var mori: RMoriType {
        MainThreadExecutor.run { unsafeMori }
    }
}

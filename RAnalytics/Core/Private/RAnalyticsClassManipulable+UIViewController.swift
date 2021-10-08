import UIKit
import struct RSDKUtils.RLogger

extension UIViewController: RAnalyticsClassManipulable, RuntimeLoadable {

    @objc public static func loadSwift() {
        replaceMethod(#selector(viewDidAppear),
                      inClass: self,
                      with: #selector(r_autotrack_viewDidAppear),
                      onlyIfPresent: true)
        RLogger.verbose("Installed auto-tracking hooks for UIViewController")
    }

    @objc func r_autotrack_viewDidAppear(_ animated: Bool) {
        RLogger.verbose("View did appear for \(type(of: self))")
        AnalyticsManager.shared().launchCollector.didPresentViewController(self)
        r_autotrack_viewDidAppear(animated)
    }
}

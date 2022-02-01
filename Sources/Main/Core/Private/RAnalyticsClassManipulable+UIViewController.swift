import UIKit
#if canImport(RSDKUtils)
import struct RSDKUtils.RLogger
#else // SPM version
import RLogger
#endif

extension UIViewController: RAnalyticsClassManipulable, RuntimeLoadable {

    @objc public static func loadSwift() {
        replaceMethod(#selector(viewDidAppear),
                      inClass: self,
                      with: #selector(rAutotrackViewDidAppear),
                      onlyIfPresent: true)
        RLogger.verbose(message: "Installed auto-tracking hooks for UIViewController")
    }

    @objc func rAutotrackViewDidAppear(_ animated: Bool) {
        RLogger.verbose(message: "View did appear for \(type(of: self))")
        AnalyticsManager.shared().launchCollector.didPresentViewController(self)
        rAutotrackViewDidAppear(animated)
    }
}

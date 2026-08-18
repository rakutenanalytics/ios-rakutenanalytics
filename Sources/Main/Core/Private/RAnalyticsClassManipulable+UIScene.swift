import UIKit

extension UIScene: RAnalyticsClassManipulable {
    private static var stateRestorationHooksAreInstalled = false
    private static let installLock = NSLock()

    static func installStateRestorationAutoTrackingHooks() {
        installLock.lock()
        defer { installLock.unlock() }
        guard !stateRestorationHooksAreInstalled else {
            return
        }
        stateRestorationHooksAreInstalled = true

        replaceMethod(#selector(extendStateRestoration),
                      inClass: self,
                      with: #selector(rAutotrack_extendStateRestoration),
                      onlyIfPresent: false)
        replaceMethod(#selector(completeStateRestoration),
                      inClass: self,
                      with: #selector(rAutotrack_completeStateRestoration),
                      onlyIfPresent: false)
        RLogger.verbose(message: "Installed auto-tracking hooks for UIScene state restoration")
    }

    @objc func rAutotrack_extendStateRestoration() {
        RAnalyticsSessionStartCoordinator.shared.stateRestorationExtended()
        rAutotrack_extendStateRestoration()
    }

    @objc func rAutotrack_completeStateRestoration() {
        rAutotrack_completeStateRestoration()
        RAnalyticsSessionStartCoordinator.shared.stateRestorationCompleted()
    }
}

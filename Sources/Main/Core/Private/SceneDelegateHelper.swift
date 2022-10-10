import Foundation
import UIKit

#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RLogger
#endif

@available(iOS 13.0, *)
enum SceneDelegateHelper {

    /// Autotrack the UISceneDelegate functions.
    static func autoTrack() {
        let bundle: EnvironmentBundle = Bundle.main

        guard let applicationSceneManifest = bundle.applicationSceneManifest else {
            RLogger.debug(message: "The app's Info.plist is not configured with UIApplicationSceneManifest.")
            return
        }

        guard let sceneDelegateClassName = applicationSceneManifest.firstSceneDelegateClassName else {
            RLogger.debug(message: "UISceneDelegateClassName could not be retrieved.")
            return
        }

        UIWindowScene.rAutotrackSceneDelegateFunctions(sceneDelegateClassName)
        RLogger.debug(message: "\(sceneDelegateClassName) is autotracked.")
    }
}

import Foundation
import UIKit

enum SceneDelegateHelper {

    /// Autotrack the UISceneDelegate functions declared in the host app's Info.plist.
    static func autoTrack(bundle: EnvironmentBundle = Bundle.main) {
        guard let applicationSceneManifest = bundle.applicationSceneManifest else {
            RLogger.error(message: "UIApplicationSceneManifest is missing from Info.plist — referral, deeplink, and geo launch auto-tracking are disabled. " +
                "Adopt the UIKit scene lifecycle and add UIApplicationSceneManifest to Info.plist. See the v12 migration guide.")
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.analyticsManagerErrorDomain,
                                             code: ErrorCode.sceneDelegateManifestMissing.rawValue,
                                             description: ErrorDescription.sceneDelegateManifestMissing,
                                             reason: ErrorReason.sceneDelegateManifestMissing))
            return
        }

        let classNames = applicationSceneManifest.allSceneDelegateClassNames
        guard !classNames.isEmpty else {
            RLogger.debug(message: "No UISceneDelegateClassName entries found in scene configurations.")
            ErrorRaiser.raise(.detailedError(domain: ErrorDomain.analyticsManagerErrorDomain,
                                             code: ErrorCode.sceneDelegateClassNameMissing.rawValue,
                                             description: ErrorDescription.sceneDelegateClassNameMissing,
                                             reason: ErrorReason.sceneDelegateClassNameMissing))
            return
        }

        for className in classNames {
            UIWindowScene.rAutotrackSceneDelegateFunctions(className)
            RLogger.debug(message: "\(className) is autotracked.")
        }
    }
}

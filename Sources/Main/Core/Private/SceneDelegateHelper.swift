import Foundation
import UIKit

#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RLogger
#endif

@available(iOS 13.0, *)
enum SceneDelegateHelper {
    private enum Keys {
        static let aplicationSceneManifestKey = "UIApplicationSceneManifest"
    }

    /// Autotrack the UISceneDelegate functions.
    static func autoTrack() {
        guard let dict = Bundle.main.object(forInfoDictionaryKey: Keys.aplicationSceneManifestKey) as? [String: Any],
              let data = try? JSONSerialization.data(withJSONObject: dict, options: []) else {
            RLogger.debug(message: "The app's Info.plist is not configured with UIApplicationSceneManifest.")
            return
        }
        let decoder = JSONDecoder()
        let manifest = try? decoder.decode(ApplicationSceneManifest.self, from: data)
        guard let sceneDelegateClassName = manifest?.sceneConfigurations?.windowSceneSessionRoleApplication?.first?.sceneDelegateClassName else {
            RLogger.debug(message: "UISceneDelegateClassName could not be retrieved.")
            return
        }
        UIWindowScene.rAutotrackSceneDelegateFunctions(sceneDelegateClassName)
        RLogger.debug(message: "\(sceneDelegateClassName) is autotracked.")
    }
}

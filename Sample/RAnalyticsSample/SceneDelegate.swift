import UIKit
import RakutenAnalytics

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }

        if let url = connectionOptions.urlContexts.first?.url {
            DeepLinkManager.record(url: url, entryPoint: "willConnectTo(url)")
        }
        if let url = connectionOptions.userActivities.first?.webpageURL {
            DeepLinkManager.record(url: url, entryPoint: "willConnectTo(universalLink)")
        }
    }

    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        if let url = urlContexts.first?.url {
            DeepLinkManager.record(url: url, entryPoint: "openURLContexts")
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        DeepLinkManager.record(url: userActivity.webpageURL, entryPoint: "continue")
    }
}

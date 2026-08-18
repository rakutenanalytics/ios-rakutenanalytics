import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // Main.storyboard is attached via UISceneStoryboardFile in Info.plist.
        // UIKit owns window creation — do not create a second window here.
        guard (scene as? UIWindowScene) != nil else { return }
    }
}

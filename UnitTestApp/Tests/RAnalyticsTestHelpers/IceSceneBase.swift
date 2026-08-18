import Foundation
import UIKit

final class IceSceneBaseManipulator: NSObject {
    static func addInstanceMethod(_ destinationSelector: Selector,
                                  with sourceSelector: Selector,
                                  fromClass: AnyClass,
                                  toClass: AnyClass) {
        guard let sourceMethod = class_getInstanceMethod(fromClass, sourceSelector) else {
            return
        }
        let sourceIMP = method_getImplementation(sourceMethod)
        let sourceTypes = method_getTypeEncoding(sourceMethod)

        if class_getInstanceMethod(toClass, destinationSelector) == nil {
            class_addMethod(toClass, destinationSelector, sourceIMP, sourceTypes)
            return
        }

        // Force the source selector on the target class to point to Ice's implementation,
        // then exchange deterministically with the destination selector.
        class_replaceMethod(toClass, sourceSelector, sourceIMP, sourceTypes)

        guard let destinationMethod = class_getInstanceMethod(toClass, destinationSelector),
              let sourceMethodOnTarget = class_getInstanceMethod(toClass, sourceSelector) else {
            return
        }
        method_exchangeImplementations(destinationMethod, sourceMethodOnTarget)
    }
}

/// Simulates a third-party library that swizzles UISceneDelegate methods before the SDK.
final class IceSceneBase: NSObject, SceneDelegating {
    private let willConnectSelector = #selector(UISceneDelegate.scene(_:willConnectTo:options:))
    private let openURLContextsSelector = #selector(UISceneDelegate.scene(_:openURLContexts:))
    private let continueSelector = #selector(UISceneDelegate.scene(_:continue:))

    static var willConnectIsCalled = false
    static var openURLContextsIsCalled = false
    static var continueIsCalled = false

    func configureForSceneDelegateClass(_ sceneDelegateClass: AnyClass) {
        IceSceneBaseManipulator.addInstanceMethod(
            willConnectSelector,
            with: #selector(IceSceneBase._ice_scene(_:willConnectTo:options:)),
            fromClass: IceSceneBase.self,
            toClass: sceneDelegateClass)

        IceSceneBaseManipulator.addInstanceMethod(
            openURLContextsSelector,
            with: #selector(IceSceneBase._ice_scene(_:openURLContexts:)),
            fromClass: IceSceneBase.self,
            toClass: sceneDelegateClass)

        IceSceneBaseManipulator.addInstanceMethod(
            continueSelector,
            with: #selector(IceSceneBase._ice_scene(_:continue:)),
            fromClass: IceSceneBase.self,
            toClass: sceneDelegateClass)
    }

    @objc func _ice_scene(_ scene: UIScene,
                          willConnectTo session: UISceneSession,
                          options connectionOptions: UIScene.ConnectionOptions) {
        IceSceneBase.willConnectIsCalled = true
    }

    @objc func _ice_scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        IceSceneBase.openURLContextsIsCalled = true
    }

    @objc func _ice_scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        IceSceneBase.continueIsCalled = true
    }
}

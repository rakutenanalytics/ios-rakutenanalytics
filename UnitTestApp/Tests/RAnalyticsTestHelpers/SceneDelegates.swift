import Foundation
import UIKit

// MARK: - SceneDelegating protocol

protocol SceneDelegating {
    static var willConnectIsCalled: Bool { get set }
    static var openURLContextsIsCalled: Bool { get set }
    static var continueIsCalled: Bool { get set }
}

// MARK: - SceneDelegates not swizzled by IceSceneBase

final class EmptySceneDelegate: NSObject, UISceneDelegate {
}

final class PartialSceneDelegateWillConnect: NSObject, UISceneDelegate, SceneDelegating {
    static var willConnectIsCalled = false
    static var openURLContextsIsCalled = false
    static var continueIsCalled = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        type(of: self).willConnectIsCalled = true
    }
}

final class PartialSceneDelegateOpenURL: NSObject, UISceneDelegate, SceneDelegating {
    static var willConnectIsCalled = false
    static var openURLContextsIsCalled = false
    static var continueIsCalled = false

    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        type(of: self).openURLContextsIsCalled = true
    }
}

final class PartialSceneDelegateContinue: NSObject, UISceneDelegate, SceneDelegating {
    static var willConnectIsCalled = false
    static var openURLContextsIsCalled = false
    static var continueIsCalled = false

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        type(of: self).continueIsCalled = true
    }
}

final class FullSceneDelegate: NSObject, UISceneDelegate, SceneDelegating {
    static var willConnectIsCalled = false
    static var openURLContextsIsCalled = false
    static var continueIsCalled = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        type(of: self).willConnectIsCalled = true
    }

    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        type(of: self).openURLContextsIsCalled = true
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        type(of: self).continueIsCalled = true
    }
}

// MARK: - SceneDelegates pre-swizzled by IceSceneBase

final class SwizzledEmptySceneDelegate: NSObject, UISceneDelegate {
    override init() {
        super.init()
        IceSceneBase().configureForSceneDelegateClass(type(of: self))
    }
}

final class SwizzledPartialSceneDelegateWillConnect: NSObject, UISceneDelegate, SceneDelegating {
    static var willConnectIsCalled = false
    static var openURLContextsIsCalled = false
    static var continueIsCalled = false

    override init() {
        super.init()
        IceSceneBase().configureForSceneDelegateClass(type(of: self))
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        type(of: self).willConnectIsCalled = true
    }
}

final class SwizzledPartialSceneDelegateOpenURL: NSObject, UISceneDelegate, SceneDelegating {
    static var willConnectIsCalled = false
    static var openURLContextsIsCalled = false
    static var continueIsCalled = false

    override init() {
        super.init()
        IceSceneBase().configureForSceneDelegateClass(type(of: self))
    }

    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        type(of: self).openURLContextsIsCalled = true
    }
}

final class SwizzledFullSceneDelegate: NSObject, UISceneDelegate, SceneDelegating {
    static var willConnectIsCalled = false
    static var openURLContextsIsCalled = false
    static var continueIsCalled = false

    override init() {
        super.init()
        IceSceneBase().configureForSceneDelegateClass(type(of: self))
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        type(of: self).willConnectIsCalled = true
    }

    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        type(of: self).openURLContextsIsCalled = true
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        type(of: self).continueIsCalled = true
    }
}

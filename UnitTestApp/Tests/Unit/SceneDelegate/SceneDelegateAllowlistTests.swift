import Testing
import UIKit
@testable import RakutenAnalytics

private final class UnregisteredSceneDelegate: NSObject, UISceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {}
}

private final class RegisteredSceneDelegate: NSObject, UISceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {}
}

@Suite("SceneDelegateAllowlist")
struct SceneDelegateAllowlistTests {
    static let rAutotrackWillConnectSelector = #selector(UIWindowScene.rAutotrackScene(_:willConnectTo:options:))
    static let rAutotrackOpenURLSelector = #selector(UIWindowScene.rAutotrackScene(_:openURLContexts:))
    static let rAutotrackContinueSelector = #selector(UIWindowScene.rAutotrackScene(_:continue:))

    @Test("does not swizzle scene delegate classes that are not registered in the allowlist")
    func testDoesNotSwizzleUnregisteredSceneDelegateClass() {
        let delegateType = UnregisteredSceneDelegate.self
        let delegate = UnregisteredSceneDelegate()

        UIWindowScene.swizzleSceneDelegateFunctions(delegateType)

        #expect(type(of: delegate).instancesRespond(to: Self.rAutotrackWillConnectSelector) == false)
        #expect(type(of: delegate).instancesRespond(to: Self.rAutotrackOpenURLSelector) == false)
        #expect(type(of: delegate).instancesRespond(to: Self.rAutotrackContinueSelector) == false)
    }

    @Test("swizzles scene delegate classes after they are registered in the allowlist")
    func testSwizzlesRegisteredSceneDelegateClass() {
        let delegateType = RegisteredSceneDelegate.self
        let delegate = RegisteredSceneDelegate()

        UIWindowScene.registerSwizzlableSceneDelegateClass(delegateType)
        UIWindowScene.swizzleSceneDelegateFunctions(delegateType)

        #expect(delegate.responds(to: #selector(UISceneDelegate.scene(_:willConnectTo:options:))))
        #expect(delegate.responds(to: #selector(UISceneDelegate.scene(_:openURLContexts:))))
        #expect(delegate.responds(to: #selector(UISceneDelegate.scene(_:continue:))))
    }

    #if os(iOS)
    @Test("does not swizzle Apple private scene delegate classes even when registered")
    func testDoesNotSwizzleApplePrivateSceneDelegateClass() {
        guard let keyboardSceneDelegateClass = NSClassFromString("_UIKeyboardInputSceneDelegate"),
              let keyboardSceneDelegateType = keyboardSceneDelegateClass as? UISceneDelegate.Type else {
            // _UIKeyboardInputSceneDelegate is unavailable before iOS 27.
            return
        }

        #expect(NSObject.isApplePrivateClass(keyboardSceneDelegateClass) == true)

        UIWindowScene.registerSwizzlableSceneDelegateClass(keyboardSceneDelegateType)
        UIWindowScene.swizzleSceneDelegateFunctions(keyboardSceneDelegateType)

        #expect(keyboardSceneDelegateClass.instancesRespond(to: Self.rAutotrackWillConnectSelector) == false)
        #expect(keyboardSceneDelegateClass.instancesRespond(to: Self.rAutotrackOpenURLSelector) == false)
        #expect(keyboardSceneDelegateClass.instancesRespond(to: Self.rAutotrackContinueSelector) == false)
    }
    #endif
}

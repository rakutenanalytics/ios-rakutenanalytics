import Testing
import UIKit
@testable import RakutenAnalytics

private final class IdempotentSceneDelegate: NSObject, UISceneDelegate {
    var willConnectIsCalled = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        willConnectIsCalled = true
    }
}

@Suite("SceneDelegateSwizzling")
struct SceneDelegateSwizzlingTests {
    @Test("does not toggle swizzling when the same delegate class is swizzled twice")
    func testDoesNotToggleSwizzlingWhenSwizzledTwice() {
        let delegateType = IdempotentSceneDelegate.self
        let delegate = IdempotentSceneDelegate()

        UIWindowScene.swizzleSceneDelegateFunctions(delegateType)
        UIWindowScene.swizzleSceneDelegateFunctions(delegateType)

        #expect(delegate.responds(to: #selector(UISceneDelegate.scene(_:willConnectTo:options:))))
        #expect(delegate.responds(to: #selector(UISceneDelegate.scene(_:openURLContexts:))))
        #expect(delegate.responds(to: #selector(UISceneDelegate.scene(_:continue:))))
    }
}

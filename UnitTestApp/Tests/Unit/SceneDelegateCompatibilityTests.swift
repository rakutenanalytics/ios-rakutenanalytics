import Testing
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// These tests require a connected UIWindowScene (via UIApplication.shared.connectedScenes),
// which is only available in a running iOS application target — not in SPM test targets,
// which run as plain executables without UIKit application lifecycle.
#if SWIFT_PACKAGE
#else
@Suite("SceneDelegateCompatibilityTests", .serialized)
struct SceneDelegateCompatibilityTests {
    static let willConnectSelector = #selector(UISceneDelegate.scene(_:willConnectTo:options:))
    static let openURLSelector = #selector(UISceneDelegate.scene(_:openURLContexts:))
    static let continueSelector = #selector(UISceneDelegate.scene(_:continue:))
    static let swizzledWillConnectSelector = #selector(UIWindowScene.rAutotrackScene(_:willConnectTo:options:))
    static let swizzledOpenURLSelector = #selector(UIWindowScene.rAutotrackScene(_:openURLContexts:))
    static let swizzledContinueSelector = #selector(UIWindowScene.rAutotrackScene(_:continue:))

    @MainActor
    private func swizzleDelegateClassIfNeeded(_ delegate: NSObject & UISceneDelegate) {
        // `swizzleSceneDelegateFunctions` is idempotent in SDK code, so this is safe and deterministic.
        UIWindowScene.swizzleSceneDelegateFunctions(type(of: delegate))
    }

    @MainActor
    private func resetIceSceneBaseFlags() {
        IceSceneBase.willConnectIsCalled = false
        IceSceneBase.openURLContextsIsCalled = false
        IceSceneBase.continueIsCalled = false
    }

    @MainActor
    private func testScene() -> UIScene? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    }

    @MainActor
    private func invokeOpenURLContexts(on delegate: NSObject & UISceneDelegate, scene: UIScene, contexts: Set<UIOpenURLContext> = []) {
        delegate.scene?(scene, openURLContexts: contexts)
    }

    @MainActor
    private func invokeContinue(on delegate: NSObject & UISceneDelegate, scene: UIScene, userActivity: NSUserActivity) {
        delegate.scene?(scene, continue: userActivity)
    }

    // Keep this suite first because swizzling mutates runtime method tables globally.
    @Suite("when SceneDelegate is pre-swizzled by IceSceneBase")
    struct WhenSceneDelegatePreSwizzledByIceSceneBaseTests {
        @Test("should keep third-party callbacks for methods the app does not implement")
        @MainActor
        func testShouldKeepThirdPartyCallbacksForUnimplementedMethods() {
            let spec = SceneDelegateCompatibilityTests()
            spec.resetIceSceneBaseFlags()

            let sceneDelegate = SwizzledEmptySceneDelegate()
            spec.swizzleDelegateClassIfNeeded(sceneDelegate)

            guard let scene = spec.testScene() else {
                Issue.record("No UIWindowScene available in host application")
                return
            }
            spec.invokeOpenURLContexts(on: sceneDelegate, scene: scene)
            spec.invokeContinue(on: sceneDelegate, scene: scene, userActivity: NSUserActivity(activityType: "test"))

            #expect(IceSceneBase.openURLContextsIsCalled == true)
            #expect(IceSceneBase.continueIsCalled == true)
        }

        @Test("should call the app openURLContexts implementation when that method is implemented")
        @MainActor
        func testShouldCallAppOpenURLContextsImplementation() {
            let spec = SceneDelegateCompatibilityTests()
            spec.resetIceSceneBaseFlags()

            SwizzledPartialSceneDelegateOpenURL.openURLContextsIsCalled = false

            let sceneDelegate = SwizzledPartialSceneDelegateOpenURL()
            spec.swizzleDelegateClassIfNeeded(sceneDelegate)
            guard let scene = spec.testScene() else {
                Issue.record("No UIWindowScene available in host application")
                return
            }
            sceneDelegate.scene(scene, openURLContexts: [])

            #expect(SwizzledPartialSceneDelegateOpenURL.openURLContextsIsCalled == true)
            #expect(IceSceneBase.openURLContextsIsCalled == false)
        }
    }

    @Suite("when SceneDelegate is not swizzled by a third party")
    struct WhenSceneDelegateNotSwizzledByThirdPartyTests {
        @Suite("Empty SceneDelegate")
        struct EmptySceneDelegateTests {
            @Test("should be swizzled as expected")
            @MainActor
            func testIsSwizzledAsExpected() {
                let sceneDelegate = EmptySceneDelegate()
                let spec = SceneDelegateCompatibilityTests()
                spec.swizzleDelegateClassIfNeeded(sceneDelegate)

                #expect(sceneDelegate.responds(to: SceneDelegateCompatibilityTests.willConnectSelector))
                #expect(sceneDelegate.responds(to: SceneDelegateCompatibilityTests.openURLSelector))
                #expect(sceneDelegate.responds(to: SceneDelegateCompatibilityTests.continueSelector))
            }
        }

        @Suite("Partial SceneDelegate with openURLContexts")
        struct PartialSceneDelegateOpenURLTests {
            @Test("should call the scene delegate implementation")
            @MainActor
            func testShouldCallSceneDelegateImplementation() {
                PartialSceneDelegateOpenURL.willConnectIsCalled = false
                PartialSceneDelegateOpenURL.openURLContextsIsCalled = false
                PartialSceneDelegateOpenURL.continueIsCalled = false

                let sceneDelegate = PartialSceneDelegateOpenURL()
                let spec = SceneDelegateCompatibilityTests()
                spec.swizzleDelegateClassIfNeeded(sceneDelegate)
                guard let scene = spec.testScene() else {
                    Issue.record("No UIWindowScene available in host application")
                    return
                }
                sceneDelegate.scene(scene, openURLContexts: [])

                #expect(PartialSceneDelegateOpenURL.openURLContextsIsCalled == true)
                #expect(PartialSceneDelegateOpenURL.willConnectIsCalled == false)
                #expect(PartialSceneDelegateOpenURL.continueIsCalled == false)
            }
        }

        @Suite("Full SceneDelegate")
        struct FullSceneDelegateTests {
            @Test("should call all implemented scene delegate methods")
            @MainActor
            func testShouldCallAllImplementedSceneDelegateMethods() {
                FullSceneDelegate.willConnectIsCalled = false
                FullSceneDelegate.openURLContextsIsCalled = false
                FullSceneDelegate.continueIsCalled = false

                let sceneDelegate = FullSceneDelegate()
                let spec = SceneDelegateCompatibilityTests()
                spec.swizzleDelegateClassIfNeeded(sceneDelegate)

                guard let scene = spec.testScene() else {
                    Issue.record("No UIWindowScene available in host application")
                    return
                }
                sceneDelegate.scene(scene, openURLContexts: [])
                sceneDelegate.scene(scene, continue: NSUserActivity(activityType: "test"))

                #expect(FullSceneDelegate.openURLContextsIsCalled == true)
                #expect(FullSceneDelegate.continueIsCalled == true)
            }
        }
    }

}
#endif

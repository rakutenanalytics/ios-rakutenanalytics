import Testing
import UIKit
@testable import RakutenAnalytics

@Suite("UISceneStateRestorationSwizzling")
struct UISceneStateRestorationSwizzlingTests {
    @Test("installStateRestorationAutoTrackingHooks is idempotent")
    func testInstallStateRestorationAutoTrackingHooksIsIdempotent() {
        UIScene.installStateRestorationAutoTrackingHooks()
        UIScene.installStateRestorationAutoTrackingHooks()
    }
}

import Testing
import UIKit

@testable import RakutenAnalytics

@Suite("SceneDelegateHelper")
struct SceneDelegateHelperTests {
    @Suite("when autoTrack is called")
    struct WhenAutoTrackIsCalledTests {
        @Test("does nothing if UIApplicationSceneManifest is missing in the bundle")
        func testDoesNothingIfUIApplicationSceneManifestIsMissing() {
            let mockBundle = BundleMock()
            mockBundle.applicationSceneManifest = nil
            SceneDelegateHelper.autoTrack(bundle: mockBundle)
            
            #expect(mockBundle.applicationSceneManifest == nil)
        }

        @Test("does nothing if UISceneDelegateClassName is missing in the scene configurations")
        func testDoesNothingIfUISceneDelegateClassNameIsMissing() {
            let mockManifest = RakutenAnalytics.ApplicationSceneManifest(applicationSupportsMultipleScenes: true,sceneConfigurations: RakutenAnalytics.SceneConfigurations(windowSceneSessionRoleApplication: []))
            let mockBundle = BundleMock()
            mockBundle.applicationSceneManifest = mockManifest
            SceneDelegateHelper.autoTrack(bundle: mockBundle)
            
            #expect(mockBundle.applicationSceneManifest?.firstSceneDelegateClassName == nil)
        }

        @Test("should call rAutotrackSceneDelegateFunctions when UISceneDelegateClassName is present in the scene configurations")
        func testShouldCallRAutotrackSceneDelegateFunctionsWhenUISceneDelegateClassNameIsPresent() {
            let sceneDelegateClassName = "MockSceneDelegate"
            let mockManifest = RakutenAnalytics.ApplicationSceneManifest(
                applicationSupportsMultipleScenes: true,
                sceneConfigurations: RakutenAnalytics.SceneConfigurations(
                    windowSceneSessionRoleApplication: [
                        RakutenAnalytics.SceneConfiguration(sceneDelegateClassName: sceneDelegateClassName)
                    ]
                )
            )
            let mockBundle = BundleMock()
            mockBundle.applicationSceneManifest = mockManifest

            SceneDelegateHelper.autoTrack(bundle: mockBundle)

            #expect(mockBundle.applicationSceneManifest != nil)
            #expect(mockBundle.applicationSceneManifest?.firstSceneDelegateClassName == sceneDelegateClassName)
        }
    }
}

// MARK: - Mock Data Structures

struct ApplicationSceneManifest {
    let applicationSupportsMultipleScenes: Bool
    let sceneConfigurations: SceneConfigurations
}

struct SceneConfigurations {
    let windowSceneSessionRoleApplication: [SceneConfiguration]
}

struct SceneConfiguration {
    let sceneDelegateClassName: String
}

extension ApplicationSceneManifest {
    var firstSceneDelegateClassName: String? {
        return sceneConfigurations.windowSceneSessionRoleApplication.first?.sceneDelegateClassName
    }
}

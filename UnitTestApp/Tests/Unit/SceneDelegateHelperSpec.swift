import Quick
import Nimble
import UIKit

@testable import RakutenAnalytics

final class SceneDelegateHelperSpec: QuickSpec {
    override class func spec() {
        describe("SceneDelegateHelper") {
            context("when autoTrack is called") {
                it("does nothing if UIApplicationSceneManifest is missing in the bundle") {
                    let mockBundle = BundleMock()
                    mockBundle.applicationSceneManifest = nil

                    SceneDelegateHelper.autoTrack(bundle: mockBundle)

                    expect(mockBundle.applicationSceneManifest).to(beNil())
                }

                it("does nothing if UISceneDelegateClassName is missing in the scene configurations") {
                    let mockManifest = RakutenAnalytics.ApplicationSceneManifest(
                        applicationSupportsMultipleScenes: true,
                        sceneConfigurations: RakutenAnalytics.SceneConfigurations(windowSceneSessionRoleApplication: [])
                    )
                    let mockBundle = BundleMock()
                    mockBundle.applicationSceneManifest = mockManifest

                    SceneDelegateHelper.autoTrack(bundle: mockBundle)
                    
                    expect(mockBundle.applicationSceneManifest?.firstSceneDelegateClassName).to(beNil())
                }

                it("should call rAutotrackSceneDelegateFunctions when UISceneDelegateClassName is present in the scene configurations") {
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

                    expect(mockBundle.applicationSceneManifest).toNot(beNil())
                    expect(mockBundle.applicationSceneManifest?.firstSceneDelegateClassName).to(equal(sceneDelegateClassName))
                }
            }
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



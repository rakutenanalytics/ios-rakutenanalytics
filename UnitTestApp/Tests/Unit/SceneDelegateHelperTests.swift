import Testing
import UIKit
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif
@testable import RakutenAnalytics

@Suite("SceneDelegateHelper")
struct SceneDelegateHelperTests {
    @Suite("when autoTrack is called", .serialized)
    struct WhenAutoTrackIsCalledTests {
        @Test("reports an error if UIApplicationSceneManifest is missing in the bundle")
        @MainActor
        func testReportsErrorIfUIApplicationSceneManifestIsMissing() async throws {
            let mockBundle = BundleMock()
            mockBundle.applicationSceneManifest = nil
            var reportedError: NSError?
            ErrorRaiser.errorHandler = { reportedError = $0 }

            SceneDelegateHelper.autoTrack(bundle: mockBundle)

            try await TestingHelpers.eventuallyOnMain {
                reportedError?.code == ErrorCode.sceneDelegateManifestMissing.rawValue
            }
            ErrorRaiser.errorHandler = nil
        }

        @Test("reports an error if UISceneDelegateClassName is missing in the scene configurations")
        @MainActor
        func testReportsErrorIfUISceneDelegateClassNameIsMissing() async throws {
            let mockManifest = RakutenAnalytics.ApplicationSceneManifest(
                applicationSupportsMultipleScenes: true,
                sceneConfigurations: RakutenAnalytics.SceneConfigurations(
                    windowSceneSessionRoleApplication: []
                )
            )
            let mockBundle = BundleMock()
            mockBundle.applicationSceneManifest = mockManifest
            var reportedError: NSError?
            ErrorRaiser.errorHandler = { reportedError = $0 }

            SceneDelegateHelper.autoTrack(bundle: mockBundle)

            try await TestingHelpers.eventuallyOnMain {
                reportedError?.code == ErrorCode.sceneDelegateClassNameMissing.rawValue
            }
            ErrorRaiser.errorHandler = nil
        }

        @Test("autotracks every UISceneDelegateClassName entry in scene configurations")
        @MainActor
        func testAutotracksEverySceneDelegateClassNameEntry() async throws {
            let classNames = ["PrimarySceneDelegate", "SecondarySceneDelegate"]
            let mockManifest = RakutenAnalytics.ApplicationSceneManifest(
                applicationSupportsMultipleScenes: true,
                sceneConfigurations: RakutenAnalytics.SceneConfigurations(
                    windowSceneSessionRoleApplication: classNames.map {
                        RakutenAnalytics.SceneConfiguration(sceneDelegateClassName: $0)
                    }
                )
            )
            let mockBundle = BundleMock()
            mockBundle.applicationSceneManifest = mockManifest

            var reportedErrors = [NSError]()
            ErrorRaiser.errorHandler = { reportedErrors.append($0) }

            SceneDelegateHelper.autoTrack(bundle: mockBundle)

            // Each unresolvable class name should trigger exactly one error, proving
            // autoTrack called rAutotrackSceneDelegateFunctions for every entry.
            try await TestingHelpers.eventuallyOnMain {
                reportedErrors.count == classNames.count
            }
            ErrorRaiser.errorHandler = nil
            #expect(reportedErrors.allSatisfy { $0.code == ErrorCode.sceneDelegateClassUnresolved.rawValue })
        }

        @Test("calls rAutotrackSceneDelegateFunctions when UISceneDelegateClassName is present in the scene configurations")
        @MainActor
        func testShouldCallRAutotrackSceneDelegateFunctionsWhenUISceneDelegateClassNameIsPresent() async throws {
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

            var reportedError: NSError?
            ErrorRaiser.errorHandler = { reportedError = $0 }

            SceneDelegateHelper.autoTrack(bundle: mockBundle)

            // The class name is unresolvable, so rAutotrackSceneDelegateFunctions will raise
            // sceneDelegateClassUnresolved — confirming it was invoked.
            try await TestingHelpers.eventuallyOnMain {
                reportedError?.code == ErrorCode.sceneDelegateClassUnresolved.rawValue
            }
            ErrorRaiser.errorHandler = nil
        }
    }
}


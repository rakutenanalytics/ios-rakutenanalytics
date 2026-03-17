// swiftlint:disable line_length

import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif
import UIKit

// Note: This spec does not work in SPM Tests Target
// Because rAutotrackSetSceneDelegate is not called in SPM Tests Target
//
// But rAutotrackSetSceneDelegate is called in an application containing the RAnalytics Swift Package
#if SWIFT_PACKAGE
// rAutotrackSetSceneDelegate is called in the Cocoapods tests target and in an application containing the RAnalytics Pod
#else
private final class CustomSceneDelegate: NSObject, UISceneDelegate {
    var sceneopenURLContextsIsCalled = false
    var sceneContinueIsCalled = false

    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        sceneopenURLContextsIsCalled = true
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        sceneContinueIsCalled = true
    }
}

@Suite("ReferralAppTrackingSceneDelegateTests", .serialized)
struct ReferralAppTrackingSceneDelegateTests {
    static let databaseParentDirectory = FileManager.SearchPathDirectory.documentDirectory
    static let databaseName = "ReferralAppTrackingSceneDelegateTests.db"
    static let databaseTableName = "testTableName_ReferralAppTrackingSceneDelegateTests"
    
    // MARK: - Suite-wide UIKit/swizzling state
    //
    // In the original QuickSpec implementation, the scene delegate was set once and never reset.
    // Repeating `delegate = ...` and/or `swizzleSceneDelegateFunctions(...)` across tests can
    // effectively toggle swizzling and cause one selector (commonly `scene(_:continue:)`) to be
    // unswizzled, leading to "nothing tracked" timeouts.
    private static var suiteUIKitInitialized = false
    private static let suiteSceneDelegate = CustomSceneDelegate()
    private static var suiteWindowScene: UIWindowScene?
    private static var suiteWindow: UIWindow?
    
    @MainActor
    private static func ensureSuiteUIKitInitialized() {
        guard !suiteUIKitInitialized else { return }
        
        // Grab any scene the host app created for the test run.
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        // If the host app hasn't attached a scene yet, retry on the next test's `setUp()`.
        guard let scene else { return }
        suiteWindowScene = scene
        suiteWindow = UIWindow(windowScene: scene)
        
        // Set delegate once for the entire suite (mirrors QuickSpec behavior).
        scene.delegate = suiteSceneDelegate
        
        // IMPORTANT:
        // `swizzleSceneDelegateFunctions(...)` uses `method_exchangeImplementations`, so calling it when
        // the host app already installed hooks will *toggle swizzling off*.
        //
        // Detect whether we are already swizzled by checking if the delegate responds to the "swizzled"
        // selectors (they are added to the recipient class during swizzling).
        let delegateObject = suiteSceneDelegate as NSObject
        let hasOpenURLSwizzle = delegateObject.responds(to: #selector(UIWindowScene.rAutotrackScene(_:openURLContexts:)))
        let hasContinueSwizzle = delegateObject.responds(to: #selector(UIWindowScene.rAutotrackScene(_:continue:)))
        if !hasOpenURLSwizzle || !hasContinueSwizzle {
            UIWindowScene.swizzleSceneDelegateFunctions(type(of: suiteSceneDelegate))
        }
        
        suiteUIKitInitialized = true
    }
    
    var databaseConnection: SQlite3Pointer!
    var database: RAnalyticsDatabase!
    let session = SwiftyURLSessionMock()
    let dependenciesContainer = SimpleContainerMock()
    
    fileprivate var sceneDelegate: CustomSceneDelegate { Self.suiteSceneDelegate }
    var windowScene: UIWindowScene? { Self.suiteWindowScene }
    var analyticsManager: ReferralAppTrackable!
    
    init() {
        dependenciesContainer.session = session
        dependenciesContainer.bundle = BundleMock.create()
        
        // Set up database cleanup (equivalent to beforeSuite)
        let databaseURL: URL! = FileManager.default.databaseFileURL(databaseName: Self.databaseName, databaseParentDirectory: Self.databaseParentDirectory)
        try? FileManager.default.removeItem(at: databaseURL)
    }
    
    @MainActor
    mutating func setUp() {
        Self.ensureSuiteUIKitInitialized()
        
        databaseConnection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: Self.databaseName, databaseParentDirectory: Self.databaseParentDirectory)
        database = RAnalyticsDatabase.database(connection: databaseConnection)
        dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database, tableName: Self.databaseTableName)
        dependenciesContainer.session = session

        let bundle = BundleMock.create()
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: Reachability(),
            userStorageHandler: dependenciesContainer.userStorageHandler)

        analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

        let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
        ratTracker.set(batchingDelay: 0)
        (analyticsManager as? AnalyticsManager)?.add(ratTracker)

        // This setter updates a static holder used by the swizzled delegate implementations.
        windowScene?.analyticsManager = analyticsManager
    }
    
    @MainActor
    mutating func tearDown() {
        // Do NOT reset the scene delegate here; toggling delegate assignment can toggle swizzling.
        // Just restore the analytics manager to its default.
        windowScene?.analyticsManager = AnalyticsManager.shared()
        DatabaseTestUtils.deleteTableIfExists(dependenciesContainer.databaseConfiguration!.tableName, connection: databaseConnection)
        database.closeConnection()
        databaseConnection = nil
    }
    
    @Suite("When the delegate is set to a non-nil value")
    struct WhenDelegateIsSetToNonNilValueTests {
        @Suite("When scene(_:openURLContexts:) is called")
        struct WhenSceneOpenURLContextsIsCalledTests {
            @Test("should process the referral app tracking")
            @MainActor
            mutating func testShouldProcessReferralAppTracking() async throws {
                var spec = ReferralAppTrackingSceneDelegateTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                var payloads = [[String: Any]]()
                spec.session.completion = {
                    let result = DatabaseTestUtils.fetchTableContents(ReferralAppTrackingSceneDelegateTests.databaseTableName, connection: spec.databaseConnection)
                    payloads = result.deserialize()
                }

                // Note: the sourceApplication is nil when scene(openURLContexts:) is called from an iOS app's SceneDelegate
                // Therefore ref must be passed in the URL
                let previousURL = UIOpenURLContext.DefaultValues.url
                let previousSourceApplication = UIOpenURLContext.DefaultValues.sourceApplication
                defer {
                    UIOpenURLContext.DefaultValues.url = previousURL
                    UIOpenURLContext.DefaultValues.sourceApplication = previousSourceApplication
                }
                UIOpenURLContext.DefaultValues.url = Payloads.urlScheme
                UIOpenURLContext.DefaultValues.sourceApplication = Payloads.appBundleIdentifier

                let scene = try #require(spec.windowScene)
                
                // Fail fast if swizzling isn't active (otherwise this test will just time out).
                #expect((spec.sceneDelegate as NSObject).responds(to: #selector(UIWindowScene.rAutotrackScene(_:openURLContexts:))))
                scene.delegate?.scene?(scene, openURLContexts: [])

                try await TestingHelpers.eventuallyOnMain(timeout: 5.0) {
                    let result = DatabaseTestUtils.fetchTableContents(ReferralAppTrackingSceneDelegateTests.databaseTableName, connection: spec.databaseConnection)
                    payloads = result.deserialize()
                    return payloads.count == 2
                }
                // Use `#require`-style early exit semantics to avoid index-out-of-range crashes in downstream
                // payload verification when the DB is still being written.
                if payloads.count != 2 {
                    Issue.record("Expected 2 payloads, got \(payloads.count)")
                    return
                }
                #expect(spec.sceneDelegate.sceneopenURLContextsIsCalled == true)

                Payloads.verifyPayloads(payloads)
            }
        }
        
        @Suite("When scene(_:continue:) is called")
        struct WhenSceneContinueIsCalledTests {
            @Test("should process the referral app tracking")
            @MainActor
            mutating func testShouldProcessReferralAppTracking() async throws {
                var spec = ReferralAppTrackingSceneDelegateTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                var payloads = [[String: Any]]()
                spec.session.completion = {
                    let result = DatabaseTestUtils.fetchTableContents(ReferralAppTrackingSceneDelegateTests.databaseTableName, connection: spec.databaseConnection)
                    payloads = result.deserialize()
                }

                let userActivity = NSUserActivity(activityType: "jp.co.rakuten.Host")
                userActivity.webpageURL = Payloads.universalLink

                let scene = try #require(spec.windowScene)
                
                // Fail fast if swizzling isn't active (otherwise this test will just time out).
                #expect((spec.sceneDelegate as NSObject).responds(to: #selector(UIWindowScene.rAutotrackScene(_:continue:))))
                scene.delegate?.scene?(scene, continue: userActivity)

                try await TestingHelpers.eventuallyOnMain(timeout: 5.0) {
                    let result = DatabaseTestUtils.fetchTableContents(ReferralAppTrackingSceneDelegateTests.databaseTableName, connection: spec.databaseConnection)
                    payloads = result.deserialize()
                    return payloads.count == 2
                }
                if payloads.count != 2 {
                    Issue.record("Expected 2 payloads, got \(payloads.count)")
                    return
                }
                #expect(spec.sceneDelegate.sceneContinueIsCalled == true)

                Payloads.verifyPayloads(payloads)
            }
        }
    }
}
#endif

// swiftlint:enable line_length

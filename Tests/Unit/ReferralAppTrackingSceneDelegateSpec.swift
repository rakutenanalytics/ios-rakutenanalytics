import Quick
import Nimble
import Foundation
@testable import RAnalytics
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
@available(iOS 13.0, *)
private final class CustomSceneDelegate: NSObject, UISceneDelegate {
    var sceneopenURLContextsIsCalled = false
    var sceneContinueIsCalled = false

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        sceneopenURLContextsIsCalled = true
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        sceneContinueIsCalled = true
    }
}

@available(iOS 13.0, *)
final class ReferralAppTrackingSceneDelegateSpec: QuickSpec {
    override func spec() {
        describe("ReferralAppTrackingSceneDelegateSpec") {
            let databaseDirectory = FileManager.SearchPathDirectory.documentDirectory
            let databaseTableName = "testTableName_ReferralAppTrackingSceneDelegateSpec"
            var databaseConnection: SQlite3Pointer!
            var database: RAnalyticsDatabase!
            let session = SwityURLSessionMock()
            let dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.session = session
            dependenciesContainer.bundle = BundleMock.create()
            let sceneDelegate = CustomSceneDelegate()
            let window = UIWindow()
            let windowScene: UIWindowScene! = window.windowScene
            windowScene?.delegate = sceneDelegate
            var analyticsManager: ReferralAppTrackable!

            context("When the delegate is set to a non-nil value") {
                beforeEach {
                    databaseConnection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: databaseTableName,
                                                                                    databaseParentDirectory: databaseDirectory)!
                    database = RAnalyticsDatabase.database(connection: databaseConnection)
                    dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database,
                                                                                        tableName: databaseTableName)
                    dependenciesContainer.session = session

                    analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    ratTracker.set(batchingDelay: 0)
                    (analyticsManager as? AnalyticsManager)?.add(ratTracker)

                    windowScene.analyticsManager = analyticsManager
                }

                afterEach {
                    DatabaseTestUtils.deleteTableIfExists(dependenciesContainer.databaseConfiguration!.tableName,
                                                          connection: databaseConnection)
                    database.closeConnection()
                    databaseConnection = nil
                }

                context("When scene(_:openURLContexts:) is called") {
                    it("should process the referral app tracking") {
                        var payloads = [[String: Any]]()
                        session.completion = {
                            let result = DatabaseTestUtils.fetchTableContents(databaseTableName,
                                                                              connection: databaseConnection)
                            payloads = result.deserialize()
                        }

                        // Note: the sourceApplication is nil when scene(openURLContexts:) is called from an iOS app's SceneDelegate
                        // Therefore ref must be passed in the URL
                        UIOpenURLContext.DefaultValues.url = Payloads.urlScheme
                        UIOpenURLContext.DefaultValues.sourceApplication = Payloads.appBundleIdentifier

                        windowScene?.delegate?.scene?(windowScene, openURLContexts: [])

                        expect(payloads.isEmpty).toAfterTimeout(beFalse(), timeout: 1.0)
                        expect(payloads.count).to(equal(2))
                        expect(sceneDelegate.sceneopenURLContextsIsCalled).to(beTrue())

                        Payloads.verifyPayloads(payloads)
                    }
                }

                context("When scene(_:continue:) is called") {
                    it("should process the referral app tracking") {
                        var payloads = [[String: Any]]()
                        session.completion = {
                            let result = DatabaseTestUtils.fetchTableContents(databaseTableName,
                                                                              connection: databaseConnection)
                            payloads = result.deserialize()
                        }

                        let userActivity = NSUserActivity(activityType: "jp.co.rakuten.Host")
                        userActivity.webpageURL = Payloads.universalLink

                        windowScene?.delegate?.scene?(windowScene, continue: userActivity)

                        expect(payloads.isEmpty).toAfterTimeout(beFalse(), timeout: 1.0)
                        expect(payloads.count).to(equal(2))
                        expect(sceneDelegate.sceneContinueIsCalled).to(beTrue())

                        Payloads.verifyPayloads(payloads)
                    }
                }
            }
        }
    }
}
#endif

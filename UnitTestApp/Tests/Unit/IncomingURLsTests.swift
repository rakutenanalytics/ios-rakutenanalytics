import Testing
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("IncomingURLs")
struct IncomingURLsTests {
    let dependenciesContainer = SimpleContainerMock()

    private mutating func makeAnalyticsManager() -> AnalyticsManager {
        dependenciesContainer.bundle = BundleMock.create()
        return AnalyticsManager(dependenciesContainer: dependenciesContainer)
    }

    @Test("tracks injected URL context values when the context set is empty")
    mutating func testTracksInjectedURLContextValues() {
        let analyticsManager = makeAnalyticsManager()
        let url = URL(string: "app://?ref=jp.co.rakuten.app-name&ref_acc=1&ref_aid=2")!
        let previousURL = UIOpenURLContext.DefaultValues.url
        let previousSourceApplication = UIOpenURLContext.DefaultValues.sourceApplication
        defer {
            UIOpenURLContext.DefaultValues.url = previousURL
            UIOpenURLContext.DefaultValues.sourceApplication = previousSourceApplication
        }

        UIOpenURLContext.DefaultValues.url = url
        UIOpenURLContext.DefaultValues.sourceApplication = "jp.co.rakuten.app-name"

        analyticsManager.handleIncomingURLContexts([])

        #expect(analyticsManager.launchCollector.origin == .external)
    }

    @Test("tracks injected universal link values during cold launch handling")
    mutating func testTracksInjectedUniversalLinkValues() {
        let analyticsManager = makeAnalyticsManager()
        let url = URL(string: "https://www.rakuten.co.jp?ref=jp.co.rakuten.app-name&ref_acc=1&ref_aid=2")!
        let previousWebpageURL = UIScene.ConnectionOptions.DefaultValues.webpageURL
        defer {
            UIScene.ConnectionOptions.DefaultValues.webpageURL = previousWebpageURL
        }

        UIScene.ConnectionOptions.DefaultValues.webpageURL = url
        analyticsManager.handleIncomingColdLaunchFromInjectedValues()

        #expect(analyticsManager.launchCollector.origin == .external)
    }

    @Test("uses sourceApplication when ref query parameter is missing")
    mutating func testUsesSourceApplicationFallback() {
        let analyticsManager = makeAnalyticsManager()
        let url = URL(string: "app://?ref_acc=1&ref_aid=2")!
        let sourceApplication = "jp.co.rakuten.app-name"

        let didTrack = analyticsManager.trackReferralApp(url: url, sourceApplication: sourceApplication)

        #expect(didTrack == true)
    }

    @Test("fails referral parsing when ref and sourceApplication are missing")
    mutating func testFailsWhenRefAndSourceApplicationAreMissing() {
        let analyticsManager = makeAnalyticsManager()
        let url = URL(string: "app://?ref_acc=1&ref_aid=2")!

        let didTrack = analyticsManager.trackReferralApp(url: url, sourceApplication: nil)

        #expect(didTrack == false)
    }

    @Test("tracks external referrer when referral parsing fails")
    mutating func testTracksExternalReferrerWhenReferralParsingFails() async throws {
        var analyticsManager = makeAnalyticsManager()
        let databaseConnection = RAnalyticsDatabase.mkAnalyticsDBConnection(
            databaseName: "IncomingURLsTests.db",
            databaseParentDirectory: .documentDirectory
        )!
        let database = RAnalyticsDatabase.database(connection: databaseConnection)
        dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database, tableName: "incoming_urls")
        let session = SwiftyURLSessionMock()
        dependenciesContainer.session = session
        analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

        let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
        ratTracker.set(batchingDelay: 0)
        analyticsManager.add(ratTracker)

        var payloads = [[String: Any]]()
        session.completion = {
            payloads = DatabaseTestUtils.fetchTableContents("incoming_urls", connection: databaseConnection).deserialize()
        }

        let url = URL(string: "https://www.example.com/page")!
        analyticsManager.trackReferrals(url: url)

        try await TestingHelpers.eventually {
            !payloads.isEmpty
        }

        let hasExternalReferralPayload = payloads.contains { payload in
            guard payload[PayloadParameterKeys.etype] as? String == RAnalyticsEvent.Name.pageVisitForRAT,
                  payload[PayloadParameterKeys.ref] as? String == url.absoluteString,
                  let cpPayload = payload[PayloadParameterKeys.cp] as? [String: Any] else {
                return false
            }
            return cpPayload[CpParameterKeys.Ref.type] as? String == RAnalyticsOrigin.external.toString
        }
        #expect(hasExternalReferralPayload)
        database.closeConnection()
    }
}

// swiftlint:disable line_length

import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

enum Payloads {
    static let appBundleIdentifier = "jp.co.rakuten.app-name"
    static let encodedAppBundleIdentifier = Payloads.appBundleIdentifier.addEncodingForRFC3986UnreservedCharacters()!
    static let refAccountIdentifier = 1
    static let refApplicationIdentifier = 2
    static let link = "campaignCode\(CharacterSet.rfc3986ReservedCharacters)"
    static let component = "news\(CharacterSet.rfc3986ReservedCharacters)"
    static let encodedLink = Payloads.link.addEncodingForRFC3986UnreservedCharacters()!
    static let encodedComponent = Payloads.component.addEncodingForRFC3986UnreservedCharacters()!
    static let parameters = "\(DeepLinkParameterKeys.accountIdentifier)=\(Payloads.refAccountIdentifier)&\(DeepLinkParameterKeys.applicationIdentifier)=\(Payloads.refApplicationIdentifier)&\(PayloadParameterKeys.Cp.refLink)=\(encodedLink)&\(PayloadParameterKeys.Cp.refComp)=\(encodedComponent)"
    static let urlScheme: URL! = URL(string: "app://?\(Payloads.parameters)")
    static let universalLink: URL! = URL(string: "https://www.rakuten.co.jp?\(PayloadParameterKeys.ref)=\(encodedAppBundleIdentifier)&\(Payloads.parameters)")

    static func verifyPayloads(_ payloads: [[String: Any]]) {
        guard payloads.count >= 2 else {
            Issue.record("Expected at least 2 payloads, got \(payloads.count)")
            return
        }

        let payload1 = payloads[0]
        let cpPayload1 = payload1[PayloadParameterKeys.Cp.cp] as? [String: Any]

        let payload2 = payloads[1]
        let cpPayload2 = payload2[PayloadParameterKeys.Cp.cp] as? [String: Any]

        #expect(payload1[PayloadParameterKeys.etype] as? String == RAnalyticsEvent.Name.pageVisitForRAT)
        #expect(payload1[PayloadParameterKeys.acc] as? Int == 477)
        #expect(payload1[PayloadParameterKeys.aid] as? Int == 1)
        #expect(payload1[PayloadParameterKeys.ref] as? String == appBundleIdentifier)
        #expect(cpPayload1 != nil)
        #expect(cpPayload1?[PayloadParameterKeys.Cp.refType
        ] as? String == RAnalyticsOrigin.external.toString)
        #expect(cpPayload1?[PayloadParameterKeys.Cp.refLink] as? String == link)
        #expect(cpPayload1?[PayloadParameterKeys.Cp.refComp] as? String == component)

        #expect(payload2[PayloadParameterKeys.etype] as? String == RAnalyticsEvent.Name.deeplink)
        #expect(payload2[PayloadParameterKeys.acc] as? Int == 1)
        #expect(payload2[PayloadParameterKeys.aid] as? Int == 2)
        #expect(payload2[PayloadParameterKeys.ref] as? String == appBundleIdentifier)
        #expect(cpPayload2 != nil)
        #expect(cpPayload2?[PayloadParameterKeys.Cp.refType] as? String == RAnalyticsOrigin.external.toString)
        #expect(cpPayload2?[PayloadParameterKeys.Cp.refLink] as? String == link)
        #expect(cpPayload2?[PayloadParameterKeys.Cp.refComp] as? String == component)
    }
}

// MARK: - ReferralAppTrackingIntegrationTests

@Suite("ReferralAppTrackingIntegrationTests")
struct ReferralAppTrackingIntegrationTests {
    let databaseDirectory = FileManager.SearchPathDirectory.documentDirectory
    let databaseTableName = "testTableName_ReferralAppTrackingIntegrationTests"
    var databaseConnection: SQlite3Pointer!
    var database: RAnalyticsDatabase!
    let session = SwiftyURLSessionMock()
    let dependenciesContainer = SimpleContainerMock()

    mutating func setUp() {
        databaseConnection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: databaseTableName, databaseParentDirectory: databaseDirectory)!
        database = RAnalyticsDatabase.database(connection: databaseConnection)
        dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database, tableName: databaseTableName)
        dependenciesContainer.session = session
        let bundle = BundleMock.create()
        dependenciesContainer.bundle = bundle
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: Reachability(),
            userStorageHandler: dependenciesContainer.userStorageHandler,
            consentStore: dependenciesContainer.dataCollectionConsent)

        // Prevent RATTracker init Rp cookie fetch from hitting the real network and writing to shared storage.
        URLSessionMock.startMockingURLSession()
        let sessionMock = URLSessionMock.mock(originalInstance: .shared)
        sessionMock.stubResponse(url: bundle.endpointAddress, statusCode: 200, headerFields: [:])
    }

    mutating func tearDown() {
        URLSessionMock.stopMockingURLSession()
        DatabaseTestUtils.deleteTableIfExists(dependenciesContainer.databaseConfiguration!.tableName, connection: databaseConnection)
        database.closeConnection()
        databaseConnection = nil
    }

    @Test("should track the referral app with a URL Scheme")
    mutating func testShouldTrackReferralAppWithURLScheme() async throws {
        setUp()
        defer { tearDown() }
        try await verify(url: Payloads.urlScheme, bundleIdentifier: Payloads.appBundleIdentifier)
    }

    @Test("should track the referral app with a Universal Link")
    mutating func testShouldTrackReferralAppWithUniversalLink() async throws {
        setUp()
        defer { tearDown() }
        try await verify(url: Payloads.universalLink, bundleIdentifier: nil)
    }

    mutating func verify(url: URL, bundleIdentifier: String?) async throws {
        let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
        let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)

        var payloads = [[String: Any]]()
        let tableName = databaseTableName
        let connection = databaseConnection!
        session.completion = {
            let result = DatabaseTestUtils.fetchTableContents(tableName, connection: connection)
            payloads = result.deserialize()
        }

        ratTracker.set(batchingDelay: 0)
        analyticsManager.remove(RAnalyticsRATTracker.shared())
        analyticsManager.add(ratTracker)
        let didTrackReferral = analyticsManager.trackReferralApp(url: url, sourceApplication: bundleIdentifier)

        try await TestingHelpers.eventually(timeout: 5.0) {
            let result = DatabaseTestUtils.fetchTableContents(tableName, connection: connection)
            payloads = result.deserialize()
            return payloads.count == 2
        }
        #expect(didTrackReferral)
        Payloads.verifyPayloads(payloads)
    }
}
// swiftlint:enable line_length

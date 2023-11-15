// swiftlint:disable line_length

import Quick
import Nimble
import Foundation
@testable import RAnalytics
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
    static let parameters = "\(CpParameterKeys.Ref.accountIdentifier)=\(Payloads.refAccountIdentifier)&\(CpParameterKeys.Ref.applicationIdentifier)=\(Payloads.refApplicationIdentifier)&\(CpParameterKeys.Ref.link)=\(encodedLink)&\(CpParameterKeys.Ref.component)=\(encodedComponent)"
    static let urlScheme: URL! = URL(string: "app://?\(Payloads.parameters)")
    static let universalLink: URL! = URL(string: "https://www.rakuten.co.jp?\(PayloadParameterKeys.ref)=\(encodedAppBundleIdentifier)&\(Payloads.parameters)")

    static func verifyPayloads(_ payloads: [[String: Any]]) {
        let payload1 = payloads[0]
        let cpPayload1 = payload1[PayloadParameterKeys.cp] as? [String: Any]

        let payload2 = payloads[1]
        let cpPayload2 = payload2[PayloadParameterKeys.cp] as? [String: Any]

        expect(payload1[PayloadParameterKeys.etype] as? String).to(equal(RAnalyticsEvent.Name.pageVisitForRAT))
        expect(payload1[PayloadParameterKeys.acc] as? Int).to(equal(477))
        expect(payload1[PayloadParameterKeys.aid] as? Int).to(equal(1))
        expect(payload1[PayloadParameterKeys.ref] as? String).to(equal(appBundleIdentifier))
        expect(cpPayload1).toNot(beNil())
        expect(cpPayload1?[CpParameterKeys.Ref.type] as? String).to(equal(RAnalyticsOrigin.external.toString))
        expect(cpPayload1?[CpParameterKeys.Ref.link] as? String).to(equal(link))
        expect(cpPayload1?[CpParameterKeys.Ref.component] as? String).to(equal(component))

        expect(payload2).toNot(beNil())
        // expect(payload2[PayloadParameterKeys.etype] as? String).to(equal(RAnalyticsEvent.Name.deeplink))
        // expect(payload2[PayloadParameterKeys.acc] as? Int).to(equal(1))
        // expect(payload2[PayloadParameterKeys.aid] as? Int).to(equal(2))
        expect(payload2[PayloadParameterKeys.ref] as? String).to(equal(appBundleIdentifier))
        expect(cpPayload2).toNot(beNil())
        expect(cpPayload2?[CpParameterKeys.Ref.type] as? String).to(equal(RAnalyticsOrigin.external.toString))
        expect(cpPayload2?[CpParameterKeys.Ref.link] as? String).to(equal(link))
        expect(cpPayload2?[CpParameterKeys.Ref.component] as? String).to(equal(component))
    }
}

// MARK: - ReferralAppTrackingIntegrationSpec

final class ReferralAppTrackingIntegrationSpec: QuickSpec {
    override func spec() {
        describe("AnalyticsManager") {
            let databaseDirectory = FileManager.SearchPathDirectory.documentDirectory
            let databaseTableName = "testTableName_ReferralAppTrackingIntegrationSpec"
            var databaseConnection: SQlite3Pointer!
            var database: RAnalyticsDatabase!
            let session = SwityURLSessionMock()
            let dependenciesContainer = SimpleContainerMock()

            beforeEach {
                databaseConnection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: databaseTableName,
                                                                                databaseParentDirectory: databaseDirectory)!
                database = RAnalyticsDatabase.database(connection: databaseConnection)
                dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database, tableName: databaseTableName)
                dependenciesContainer.session = session
                let bundle = BundleMock.create()
                dependenciesContainer.bundle = bundle
                dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(bundle: bundle,
                                                                                      deviceCapability: dependenciesContainer.deviceCapability,
                                                                                      screenHandler: dependenciesContainer.screenHandler,
                                                                                      telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
                                                                                      notificationHandler: dependenciesContainer.notificationHandler,
                                                                                      analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
                                                                                      reachability: Reachability(hostname: ReachabilityConstants.host))
            }

            afterEach {
                DatabaseTestUtils.deleteTableIfExists(dependenciesContainer.databaseConfiguration!.tableName, connection: databaseConnection)
                database.closeConnection()
                databaseConnection = nil
            }

            it("should track the referral app with a URL Scheme") {
                verify(url: Payloads.urlScheme, bundleIdentifier: Payloads.appBundleIdentifier)
            }

            it("should track the referral app with a Universal Link") {
                verify(url: Payloads.universalLink, bundleIdentifier: nil)
            }

            func verify(url: URL, bundleIdentifier: String?) {
                let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)

                var payloads = [[String: Any]]()
                session.completion = {
                    let result = DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection)
                    payloads = result.deserialize()
                }

                ratTracker.set(batchingDelay: 0)
                analyticsManager.remove(RAnalyticsRATTracker.shared())
                analyticsManager.add(ratTracker)
                analyticsManager.trackReferralApp(url: url, sourceApplication: bundleIdentifier)

                expect(payloads.isEmpty).toEventually(beFalse())
                // expect(payloads.count).to(equal(2))

                DatabaseTestUtils.deleteTableIfExists(dependenciesContainer.databaseConfiguration!.tableName, connection: databaseConnection)

                Payloads.verifyPayloads(payloads)
            }
        }
    }
}
// swiftlint:enable line_length

// swiftlint:disable line_length

import Quick
import Nimble
@testable import RAnalytics

// MARK: - ReferralAppTrackingIntegrationSpec

final class ReferralAppTrackingIntegrationSpec: QuickSpec {
    override func spec() {
        describe("AnalyticsManager") {
            let appBundleIdentifier = "jp.co.rakuten.app-name"
            let encodedAppBundleIdentifier = appBundleIdentifier.addEncodingForRFC3986UnreservedCharacters()!
            let databaseTableName = "testTableName_ReferralAppTrackingIntegrationSpec"
            var databaseConnection: SQlite3Pointer!
            var database: RAnalyticsDatabase!
            let session = SwityURLSessionMock()
            let dependenciesContainer = SimpleContainerMock()
            let refAccountIdentifier = 1
            let refApplicationIdentifier = 2
            let link = "campaignCode\(CharacterSet.RFC3986ReservedCharacters)"
            let encodedLink = link.addEncodingForRFC3986UnreservedCharacters()!
            let component = "news\(CharacterSet.RFC3986ReservedCharacters)"
            let encodedComponent = component.addEncodingForRFC3986UnreservedCharacters()!
            let parameters = "\(PayloadParameterKeys.refAccountIdentifier)=\(refAccountIdentifier)&\(PayloadParameterKeys.refApplicationIdentifier)=\(refApplicationIdentifier)&\(PayloadParameterKeys.refLink)=\(encodedLink)&\(PayloadParameterKeys.refComponent)=\(encodedComponent)"

            beforeEach {
                databaseConnection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: databaseTableName)!
                database = RAnalyticsDatabase.database(connection: databaseConnection)
                dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database, tableName: databaseTableName)
                dependenciesContainer.session = session
            }

            afterEach {
                DatabaseTestUtils.deleteTableIfExists(dependenciesContainer.databaseConfiguration!.tableName, connection: databaseConnection)
                database.closeConnection()
                databaseConnection = nil
            }

            it("should track the referral app with a URL Scheme") {
                verify(url: URL(string: "app://?\(parameters)")!, bundleIdentifier: appBundleIdentifier)
            }

            it("should track the referral app with a Universal Link") {
                verify(url: URL(string: "https://www.rakuten.co.jp?\(PayloadParameterKeys.ref)=\(encodedAppBundleIdentifier)&\(parameters)")!, bundleIdentifier: nil)
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
                analyticsManager.add(ratTracker)
                analyticsManager.trackReferralApp(url: url, sourceApplication: bundleIdentifier)

                expect(payloads.isEmpty).toEventually(beFalse())
                expect(payloads.count).to(equal(2))

                DatabaseTestUtils.deleteTableIfExists(dependenciesContainer.databaseConfiguration!.tableName, connection: databaseConnection)

                let payload1 = payloads[0]
                let cpPayload1 = payload1[PayloadParameterKeys.cp] as? [String: Any]

                let payload2 = payloads[1]
                let cpPayload2 = payload2[PayloadParameterKeys.cp] as? [String: Any]

                expect(payload1[PayloadParameterKeys.etype] as? String).to(equal(EventsName.pageVisit))
                expect(payload1[PayloadParameterKeys.acc] as? Int).to(equal(477))
                expect(payload1[PayloadParameterKeys.aid] as? Int).to(equal(1))
                expect(payload1[PayloadParameterKeys.ref] as? String).to(equal(appBundleIdentifier))
                expect(cpPayload1).toNot(beNil())
                expect(cpPayload1?[PayloadParameterKeys.refType] as? String).to(equal(RAnalyticsOrigin.external.toString))
                expect(cpPayload1?[PayloadParameterKeys.refLink] as? String).to(equal(link))
                expect(cpPayload1?[PayloadParameterKeys.refComponent] as? String).to(equal(component))

                expect(payload2).toNot(beNil())
                expect(payload2[PayloadParameterKeys.etype] as? String).to(equal(EventsName.deeplink))
                expect(payload2[PayloadParameterKeys.acc] as? Int).to(equal(1))
                expect(payload2[PayloadParameterKeys.aid] as? Int).to(equal(2))
                expect(payload2[PayloadParameterKeys.ref] as? String).to(equal(appBundleIdentifier))
                expect(cpPayload2).toNot(beNil())
                expect(cpPayload2?[PayloadParameterKeys.refType] as? String).to(equal(RAnalyticsOrigin.external.toString))
                expect(cpPayload2?[PayloadParameterKeys.refLink] as? String).to(equal(link))
                expect(cpPayload2?[PayloadParameterKeys.refComponent] as? String).to(equal(component))
            }
        }
    }
}

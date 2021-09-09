// swiftlint:disable line_length

import Quick
import Nimble
@testable import RAnalytics

// MARK: - ReferralAppTrackingIntegrationSpec

final class ReferralAppTrackingIntegrationSpec: QuickSpec {
    override func spec() {
        describe("AnalyticsManager") {
            it("should track the referral app") {
                let databaseTableName = "testTableName_ReferralAppTrackingIntegrationSpec"
                let databaseConnection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: databaseTableName)!
                let database = RAnalyticsDatabase.database(connection: databaseConnection)
                let session = SwityURLSessionMock()
                let dependenciesContainer: SimpleContainerMock = {
                    let dependenciesContainer = SimpleContainerMock()
                    dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database, tableName: databaseTableName)
                    dependenciesContainer.session = session
                    return dependenciesContainer
                }()
                let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                let refAccountIdentifier = 1
                let refApplicationIdentifier = 2
                let link = "campaignCode"
                let component = "news"
                let parameters = "\(PayloadParameterKeys.refAccountIdentifier)=\(refAccountIdentifier)&\(PayloadParameterKeys.refApplicationIdentifier)=\(refApplicationIdentifier)&\(PayloadParameterKeys.refLink)=\(link)&\(PayloadParameterKeys.refComponent)=\(component)"
                let appURL = URL(string: "app://?\(parameters)")!
                var payloads = [[String: Any]]()

                session.completion = {
                    let result = DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection)
                    payloads = result.deserialize()
                }

                ratTracker.set(batchingDelay: 0)
                analyticsManager.add(ratTracker)
                analyticsManager.trackReferralApp(url: appURL, sourceApplication: "jp.co.rakuten.app")

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
                expect(payload1[PayloadParameterKeys.ref] as? String).to(equal("jp.co.rakuten.app"))
                expect(cpPayload1).toNot(beNil())
                expect(cpPayload1?[PayloadParameterKeys.refType] as? String).to(equal(RAnalyticsOrigin.external.toString))
                expect(cpPayload1?[PayloadParameterKeys.refLink] as? String).to(equal("campaignCode"))
                expect(cpPayload1?[PayloadParameterKeys.refComponent] as? String).to(equal("news"))

                expect(payload2).toNot(beNil())
                expect(payload2[PayloadParameterKeys.etype] as? String).to(equal(EventsName.deeplink))
                expect(payload2[PayloadParameterKeys.acc] as? Int).to(equal(1))
                expect(payload2[PayloadParameterKeys.aid] as? Int).to(equal(2))
                expect(payload2[PayloadParameterKeys.ref] as? String).to(equal("jp.co.rakuten.app"))
                expect(cpPayload2).toNot(beNil())
                expect(cpPayload2?[PayloadParameterKeys.refType] as? String).to(equal(RAnalyticsOrigin.external.toString))
                expect(cpPayload2?[PayloadParameterKeys.refLink] as? String).to(equal("campaignCode"))
                expect(cpPayload2?[PayloadParameterKeys.refComponent] as? String).to(equal("news"))
            }
        }
    }
}

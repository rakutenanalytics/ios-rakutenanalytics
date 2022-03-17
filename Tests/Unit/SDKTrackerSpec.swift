import Quick
import Nimble
import SQLite3
import Foundation
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - SDKTrackerSpec

final class SDKTrackerSpec: QuickSpec {
    override func spec() {
        describe("SDKTracker") {
            let databaseDirectory = FileManager.SearchPathDirectory.documentDirectory
            let databaseName = "test_RAnalyticsSDKTracker.db"
            let databaseTableName = "testTableName_SDKTrackerSpec"
            let urlSession = SwityURLSessionMock()
            let bundle = BundleMock()
            var databaseConnection: SQlite3Pointer!
            var database: RAnalyticsDatabase!
            var databaseConfiguration: DatabaseConfiguration!

            beforeEach {
                urlSession.urlRequest = nil

                databaseConnection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: databaseName,
                                                                                databaseParentDirectory: databaseDirectory)
                database = RAnalyticsDatabase.database(connection: databaseConnection)
                databaseConfiguration = DatabaseConfiguration(database: database, tableName: databaseTableName)
            }

            afterEach {
                DatabaseTestUtils.deleteTableIfExists(databaseConfiguration!.tableName, connection: databaseConnection)
                database.closeConnection()
                databaseConnection = nil
            }

            describe("init") {
                it("should return nil when the bundle does not define the endpoint URL") {
                    bundle.mutableEndpointAddress = nil

                    let sdkTracker = SDKTracker(bundle: bundle,
                                                session: urlSession,
                                                databaseConfiguration: databaseConfiguration)
                    expect(sdkTracker).to(beNil())
                }

                it("should return a new instance of SDKTracker when the bundle define the endpoint URL") {
                    bundle.mutableEndpointAddress = URL(string: "https://endpoint.co.jp")!

                    let sdkTracker = SDKTracker(bundle: bundle,
                                                session: urlSession,
                                                databaseConfiguration: databaseConfiguration)
                    expect(sdkTracker).toNot(beNil())
                    expect(sdkTracker?.endpointURL).toNot(beNil())
                    expect(sdkTracker?.endpointURL?.absoluteString).to(equal("https://endpoint.co.jp"))
                }
            }

            describe("process") {
                let installEvent = RAnalyticsEvent(name: RAnalyticsEvent.Name.install, parameters: nil)
                let pageVisitEvent = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                let state = RAnalyticsState(sessionIdentifier: "CA7A88AB-82FE-40C9-A836-B1B3455DECAB", deviceIdentifier: "deviceId")

                it("should not process the event when the event is not _rem_install") {
                    bundle.mutableEndpointAddress = URL(string: "https://endpoint.co.jp")!
                    let sdkTracker = SDKTracker(bundle: bundle,
                                                session: urlSession,
                                                batchingDelay: 1,
                                                databaseConfiguration: databaseConfiguration)
                    expect(sdkTracker?.process(event: pageVisitEvent, state: state)).to(beFalse())
                    expect(urlSession.urlRequest?.httpBody).to(beNil())
                }

                it("should process the event when the event is _rem_install") {
                    bundle.mutableEndpointAddress = URL(string: "https://endpoint.co.jp")!
                    let sdkTracker = SDKTracker(bundle: bundle,
                                                session: urlSession,
                                                batchingDelay: 1,
                                                databaseConfiguration: databaseConfiguration)

                    expect(sdkTracker?.process(event: installEvent, state: state)).to(beTrue())

                    expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))
                    expect(urlSession.urlRequest?.httpBody).toNot(beNil())

                    let jsonArray = urlSession.urlRequest?.httpBody?.ratPayload

                    expect(jsonArray).toNot(beNil())
                    expect(jsonArray?.count).to(equal(1))
                    expect(jsonArray?[0][PayloadParameterKeys.acc] as? Int).to(equal(477))
                    expect(jsonArray?[0][PayloadParameterKeys.aid] as? Int).to(equal(1))

                    let cpDictionary = jsonArray?[0][PayloadParameterKeys.cp] as? [String: Any]
                    expect(cpDictionary).toNot(beNil())

                    let appInfo = cpDictionary?[RAnalyticsConstants.appInfoKey] as? String
                    expect(appInfo?.contains("xcode")).to(beTrue())
                    expect(appInfo?.contains("iphonesimulator")).to(beTrue())

                    let sdkInfo = jsonArray?[0][RAnalyticsConstants.sdkDependenciesKey] as? [String: Any]
                    expect(sdkInfo).toNot(beNil())
                    expect(sdkInfo?["analytics"] as? String).toNot(beNil())
                }
            }
        }
    }
}

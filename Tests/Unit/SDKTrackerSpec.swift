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
            let appInfoMock = "{\"xcode\":\"1410.14B47b\",\"sdk\":\"iphonesimulator14.0.internal\",\"deployment_target\":\"14.0\"}"
            let sdkDependenciesMock = ["rsdks_inappmessaging": "6.0.0",
                                       "rsdks_pushpnp": "8.0.0",
                                       "rsdks_geo": "1.1.0",
                                       "rsdks_pitari": "1.0.0"]
            let coreInfosCollectorMock = CoreInfosCollectorMock(appInfo: appInfoMock, sdkDependencies: sdkDependenciesMock)

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
                    bundle.endpointAddress = nil

                    let sdkTracker = SDKTracker(bundle: bundle,
                                                session: urlSession,
                                                databaseConfiguration: databaseConfiguration)
                    expect(sdkTracker).to(beNil())
                }

                it("should return a new instance of SDKTracker when the bundle define the endpoint URL") {
                    bundle.endpointAddress = URL(string: "https://endpoint.co.jp")!

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

                it("should not track _rem_internal_install when the processed event is not _rem_install") {
                    bundle.endpointAddress = URL(string: "https://endpoint.co.jp")!
                    let sdkTracker = SDKTracker(bundle: bundle,
                                                session: urlSession,
                                                batchingDelay: 1,
                                                databaseConfiguration: databaseConfiguration)
                    expect(sdkTracker?.process(event: pageVisitEvent, state: state)).to(beFalse())
                    expect(urlSession.urlRequest?.httpBody).to(beNil())
                }

                it("should track _rem_internal_install when the processed event is _rem_install") {
                    bundle.endpointAddress = URL(string: "https://endpoint.co.jp")!
                    let sdkTracker = SDKTracker(bundle: bundle,
                                                session: urlSession,
                                                batchingDelay: 1,
                                                databaseConfiguration: databaseConfiguration,
                                                coreInfosCollector: coreInfosCollectorMock)

                    expect(sdkTracker?.process(event: installEvent, state: state)).to(beTrue())

                    expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))
                    expect(urlSession.urlRequest?.httpBody).toNot(beNil())

                    let jsonArray = urlSession.urlRequest?.httpBody?.ratPayload

                    expect(jsonArray).toNot(beNil())
                    expect(jsonArray?.count).to(equal(1))
                    expect(jsonArray?[0][PayloadParameterKeys.acc] as? Int).to(equal(477))
                    expect(jsonArray?[0][PayloadParameterKeys.aid] as? Int).to(equal(1))

                    expect(jsonArray?[0][PayloadParameterKeys.etype] as? String).to(equal("_rem_internal_install"))

                    let cpDictionary = jsonArray?[0][PayloadParameterKeys.cp] as? [String: Any]
                    expect(cpDictionary).toNot(beNil())

                    expect(cpDictionary?.appInfo).to(equal(appInfoMock))

                    expect(cpDictionary?.sdkDependencies).to(equal(sdkDependenciesMock))
                }
            }
        }
    }
}

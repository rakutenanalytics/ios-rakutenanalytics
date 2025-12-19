import Foundation
import SQLite3
import Testing
@preconcurrency @testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - ProcessTestHelper

enum ProcessTestHelper {
    static let appInfoMock = "{\"xcode\":\"1410.14B47a\",\"sdk\":\"iphonesimulator16.1.inner\",\"deployment_target\":\"11.0\"}"
    static let sdkDependenciesMock = ["rsdks_inappmessaging": "7.2.0",
                                      "rsdks_pushpnp": "10.0.0",
                                      "rsdks_geo": "2.2.0",
                                      "rsdks_pitari": "3.0.0"]
    
    // MARK: - Test Helper
    
    struct TestHelper {
        var databaseConnection: SQlite3Pointer!
        var database: RAnalyticsDatabase!
        let dependenciesContainer = SimpleContainerMock()
        var ratTracker: RAnalyticsRATTracker!
        let expecter = RAnalyticsRATExpecter()
        let coreInfosCollectorMock = CoreInfosCollectorMock(appInfo: appInfoMock, sdkDependencies: sdkDependenciesMock)
        
        mutating func setUp() {
            let databaseTableName = "testTableName_RAnalyticsRATTrackerTests"
            databaseConnection = DatabaseTestUtils.openRegularConnection()!
            database = DatabaseTestUtils.mkDatabase(connection: databaseConnection)
            
            let bundle = BundleMock()
            bundle.accountIdentifier = 777
            bundle.applicationIdentifier = 888
            bundle.endpointAddress = URL(string: "https://endpoint.co.jp/")!
            
            dependenciesContainer.bundle = bundle
            dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database, tableName: databaseTableName)
            dependenciesContainer.session = SwiftyURLSessionMock()
            dependenciesContainer.deviceCapability = DeviceMock()
            dependenciesContainer.telephonyNetworkInfoHandler = TelephonyNetworkInfoMock()
            dependenciesContainer.analyticsStatusBarOrientationGetter = ApplicationMock(.portrait)
            dependenciesContainer.coreInfosCollector = coreInfosCollectorMock
            dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
                bundle: bundle,
                deviceCapability: dependenciesContainer.deviceCapability,
                screenHandler: dependenciesContainer.screenHandler,
                telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
                notificationHandler: dependenciesContainer.notificationHandler,
                analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
                reachability: Reachability(),
                userStorageHandler: dependenciesContainer.userStorageHandler)
            
            ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
            ratTracker.set(batchingDelay: 0)
            
            expecter.dependenciesContainer = dependenciesContainer
            expecter.endpointURL = dependenciesContainer.bundle.endpointAddress
            expecter.databaseTableName = dependenciesContainer.databaseConfiguration?.tableName
            expecter.databaseConnection = databaseConnection
            expecter.ratTracker = ratTracker
        }
        
        mutating func tearDown() {
            DatabaseTestUtils.deleteTableIfExists(dependenciesContainer.databaseConfiguration!.tableName, connection: databaseConnection)
            database.closeConnection()
            databaseConnection = nil
        }
        
        func verifyCoreInfos(for eventName: String) async throws {
            let event = RAnalyticsEvent(name: eventName, parameters: nil)
            var appInfoPayload: String?
            var sdkDependencies: [String: String]?
            
            try await expecter.expectEventAsync(event, state: Tracking.defaultState, equal: eventName) {
                let cp = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                appInfoPayload = cp?.appInfo
                sdkDependencies = cp?.sdkDependencies
            }
            
            try await TestingHelpers.eventually {
                appInfoPayload != nil
            }
            #expect(appInfoPayload == appInfoMock)
            #expect(sdkDependencies == sdkDependenciesMock)
        }
    }
}

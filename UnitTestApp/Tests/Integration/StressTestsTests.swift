import Foundation
import CoreLocation
import Testing
import UIKit
import CoreTelephony
import AdSupport
import WebKit
@testable import RakutenAnalytics

#if canImport(RAnalyticsTestHelpers)
import class RAnalyticsTestHelpers.TrackerMock
import class RAnalyticsTestHelpers.URLSessionMock
import class RAnalyticsTestHelpers.WKHTTPCookieStorageMock
#endif

@Suite("Stress tests", .serialized)
struct StressTestsTests {
    private static let stressContainer = StressDependenciesContainer()
    private static let endpointManager = AnalyticsManager(dependenciesContainer: stressContainer)
    
    @Test("RAnalyticsSender send/upload concurrent calls do not crash")
    func sendUploadConcurrentCallsDoNotCrash() async throws {
        guard let publicSender = makeSender() else { return }
        try await stressUploadTimer(publicSender: publicSender, iterations: 100_000)
    }
    
    @Test("RAnalyticsSender concurrent send with failing requests does not crash")
    func sendUploadConcurrentCallsWithFailingRequestsDoNotCrash() async throws {
        guard let publicSender = makeSender() else { return }
        
        let sessionMock = URLSessionMock.mock(originalInstance: .shared)
        URLSessionMock.startMockingURLSession()
        defer { URLSessionMock.stopMockingURLSession() }
        
        sessionMock.stubResponse(statusCode: 400)
        try await stressUploadTimer(publicSender: publicSender, iterations: 100_000)
    }
    
    @Test("AnalyticsManager addTracker concurrent calls do not crash")
    func addTrackerConcurrentCallsDoNotCrash() async throws {
        let analyticsManager = AnalyticsManager(dependenciesContainer: StressTestsTests.stressContainer)
        let iterations = 100_000
        
        let waitResult = try await runConcurrently(iterations: iterations, timeout: 30) {
            analyticsManager.add(TrackerMock())
        }
        #expect(waitResult == .success, "Timed out waiting for background add() calls")
    }
    
    @Test("AnalyticsManager setEndpoint concurrent calls do not crash")
    func setEndpointConcurrentCallsDoNotCrash() async throws {
        let analyticsManager = StressTestsTests.endpointManager
        let iterations = 100_000
        
        let waitResult = try await runConcurrently(iterations: iterations, timeout: 30) {
            analyticsManager.set(endpointURL: URL(string: "https://endpoint.com")!)
        }
        #expect(waitResult == .success, "Timed out waiting for background set(endpointURL:) calls")
    }
    
    private func stressUploadTimer(publicSender: RAnalyticsSender, iterations: Int) async throws {
        publicSender.setBatchingDelayBlock(0.1)
        
        let waitResult = try await runConcurrently(iterations: iterations, timeout: 30) {
            publicSender.send(jsonObject: ["key1": "value1", "key2": "value2"])
        }
        #expect(waitResult == .success, "Timed out waiting for background send() calls")
    }
    
    private func makeSender() -> RAnalyticsSender? {
        let publicSender = RAnalyticsSender(
            endpoint: URL(string: "https://endpoint.com")!,
            databaseName: "stress-sender-\(UUID().uuidString).db",
            databaseTableName: "stress_sender_table"
        )
        #expect(publicSender != nil, "Failed to create RAnalyticsSender")
        return publicSender
    }
    
    /// Runs the provided block concurrently without blocking the test thread.
    /// This avoids Thread Performance Checker QoS inversion warnings caused by synchronous waits.
    private func runConcurrently(iterations: Int, timeout: TimeInterval, block: @escaping () -> Void) async throws -> DispatchTimeoutResult {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let worker: @Sendable () -> Void = {
                for _ in 1...iterations { block() }
            }
            
            group.addTask { await Task.detached(priority: .utility, operation: worker).value }
            group.addTask { await Task.detached(priority: .utility, operation: worker).value }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimeoutError()
            }
            
            do {
                // Wait for the first two worker tasks; if timeout wins, we'll throw.
                var completedWorkers = 0
                while completedWorkers < 2 {
                    _ = try await group.next()
                    completedWorkers += 1
                }
                group.cancelAll()
                return .success
            } catch is TimeoutError {
                group.cancelAll()
                return .timedOut
            }
        }
    }
    
    private struct TimeoutError: Error {}
    
    private struct StressDependenciesContainer: SimpleDependenciesContainable {
        let notificationHandler: NotificationObservable = NotificationCenter.default
        let userStorageHandler: UserStorageHandleable = UserDefaults.standard
        let sharedUserStorageHandlerType: UserStorageHandleable.Type = UserDefaults.self
        let adIdentifierManager: AdvertisementIdentifiable = ASIdentifierManager.shared()
        let wkHttpCookieStore: WKHTTPCookieStorable = WKHTTPCookieStorageMock()
        let httpCookieStore: HTTPCookieStorable = HTTPCookieStorage.shared
        let keychainHandler: KeychainHandleable = KeychainHandler(bundle: Bundle.main)
        let locationManager: LocationManageable = CLLocationManager()
        let bundle: EnvironmentBundle = Bundle.main
        let telephonyNetworkInfoHandler: TelephonyNetworkInfoHandleable = CTTelephonyNetworkInfo()
        let deviceCapability: DeviceCapability = UIDevice.current
        let screenHandler: Screenable = UIScreen.screenableFromScene
        let session: SwiftySessionable = URLSession.shared
        let analyticsStatusBarOrientationGetter: StatusBarOrientationGettable? = UIApplication.RAnalyticsSharedApplication
        let databaseConfiguration: DatabaseConfigurable? = {
            DatabaseConfigurationHandler.create(
                databaseName: "stress-\(UUID().uuidString).db",
                tableName: "stress_table",
                databaseParentDirectory: .cachesDirectory
            )
        }()
        let pushEventHandler: PushEventHandleable
        let coreInfosCollector: CoreInfosCollectable = CoreInfosCollector()
        let automaticFieldsBuilder: AutomaticFieldsBuildable
        let applicationStateGetter: ApplicationStateGettable? = UIApplication.RAnalyticsSharedApplication
        
        init() {
            let appGroupId = bundle.appGroupId
            let sharedUserStorageHandler = sharedUserStorageHandlerType.init(suiteName: appGroupId)
            pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserStorageHandler, appGroupId: appGroupId)
            automaticFieldsBuilder = AutomaticFieldsBuilder(
                bundle: bundle,
                deviceCapability: deviceCapability,
                screenHandler: screenHandler,
                telephonyNetworkInfoHandler: telephonyNetworkInfoHandler,
                notificationHandler: notificationHandler,
                analyticsStatusBarOrientationGetter: analyticsStatusBarOrientationGetter,
                reachability: Reachability(),
                userStorageHandler: userStorageHandler)
        }
    }
}

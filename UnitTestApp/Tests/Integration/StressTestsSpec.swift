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
struct StressTestsSpec {
    private static let backgroundThread = DispatchQueue(label: "StressTests.Background", qos: .default)
    private static let stressContainer = StressDependenciesContainer()
    private static let endpointManager = AnalyticsManager(dependenciesContainer: stressContainer)

    private let backgroundThread = StressTestsSpec.backgroundThread

    @Test("RAnalyticsSender send/upload concurrent calls do not crash")
    func sendUploadConcurrentCallsDoNotCrash() {
        guard let publicSender = makeSender() else { return }
        stressUploadTimer(publicSender: publicSender, iterations: 100_000)
    }

    @Test("RAnalyticsSender concurrent send with failing requests does not crash")
    func sendUploadConcurrentCallsWithFailingRequestsDoNotCrash() {
        guard let publicSender = makeSender() else { return }

        let sessionMock = URLSessionMock.mock(originalInstance: .shared)
        URLSessionMock.startMockingURLSession()
        defer { URLSessionMock.stopMockingURLSession() }

        sessionMock.stubResponse(statusCode: 400)
        stressUploadTimer(publicSender: publicSender, iterations: 100_000)
    }

    @Test("AnalyticsManager addTracker concurrent calls do not crash")
    func addTrackerConcurrentCallsDoNotCrash() {
        let analyticsManager = AnalyticsManager(dependenciesContainer: StressTestsSpec.stressContainer)
        let iterations = 10_000

        let waitResult = runConcurrently(iterations: iterations, timeout: 30) {
            analyticsManager.add(TrackerMock())
        }
        #expect(waitResult == .success, "Timed out waiting for background add() calls")
    }

    @Test("AnalyticsManager setEndpoint concurrent calls do not crash")
    func setEndpointConcurrentCallsDoNotCrash() {
        let analyticsManager = StressTestsSpec.endpointManager
        let iterations = 100_000

        let waitResult = runConcurrently(iterations: iterations, timeout: 30) {
            analyticsManager.set(endpointURL: URL(string: "https://endpoint.com")!)
        }
        #expect(waitResult == .success, "Timed out waiting for background set(endpointURL:) calls")
    }

    private func stressUploadTimer(publicSender: RAnalyticsSender, iterations: Int) {
        publicSender.setBatchingDelayBlock(0.1)

        let waitResult = runConcurrently(iterations: iterations, timeout: 30) {
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

    /// Runs the provided block concurrently on the background thread and the current thread.
    private func runConcurrently(iterations: Int, timeout: TimeInterval, block: @escaping () -> Void) -> DispatchTimeoutResult {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()

        backgroundThread.async {
            for _ in 1...iterations {
                block()
            }
            dispatchGroup.leave()
        }
        for _ in 1...iterations {
            block()
        }
        return dispatchGroup.wait(timeout: .now() + timeout)
    }

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
        let screenHandler: Screenable = UIScreen.main
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
            pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserStorageHandler,
                                                appGroupId: appGroupId)
            automaticFieldsBuilder = AutomaticFieldsBuilder(bundle: bundle,
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

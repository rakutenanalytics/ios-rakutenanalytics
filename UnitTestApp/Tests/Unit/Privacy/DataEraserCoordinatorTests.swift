import Testing
import Foundation
import SQLite3
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - Helpers

private enum ClearDataTestKeys {
    static let loginState = "com.rakuten.esd.sdk.properties.analytics.loginInformation.loginState"
    static let trackingIdentifier = "com.rakuten.esd.sdk.properties.analytics.loginInformation.trackingIdentifier"
    static let userIdentifier = "com.rakuten.esd.sdk.properties.analytics.loginInformation.userIdentifier"
    static let easyIdentifier = "com.rakuten.esd.sdk.properties.analytics.loginInformation.easyIdentifier"
    static let loginMethod = "com.rakuten.esd.sdk.properties.analytics.loginInformation.loginMethod"
    static let initialLaunchDate = "com.rakuten.esd.sdk.properties.analytics.launchInformation.initialLaunchDate"
    static let installLaunchDate = "com.rakuten.esd.sdk.properties.analytics.launchInformation.installLaunchDate"
    static let lastUpdateDate = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastUpdateDate"
    static let lastLaunchDate = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastLaunchDate"
    static let lastVersion = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersion"
    static let lastVersionLaunches = "com.rakuten.esd.sdk.properties.analytics.launchInformation.lastVersionLaunches"
}

private func awaitClearData(on erasable: DataErasable) async throws {
    try await erasable.clearData()
}

private func awaitCoordinatorClearData(_ coordinator: DataEraserCoordinator) async throws {
    try await coordinator.clearData()
}

private func insertBlob(_ blob: Data, into table: String, database: RAnalyticsDatabase) async {
    await database.insert(blob: blob, into: table, limit: 10)
}

private func fetchBlobCount(from table: String, database: RAnalyticsDatabase) async -> Int {
    let result = await database.fetchBlobs(100, from: table)
    return result.blobs?.count ?? 0
}

private func makeLaunchCollectorDependencies() -> SimpleContainerMock {
    let container = SimpleContainerMock()
    let bundle = BundleMock()
    bundle.dictionary = [AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey: "group.test"]
    container.bundle = bundle
    container.keychainHandler = KeychainHandlerMock()
    container.userStorageHandler = UserDefaultsMock([:])
    container.sharedUserStorageHandlerType = UserDefaultsMock.self
    let sharedStorage = container.sharedUserStorageHandlerType.init(suiteName: container.bundle.appGroupId)
    container.pushEventHandler = PushEventHandler(
        sharedUserStorageHandler: sharedStorage,
        appGroupId: container.bundle.appGroupId)
    return container
}

// MARK: - DataEraserCoordinator

@Suite("DataEraserCoordinator")
struct DataEraserCoordinatorTests {

    private final class ErasableSpy: DataErasable {
        private(set) var clearCount = 0
        private let onClear: (() -> Void)?

        init(onClear: (() -> Void)? = nil) {
            self.onClear = onClear
        }

        func clearData() async throws {
            clearCount += 1
            onClear?()
        }
    }

    @Test("should invoke every erasable once")
    func invokesEveryErasableOnce() async throws {
        let first = ErasableSpy()
        let second = ErasableSpy()
        let coordinator = DataEraserCoordinator(erasables: [first, second])

        try await awaitCoordinatorClearData(coordinator)
        #expect(first.clearCount == 1)
        #expect(second.clearCount == 1)
    }

    private final class BlockingErasable: DataErasable {
        var release: (() -> Void)?

        func clearData() async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                release = { continuation.resume() }
            }
        }
    }

    @Test("async clearData should return alreadyRunning when called concurrently")
    func asyncClearDataReturnsAlreadyRunningForConcurrentCalls() async {
        let blocking = BlockingErasable()
        let coordinator = DataEraserCoordinator(erasables: [blocking])

        let firstTask = Task {
            try await coordinator.clearData()
        }

        try? await Task.sleep(nanoseconds: 50_000_000)

        do {
            try await coordinator.clearData()
            Issue.record("Expected concurrent async clearData to throw alreadyRunning")
        } catch let error as ClearDataError {
            #expect(error == .alreadyRunning)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }

        blocking.release?()
        _ = try? await firstTask.value
    }

    @Test("should bridge to NSError with SDK domain, code, and description")
    func bridgesToNSErrorWithSDKMetadata() {
        let error = ClearDataError.alreadyRunning as NSError

        #expect(error.domain == ErrorDomain.analyticsManagerErrorDomain)
        #expect(error.code == ErrorCode.clearDataAlreadyRunning.rawValue)
        #expect(error.localizedDescription == ErrorDescription.clearDataAlreadyRunning)
    }
}

// MARK: - RAnalyticsLaunchCollector

@Suite("RAnalyticsLaunchCollector clearData")
struct RAnalyticsLaunchCollectorClearDataTests {

    @Test("should clear persisted launch data and reset in-memory state")
    func clearsPersistedLaunchDataAndResetsState() async throws {
        let container = makeLaunchCollectorDependencies()
        let storage = container.userStorageHandler as? UserDefaultsMock
        let keychain = container.keychainHandler as? KeychainHandlerMock
        keychain?.status = errSecSuccess
        keychain?.set(creationDate: Date(), for: ClearDataTestKeys.initialLaunchDate)

        storage?.set(value: Date(), forKey: ClearDataTestKeys.installLaunchDate)
        storage?.set(value: Date(), forKey: ClearDataTestKeys.lastUpdateDate)
        storage?.set(value: Date(), forKey: ClearDataTestKeys.lastLaunchDate)
        storage?.set(value: "1.0.0", forKey: ClearDataTestKeys.lastVersion)
        storage?.set(value: NSNumber(value: 3), forKey: ClearDataTestKeys.lastVersionLaunches)

        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: container)
        launchCollector.origin = .external
        launchCollector.referralTracking = .externalReferral(URL(string: "https://example.com")!)

        try await awaitClearData(on: launchCollector)

        #expect(keychain?.creationDate(for: nil) == nil)
        #expect(storage?.object(forKey: ClearDataTestKeys.installLaunchDate) == nil)
        #expect(storage?.object(forKey: ClearDataTestKeys.lastUpdateDate) == nil)
        #expect(storage?.object(forKey: ClearDataTestKeys.lastLaunchDate) == nil)
        #expect(storage?.object(forKey: ClearDataTestKeys.lastVersion) == nil)
        #expect(storage?.object(forKey: ClearDataTestKeys.lastVersionLaunches) == nil)
        #expect(launchCollector.isInitialLaunch == true)
        #expect(launchCollector.isInstallLaunch == true)
        #expect(launchCollector.origin == .inner)
        #expect(launchCollector.referralTracking == .none)
    }

    @Test("should clear push tracking cache")
    func clearsPushTrackingCache() async throws {
        let container = makeLaunchCollectorDependencies()
        guard let pushEventHandler = container.pushEventHandler as? PushEventHandler else {
            Issue.record("Expected PushEventHandler")
            return
        }
        guard let sharedStorage = pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock else {
            Issue.record("Expected UserDefaultsMock shared storage")
            return
        }
        sharedStorage.set(value: [PushEventHandlerTests.sentTrackingId: true], forKey: PushEventHandlerKeys.openCountSentUserDefaultKey)
        sharedStorage.set(value: PushEventHandlerTests.eventsToCache, forKey: PushEventHandlerKeys.openCountCachedEventsKey)

        let launchCollector = RAnalyticsLaunchCollector(dependenciesContainer: container)
        try await awaitClearData(on: launchCollector)

        #expect(sharedStorage.object(forKey: PushEventHandlerKeys.openCountSentUserDefaultKey) == nil)
        #expect((sharedStorage.array(forKey: PushEventHandlerKeys.openCountCachedEventsKey)?.isEmpty) == true)
    }
}

// MARK: - RAnalyticsExternalCollector

@Suite("RAnalyticsExternalCollector clearData")
struct RAnalyticsExternalCollectorClearDataTests {

    @Test("should clear persisted login data and reset in-memory state")
    func clearsPersistedLoginDataAndResetsState() async throws {
        let container = SimpleContainerMock()
        let storage = UserDefaultsMock([:])
        let keychain = KeychainHandlerMock()
        keychain.status = errSecSuccess
        container.userStorageHandler = storage
        container.keychainHandler = keychain

        storage.set(value: true, forKey: ClearDataTestKeys.loginState)
        storage.set(value: "member-id", forKey: ClearDataTestKeys.trackingIdentifier)
        storage.set(value: "user-id", forKey: ClearDataTestKeys.userIdentifier)
        storage.set(value: NSNumber(value: AnalyticsManager.State.LoginMethod.passwordInput.rawValue), forKey: ClearDataTestKeys.loginMethod)
        try keychain.set(value: "easy-id", for: ClearDataTestKeys.easyIdentifier)

        let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: container)
        #expect(externalCollector.isLoggedIn == true)
        #expect(externalCollector.trackingIdentifier == "member-id")
        #expect(externalCollector.userIdentifier == "user-id")
        #expect(externalCollector.easyIdentifier == "easy-id")
        #expect(externalCollector.loginMethod == .passwordInput)

        try await awaitClearData(on: externalCollector)

        #expect(storage.bool(forKey: ClearDataTestKeys.loginState) == false)
        #expect(storage.string(forKey: ClearDataTestKeys.trackingIdentifier) == nil)
        #expect(storage.string(forKey: ClearDataTestKeys.userIdentifier) == nil)
        #expect((storage.object(forKey: ClearDataTestKeys.loginMethod) as? NSNumber)?.uintValue == AnalyticsManager.State.LoginMethod.other.rawValue)
        #expect(try keychain.string(for: ClearDataTestKeys.easyIdentifier) == nil)
        #expect(externalCollector.isLoggedIn == false)
        #expect(externalCollector.trackingIdentifier == nil)
        #expect(externalCollector.userIdentifier == nil)
        #expect(externalCollector.easyIdentifier == nil)
        #expect(externalCollector.loginMethod == .other)
    }
}

// MARK: - RAnalyticsCookieInjector

@Suite("RAnalyticsCookieInjector clearData")
struct RAnalyticsCookieInjectorClearDataTests {
    static let deviceID = "cc851516e51366f4856d165c3ea117e592db6fba"
    static let analyticsCookieName = "ra_uid"

    @Test("should remove injected cookies via clearData")
    @MainActor
    func removesInjectedCookiesViaClearData() async throws {
        let cookieStore = WKHTTPCookieStorageMock()
        let container = SimpleContainerMock()
        container.wkHttpCookieStore = cookieStore
        let cookieInjector = RAnalyticsCookieInjector(dependenciesContainer: container)

        _ = await cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: Self.deviceID)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            cookieInjector.clearData {
                continuation.resume()
            }
        }

        let cookies = await cookieStore.allCookies()
        let hasCookie = cookies.contains { $0.name == Self.analyticsCookieName }
        #expect(hasCookie == false)
    }
}

// MARK: - AnalyticsManagerSessionEraser

@Suite("AnalyticsManagerSessionEraser clearData")
struct AnalyticsManagerSessionEraserClearDataTests {

    @Test("should clear session carrier names and user agent")
    func clearsSessionCarrierNamesAndUserAgent() async throws {
        let storage = UserDefaultsMock([:])
        let container = SimpleContainerMock()
        container.userStorageHandler = storage

        let manager = AnalyticsManager(dependenciesContainer: container)
        manager.setCarrierNames(primary: "Primary Carrier", secondary: "Secondary Carrier")
        storage.set(value: "CustomUserAgent", forKey: UserDefaultsKeys.userAgentKey)

        let sessionEraser = AnalyticsManagerSessionEraser(delegate: manager)
        try await awaitClearData(on: sessionEraser)

        let carrierNames = manager.getCarrierNames()
        #expect(carrierNames.primary == nil)
        #expect(carrierNames.secondary == nil)
        #expect(storage.object(forKey: UserDefaultsKeys.userAgentKey) == nil)
    }
}

// MARK: - RAnalyticsDatabase deleteAllBlobs

@Suite("RAnalyticsDatabase deleteAllBlobs")
struct RAnalyticsDatabaseDeleteAllBlobsTests {

    @Test("should delete all queued blobs from table")
    func deletesAllQueuedBlobsFromTable() async throws {
        guard let connection = DatabaseTestUtils.openRegularConnection() else {
            Issue.record("Failed to open SQLite connection")
            return
        }
        defer { sqlite3_close_v2(connection) }

        let database = DatabaseTestUtils.mkDatabase(connection: connection)
        database.enabled = true
        let tableName = "CLEAR_DATA_TEST_TABLE"
        let blob = "{\"etype\":\"pv\"}".data(using: .utf8)!

        await insertBlob(blob, into: tableName, database: database)
        let countBefore = await fetchBlobCount(from: tableName, database: database)
        #expect(countBefore == 1)

        try await withCheckedThrowingContinuation { continuation in
            database.deleteAllBlobs(in: tableName) {
                continuation.resume()
            }
        }

        let countAfter = await fetchBlobCount(from: tableName, database: database)
        #expect(countAfter == 0)
    }

    @Test("should complete immediately when database is disabled")
    func completesImmediatelyWhenDatabaseDisabled() async throws {
        guard let connection = DatabaseTestUtils.openRegularConnection() else {
            Issue.record("Failed to open SQLite connection")
            return
        }
        defer { sqlite3_close_v2(connection) }

        let database = DatabaseTestUtils.mkDatabase(connection: connection)
        database.enabled = false

        try await withCheckedThrowingContinuation { continuation in
            database.deleteAllBlobs(in: "DISABLED_TABLE") {
                continuation.resume()
            }
        }
    }
}

// MARK: - RAnalyticsRATTracker

@Suite("RAnalyticsRATTracker clearData")
struct RAnalyticsRATTrackerClearDataTests {

    @Test("should clear queued events and carrier names")
    func clearsQueuedEventsAndCarrierNames() async throws {
        var helper = PayloadTestHelper.TestHelper()
        helper.setUp()
        defer { helper.tearDown() }

        let tableName = helper.dependenciesContainer.databaseConfiguration!.tableName
        let blob = "{\"etype\":\"pv\"}".data(using: .utf8)!
        await insertBlob(blob, into: tableName, database: helper.database)

        helper.ratTracker.updateCarrierNames(mcn: "Primary", mcnd: "Secondary")
        #expect(helper.ratTracker.getCarrierNames().primary == "Primary")

        try await awaitClearData(on: helper.ratTracker)

        let blobCount = await fetchBlobCount(from: tableName, database: helper.database)
        #expect(blobCount == 0)
        #expect(helper.ratTracker.getCarrierNames().primary == nil)
        #expect(helper.ratTracker.getCarrierNames().secondary == nil)
    }

    @Test("should clear Rp cookies from HTTP cookie storage")
    func clearsRpCookiesFromHTTPCookieStorage() async throws {
        var helper = PayloadTestHelper.TestHelper()
        helper.setUp()
        defer { helper.tearDown() }

        let endpoint = URL(string: "https://endpoint.co.jp")!
        guard let bundleMock = helper.dependenciesContainer.bundle as? BundleMock else {
            Issue.record("Expected BundleMock for RP cookie clearing test")
            return
        }
        bundleMock.endpointAddress = endpoint

        guard let cookieStorage = helper.dependenciesContainer.httpCookieStore as? HTTPCookieStorage else {
            Issue.record("Expected HTTPCookieStorage for RP cookie clearing test")
            return
        }

        let rpCookie = HTTPCookie(properties: [
            .name: RATConstants.RpCookie.cookieName,
            .value: "rp-test-value",
            .domain: "endpoint.co.jp",
            .path: "/"
        ])!
        cookieStorage.setCookie(rpCookie)
        #expect(cookieStorage.cookies(for: endpoint)?.contains(where: { $0.name == RATConstants.RpCookie.cookieName }) == true)

        try await awaitClearData(on: helper.ratTracker)

        #expect(cookieStorage.cookies(for: endpoint)?.contains(where: { $0.name == RATConstants.RpCookie.cookieName }) != true)
    }
}

// MARK: - GeoTracker

@Suite("GeoTracker clearData")
struct GeoTrackerClearDataTests {

    @Test("should clear queued geo events from database")
    func clearsQueuedGeoEventsFromDatabase() async throws {
        let bundle = BundleMock()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        let dependenciesContainer = GeoContainerMock()
        dependenciesContainer.bundle = bundle

        guard let connection = DatabaseTestUtils.openRegularConnection() else {
            Issue.record("Failed to open SQLite connection")
            return
        }
        defer { sqlite3_close_v2(connection) }

        let database = DatabaseTestUtils.mkDatabase(connection: connection)
        database.enabled = true
        let tableName = "GEO_CLEAR_DATA_TABLE"
        let databaseConfiguration = DatabaseConfiguration(database: database, tableName: tableName)

        guard let geoTracker = GeoTracker(
                dependenciesContainer: dependenciesContainer,
                databaseConfiguration: databaseConfiguration) else {
            Issue.record("Failed to create GeoTracker")
            return
        }

        let blob = "{\"etype\":\"loc\"}".data(using: .utf8)!
        await insertBlob(blob, into: tableName, database: database)
        #expect(await fetchBlobCount(from: tableName, database: database) == 1)

        try await awaitClearData(on: geoTracker)

        #expect(await fetchBlobCount(from: tableName, database: database) == 0)
    }
}

// MARK: - GeoManager

@Suite("GeoManager clearData")
struct GeoManagerClearDataTests {

    @Test("should stop location collection and clear geo tracker queue")
    @MainActor
    func stopsLocationCollectionAndClearsGeoTrackerQueue() async throws {
        let bundle = BundleMock()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        let dependenciesContainer = GeoContainerMock()
        dependenciesContainer.bundle = bundle

        guard let connection = DatabaseTestUtils.openRegularConnection() else {
            Issue.record("Failed to open SQLite connection")
            return
        }
        defer { sqlite3_close_v2(connection) }

        let database = DatabaseTestUtils.mkDatabase(connection: connection)
        database.enabled = true
        let tableName = "GEO_MANAGER_CLEAR_DATA_TABLE"
        let databaseConfiguration = DatabaseConfiguration(database: database, tableName: tableName)

        guard let geoTracker = GeoTracker(
                dependenciesContainer: dependenciesContainer,
                databaseConfiguration: databaseConfiguration) else {
            Issue.record("Failed to create GeoTracker")
            return
        }

        let blob = "{\"etype\":\"loc\"}".data(using: .utf8)!
        await insertBlob(blob, into: tableName, database: database)

        let geoLocationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManagerMock,
            device: UIDevice.current,
            geoTracker: geoTracker,
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))

        dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.configurationKey)
        geoManager.startLocationCollection()
        try await TestingHelpers.eventuallyOnMain(timeout: 1.0) {
            geoLocationManagerMock.startMonitoringSignificantLocationChangesIsCalled
        }

        try await awaitClearData(on: geoManager)

        #expect(geoLocationManagerMock.stopMonitoringSignificantLocationChangesIsCalled == true)
        #expect(await fetchBlobCount(from: tableName, database: database) == 0)
    }
}

// MARK: - AnalyticsManager clearData

@Suite("AnalyticsManager clearData")
struct AnalyticsManagerClearDataTests {

    @Test("should clear persisted login and launch information")
    func clearsPersistedLoginAndLaunchInformation() async throws {
        let storage = UserDefaultsMock([:])
        let keychain = KeychainHandlerMock()
        keychain.status = errSecSuccess

        let container = SimpleContainerMock()
        container.userStorageHandler = storage
        container.keychainHandler = keychain

        let manager = AnalyticsManager(dependenciesContainer: container)
        let launchCollector = manager.launchCollector

        storage.set(value: true, forKey: ClearDataTestKeys.loginState)
        storage.set(value: "member", forKey: ClearDataTestKeys.trackingIdentifier)
        storage.set(value: Date(), forKey: ClearDataTestKeys.installLaunchDate)
        storage.set(value: "UserAgentValue", forKey: UserDefaultsKeys.userAgentKey)

        try await manager.clearData()
        #expect(storage.bool(forKey: ClearDataTestKeys.loginState) == false)
        #expect(storage.string(forKey: ClearDataTestKeys.trackingIdentifier) == nil)
        #expect(storage.object(forKey: ClearDataTestKeys.installLaunchDate) == nil)
        #expect(storage.object(forKey: UserDefaultsKeys.userAgentKey) == nil)
        #expect(launchCollector.isInitialLaunch == true)
    }

    @Test("should clear session carrier names")
    func clearsSessionCarrierNames() async throws {
        let container = SimpleContainerMock()
        container.userStorageHandler = UserDefaultsMock([:])
        let manager = AnalyticsManager(dependenciesContainer: container)

        manager.setCarrierNames(primary: "Carrier A", secondary: "Carrier B")
        try await manager.clearData()

        let carrierNames = manager.getCarrierNames()
        #expect(carrierNames.primary == nil)
        #expect(carrierNames.secondary == nil)
    }

    @Test("should clear injected web tracking cookies")
    @MainActor
    func clearsInjectedWebTrackingCookies() async throws {
        let cookieStore = WKHTTPCookieStorageMock()
        let container = SimpleContainerMock()
        container.wkHttpCookieStore = cookieStore
        container.userStorageHandler = UserDefaultsMock([:])

        let manager = AnalyticsManager(dependenciesContainer: container)
        let cookieInjector = RAnalyticsCookieInjector(dependenciesContainer: container)
        let deviceID = "cc851516e51366f4856d165c3ea117e592db6fba"
        let cookieName = "ra_uid"

        _ = await cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID)

        let cookiesBeforeClear = await cookieStore.allCookies()
        #expect(cookiesBeforeClear.contains { $0.name == cookieName })

        try await manager.clearData()

        let cookiesAfterClear = await cookieStore.allCookies()
        #expect(!cookiesAfterClear.contains { $0.name == cookieName })
    }
}

import Testing
import Foundation
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("RAnalyticsSender")
struct SenderTests {
    let session = SwiftyURLSessionMock()
    let databaseTableName = "testTableName"
    let payload = ["key": "value"]
    let bundle = BundleMock()
    var userDefaultsMock: UserDefaultsMock!

    var sender: RAnalyticsSender!
    var databaseConnection: SQlite3Pointer!
    var database: RAnalyticsDatabase!

    private static let endpointURL = "https://endpoint.co.jp/"

    /// Observable seam: upload pipeline reached the mocked URLSession.
    private static func expectUploadReachedMockSession(_ session: SwiftyURLSessionMock) {
        #expect(session.urlRequest != nil)
        #expect(session.urlRequest?.url?.absoluteString == endpointURL)
    }

    private func fetchDatabaseContents() -> [Data] {
        DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection)
    }

    mutating func setUp() {
        databaseConnection = DatabaseTestUtils.openRegularConnection()
        database = DatabaseTestUtils.mkDatabase(connection: databaseConnection)
        userDefaultsMock = UserDefaultsMock([:])

        sender = RAnalyticsSender(
            endpoint: URL(string: "https://endpoint.co.jp/")!,
            database: database,
            databaseTable: databaseTableName,
            bundle: bundle,
            session: session,
            userStorageHandler: userDefaultsMock,
            allowsAnalyticsSend: AnalyticsSendPolicy.makeDefaultSendPredicate(for: bundle))
    }

    mutating func tearDown() {
        sender.setBatchingDelayBlock(0)
        sender.fetchAndUpload()

        DatabaseTestUtils.deleteTableIfExists(databaseTableName, connection: databaseConnection)
        database.closeConnection()
        databaseConnection = nil
        database = nil

        bundle.mutableEnableInternalSerialization = false
        bundle.isManualInitializationEnabled = false
        AnalyticsManager.isConfigured = true
    }

    @Suite("initialization")
    struct InitializationTests {
        @Test("should set enableBackgroundTimerUpdate to false")
        func testShouldSetEnableBackgroundTimerUpdateToFalse() {
            var spec = SenderTests()
            spec.setUp()
            defer { spec.tearDown() }

            var isNone = false

            if case .none = spec.sender.backgroundTimerEnabler {
                isNone = true
            }

            #expect(isNone == true)
        }
    }

    @Suite("JSON serialization")
    struct JSONSerializationTests {
        @Test("should send given payload when enableInternalSerialization is false")
        func testShouldSendPayloadWhenEnableInternalSerializationIsFalse() async throws {
            var spec = SenderTests()
            spec.setUp()
            defer { spec.tearDown() }

            spec.bundle.mutableEnableInternalSerialization = false
            try await TestingHelpers.awaitSenderUpload(session: spec.session) {
                spec.sender.send(jsonObject: spec.payload)
            }
            SenderTests.expectUploadReachedMockSession(spec.session)
        }

        @Test("should send given payload when enableInternalSerialization is true")
        func testShouldSendPayloadWhenEnableInternalSerializationIsTrue() async throws {
            var spec = SenderTests()
            spec.setUp()
            defer { spec.tearDown() }

            spec.bundle.mutableEnableInternalSerialization = true
            try await TestingHelpers.awaitSenderUpload(session: spec.session) {
                spec.sender.send(jsonObject: spec.payload)
            }
            SenderTests.expectUploadReachedMockSession(spec.session)
        }
    }

    @Suite("enableBackgroundTimerUpdate")
    struct EnableBackgroundTimerUpdateTests {
        static let geoScheduleStartTimeKey = "RATGeoScheduleStartTime"
        var isSendingCompleted = false

        mutating func setUpSender() {
            var spec = SenderTests()
            spec.setUp()
            // Note: We need to create a new sender with maxUploadInterval
            spec.sender = RAnalyticsSender(endpoint: URL(string: "https://endpoint.co.jp/")!,
                                           database: spec.database,
                                           databaseTable: spec.databaseTableName,
                                           bundle: spec.bundle,
                                           session: URLSession.shared,
                                           maxUploadInterval: 900.0,
                                           userStorageHandler: spec.userDefaultsMock,
                                           allowsAnalyticsSend: AnalyticsSendPolicy.makeDefaultSendPredicate(for: spec.bundle))
        }

        @Suite("When setting enableBackgroundTimerUpdate to false")
        struct WhenSettingEnableBackgroundTimerUpdateToFalseTests {
            @Suite("When the batching delay is set to 0")
            struct WhenBatchingDelayIsSetToZeroTests {
                @Suite("When not sending data")
                struct WhenNotSendingDataTests {
                    @Test("should not set the start date")
                    func testShouldNotSetStartDate() {
                        var spec = SenderTests()
                        spec.setUp()
                        defer { spec.tearDown() }

                        spec.sender.backgroundTimerEnabler = .none
                        #expect(spec.userDefaultsMock.double(forKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey) == 0.0)
                    }
                }

                @Suite("When sending data")
                struct WhenSendingDataTests {
                    @Test("should not set the start date")
                    func testShouldNotSetStartDate() async throws {
                        var spec = SenderTests()
                        spec.setUp()
                        defer { spec.tearDown() }

                        spec.sender.backgroundTimerEnabler = .none
                        try await TestingHelpers.awaitSenderUpload(session: spec.session) {
                            spec.sender.send(jsonObject: spec.payload)
                        }
                        SenderTests.expectUploadReachedMockSession(spec.session)
                        #expect(spec.userDefaultsMock.double(forKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey) == 0.0)
                    }
                }
            }

            @Suite("When the batching delay is set to 900.0")
            struct WhenBatchingDelayIsSetTo900Tests {
                @Suite("When not sending data")
                struct WhenNotSendingDataTests {
                    @Test("should not set the start date")
                    func testShouldNotSetStartDate() {
                        var spec = SenderTests()
                        spec.setUp()
                        defer { spec.tearDown() }

                        spec.sender.backgroundTimerEnabler = .none
                        spec.sender.setBatchingDelayBlock(900.0)
                        #expect(spec.userDefaultsMock.double(forKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey) == 0.0)
                    }
                }

                @Suite("When sending data")
                struct WhenSendingDataTests {
                    @Test("should not set the start date")
                    func testShouldNotSetStartDate() async throws {
                        var spec = SenderTests()
                        spec.setUp()
                        defer { spec.tearDown() }

                        spec.sender.backgroundTimerEnabler = .none
                        spec.sender.setBatchingDelayBlock(900.0)
                        spec.sender.send(jsonObject: spec.payload)

                        let getDBContent = { DatabaseTestUtils.fetchTableContents(spec.databaseTableName, connection: spec.databaseConnection) }
                        try await TestingHelpers.performAsyncTest(timeForExecution: 1.0, timeout: 2.0) {
                            #expect(getDBContent().count == 1)
                        }
                        #expect(spec.userDefaultsMock.double(forKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey) == 0.0)
                    }
                }
            }
        }

        @Suite("When setting enableBackgroundTimerUpdate to true")
        struct WhenSettingEnableBackgroundTimerUpdateToTrueTests {
            @Suite("When the batching delay is set to 0")
            struct WhenBatchingDelayIsSetToZeroTests {
                @Suite("When not sending data")
                struct WhenNotSendingDataTests {
                    @Test("should not set the start date")
                    func testShouldNotSetStartDate() {
                        var spec = SenderTests()
                        spec.setUp()
                        defer { spec.tearDown() }

                        spec.sender.backgroundTimerEnabler = .enabled(startTimeKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey)
                        spec.sender.setBatchingDelayBlock(0.0)
                        #expect(spec.userDefaultsMock.double(forKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey) == 0.0)
                    }
                }

                @Suite("When sending data")
                struct WhenSendingDataTests {
                    @Test("should not set the start date")
                    func testShouldNotSetStartDate() async throws {
                        var spec = SenderTests()
                        spec.setUp()
                        defer { spec.tearDown() }

                        spec.sender.backgroundTimerEnabler = .enabled(startTimeKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey)
                        spec.sender.setBatchingDelayBlock(0.0)
                        try await TestingHelpers.awaitSenderUpload(session: spec.session) {
                            spec.sender.send(jsonObject: spec.payload)
                        }
                        SenderTests.expectUploadReachedMockSession(spec.session)
                        try await TestingHelpers.eventually(timeout: 2.0) {
                            spec.userDefaultsMock.double(forKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey) != 0.0
                        }
                    }
                }
            }

            @Suite("When the batching delay is set to 900.0")
            struct WhenBatchingDelayIsSetTo900Tests {
                @Suite("When not sending data")
                struct WhenNotSendingDataTests {
                    @Test("should not set the start date")
                    func testShouldNotSetStartDate() {
                        var spec = SenderTests()
                        spec.setUp()
                        defer { spec.tearDown() }

                        spec.sender.backgroundTimerEnabler = .enabled(startTimeKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey)
                        spec.sender.setBatchingDelayBlock(900.0)
                        #expect(spec.userDefaultsMock.double(forKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey) == 0.0)
                    }
                }

                @Suite("When sending data")
                struct WhenSendingDataTests {
                    @Test("should set the schedule start date")
                    func testShouldSetScheduleStartDate() async throws {
                        var spec = SenderTests()
                        spec.setUp()
                        defer { spec.tearDown() }

                        spec.sender.backgroundTimerEnabler = .enabled(startTimeKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey)
                        spec.sender.setBatchingDelayBlock(900.0)
                        spec.sender.send(jsonObject: spec.payload)

                        let getDBContent = { DatabaseTestUtils.fetchTableContents(spec.databaseTableName, connection: spec.databaseConnection) }
                        try await TestingHelpers.performAsyncTest(timeForExecution: 1.0, timeout: 2.0) {
                            #expect(getDBContent().count == 1)
                        }

                        let starteDateTime = spec.userDefaultsMock.double(forKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey)

                        #expect(starteDateTime > 0.0)
                    }

                    @Suite("Then the app goes to foreground")
                    struct ThenAppGoesToForegroundTests {
                        @Test("should set an updated uploadTimerInterval")
                        func testShouldSetUpdatedUploadTimerInterval() async throws {
                            var spec = SenderTests()
                            spec.setUp()
                            defer { spec.tearDown() }

                            spec.sender.backgroundTimerEnabler = .enabled(startTimeKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey)
                            spec.sender.setBatchingDelayBlock(900.0)
                            spec.sender.send(jsonObject: spec.payload)

                            let getDBContent = { DatabaseTestUtils.fetchTableContents(spec.databaseTableName, connection: spec.databaseConnection) }
                            try await TestingHelpers.performAsyncTest(timeForExecution: 1.0, timeout: 2.0) {
                                #expect(getDBContent().count == 1)
                            }

                            let scheduleElapsedTime = spec.userDefaultsMock.double(forKey: EnableBackgroundTimerUpdateTests.geoScheduleStartTimeKey)

                            #expect(scheduleElapsedTime > 0.0)

                            sleep(3)

                            spec.sender.appDidBecomeActive()

                            let elapsedTime = Date().timeIntervalSince1970 - scheduleElapsedTime

                            #expect(ceil(spec.sender.uploadTimerInterval) <= ceil(900.0 - elapsedTime))
                        }
                    }
                }
            }
        }
    }

    @Suite("when setting batching delay")
    struct WhenSettingBatchingDelayTests {
        @Test("should succeed with default batching delay")
        func testShouldSucceedWithDefaultBatchingDelay() async throws {
            var spec = SenderTests()
            spec.setUp()
            defer { spec.tearDown() }

            try await TestingHelpers.awaitSenderUpload(session: spec.session) {
                spec.sender.send(jsonObject: spec.payload)
            }
            #expect(spec.sender.uploadTimerInterval == 0)
        }

        @Test("should succeed with custom batching delay")
        func testShouldSucceedWithCustomBatchingDelay() async throws {
            var spec = SenderTests()
            spec.setUp()
            defer { spec.tearDown() }

            spec.session.stubResponse(statusCode: 200)
            spec.sender.setBatchingDelayBlock(15.0)
            spec.sender.send(jsonObject: spec.payload)
            try await TestingHelpers.eventually(timeout: 2.0) {
                spec.sender.uploadTimerInterval == 15.0
            }
        }
    }

    @Suite("when sending events to RAT")
    struct WhenSendingEventsToRATTests {
        @Test("should send given payload")
        func testShouldSendGivenPayload() async throws {
            var spec = SenderTests()
            spec.setUp()
            defer { spec.tearDown() }

            try await TestingHelpers.awaitSenderUpload(session: spec.session) {
                spec.sender.send(jsonObject: spec.payload)
            }
            SenderTests.expectUploadReachedMockSession(spec.session)
        }

        @Suite("when manual initialization is enabled")
        struct WhenManualInitializationIsEnabledTests {
            @Test("should not send given payload if SDK not initialized")
            func testShouldNotSendPayloadIfSDKNotInitialized() async throws {
                var spec = SenderTests()
                spec.bundle.isManualInitializationEnabled = true
                AnalyticsManager.isConfigured = false
                spec.setUp()
                defer { spec.tearDown() }

                spec.sender.send(jsonObject: spec.payload)
                try await TestingHelpers.eventuallyAsync(timeout: 2.0) {
                    spec.session.urlRequest == nil && spec.fetchDatabaseContents().isEmpty
                }
            }

            @Test("should send given payload if SDK initialized")
            func testShouldSendPayloadIfSDKInitialized() async throws {
                var spec = SenderTests()
                spec.bundle.isManualInitializationEnabled = true
                spec.setUp()
                defer { spec.tearDown() }

                AnalyticsManager.configure()
                try await TestingHelpers.awaitSenderUpload(session: spec.session) {
                    spec.sender.send(jsonObject: spec.payload)
                }
                SenderTests.expectUploadReachedMockSession(spec.session)
            }
        }

        @Suite("When sending fails")
        struct WhenSendingFailsTests {
            static func verifyRAnalyticsUploadFailure(session: SwiftyURLSessionMock, sender: RAnalyticsSender, payload: [String: Any]) async throws {
                var didReceiveNotification = false
                let queue = OperationQueue()
                let observer = NotificationCenter.default.addObserver(forName: Notification.Name.rAnalyticsUploadFailure,
                                                                      object: nil,
                                                                      queue: queue) { (notification) in
                    let error = notification.userInfo?[NSUnderlyingErrorKey] as? Error
                    // Filter spurious notifications from other senders running concurrently.
                    guard error?.localizedDescription == "invalid_response" else { return }
                    #expect(error != nil)
                    didReceiveNotification = true
                }

                try await TestingHelpers.awaitSenderUpload(session: session, statusCode: 500) {
                    sender.send(jsonObject: payload)
                }
                SenderTests.expectUploadReachedMockSession(session)
                try await TestingHelpers.eventually(timeout: 2.0) {
                    didReceiveNotification == true
                }

                NotificationCenter.default.removeObserver(observer)
            }

            @Suite("When the batching delay is > 0")
            struct WhenBatchingDelayIsGreaterThanZeroTests {
                @Test("should send RAnalyticsUploadFailure notification")
                func testShouldSendRAnalyticsUploadFailureNotification() async throws {
                    var spec = SenderTests()
                    spec.setUp()
                    defer { spec.tearDown() }

                    spec.sender.setBatchingDelayBlock(0.1)
                    try await WhenSendingFailsTests.verifyRAnalyticsUploadFailure(
                        session: spec.session,
                        sender: spec.sender,
                        payload: spec.payload
                    )
                }
            }

            @Suite("When the batching delay is 0")
            struct WhenBatchingDelayIsZeroTests {
                @Test("should send RAnalyticsUploadFailure notification")
                func testShouldSendRAnalyticsUploadFailureNotification() async throws {
                    var spec = SenderTests()
                    spec.setUp()
                    defer { spec.tearDown() }

                    spec.sender.setBatchingDelayBlock(0)
                    try await WhenSendingFailsTests.verifyRAnalyticsUploadFailure(
                        session: spec.session,
                        sender: spec.sender,
                        payload: spec.payload
                    )
                }
            }
        }

        @Test("should remove DB record after event is sent")
        func testShouldRemoveDBRecordAfterEventIsSent() async throws {
            var spec = SenderTests()
            spec.setUp()
            defer { spec.tearDown() }

            try await TestingHelpers.awaitSenderUpload(session: spec.session) {
                spec.sender.send(jsonObject: spec.payload)
            }
            SenderTests.expectUploadReachedMockSession(spec.session)
            try await TestingHelpers.waitForSenderIdle(spec.sender, timeout: 2.0)
            #expect(spec.fetchDatabaseContents().isEmpty)
        }

        @Test("should not remove DB record before event is sent")
        func testShouldNotRemoveDBRecordBeforeEventIsSent() async throws {
            var spec = SenderTests()
            spec.setUp()
            defer { spec.tearDown() }

            spec.session.stubResponse(statusCode: 200)
            spec.sender.setBatchingDelayBlock(30.0)
            spec.sender.send(jsonObject: spec.payload)

            let getDBContent = { spec.fetchDatabaseContents() }
            try await TestingHelpers.performAsyncTest(timeForExecution: 1.0, timeout: 2.0) {
                #expect(getDBContent().count == 1)
            }
            #expect(spec.session.urlRequest == nil)
        }
    }

    @Suite("clearPendingEvents")
    struct ClearPendingEventsTests {
        @Test("should delete queued blobs and cancel upload scheduling")
        func deletesQueuedBlobsAndInvalidatesUploadTimer() async throws {
            var spec = SenderTests()
            spec.setUp()
            defer { spec.tearDown() }

            spec.session.stubResponse(statusCode: 200)
            spec.sender.setBatchingDelayBlock(30.0)
            spec.sender.send(jsonObject: spec.payload)

            try await TestingHelpers.performAsyncTest(timeForExecution: 1.0, timeout: 2.0) {
                #expect(DatabaseTestUtils.fetchTableContents(spec.databaseTableName, connection: spec.databaseConnection).count == 1)
            }

            try await withCheckedThrowingContinuation { continuation in
                spec.sender.clearPendingEvents {
                    continuation.resume()
                }
            }

            #expect(spec.sender.isUploadSchedulingIdle)
            let dbContent = DatabaseTestUtils.fetchTableContents(spec.databaseTableName, connection: spec.databaseConnection)
            #expect(dbContent.isEmpty)
        }
    }
}

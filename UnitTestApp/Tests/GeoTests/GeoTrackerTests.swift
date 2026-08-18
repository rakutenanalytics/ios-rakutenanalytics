// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable line_length

import Testing
import SQLite3
import Foundation
import UIKit
import CoreLocation
import SystemConfiguration
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

/// Deterministic reachability used in tests to avoid flakes from `NWPathMonitor` async updates.
final class ReachabilityStub: ReachabilityType {
    let connection: Reachability.Connection
    var flags: SCNetworkReachabilityFlags?
    
    init(flags: SCNetworkReachabilityFlags, connection: Reachability.Connection = .wifi) {
        self.flags = flags
        self.connection = connection
    }
    
    func addObserver(_ observer: ReachabilityObserver) { /* no-op */ }
    func removeObserver(_ observer: ReachabilityObserver) { /* no-op */ }
}

@Suite("GeoTracker")
struct GeoTrackerTests {
    static let databaseDirectory = FileManager.SearchPathDirectory.documentDirectory
    static let databaseName = "test_RAnalyticsSDKTracker.db"
    static let databaseTableName = "testTableName_SDKTrackerTests"
    
    let urlSession = SwiftyURLSessionMock()
    let bundle = BundleMock()
    var databaseConnection: SQlite3Pointer!
    var database: RAnalyticsDatabase!
    var databaseConfiguration: DatabaseConfiguration!
    let dependenciesContainer = GeoContainerMock()
    var geoTracker: GeoTracker?
    
    // Expected values for process tests
    let expectedLatitude = 37.421998333333335
    let expectedLongitude = 122.084
    let expectedAccuracy = 5.0
    let expectedSpeed = 10.0
    let expectedSpeedAccuracy = 10.0
    let expectedTms: TimeInterval = 1679054447.532
    let expectedAltitude = 5.0
    let expectedVerticalAccuracy = 20.0
    let expectedBearing = 22.0
    let expectedBearingAccuracy = 20.0
    let expectedResolution = "375x812"
    let expectedSessionIdentifier = "CA7A88AR-82FE-40C9-A836-B1B3455DECAF"
    let expectedCkp = "bd8ac43958a9e7fa0f097c0a0ba5c2979299e69d"
    let expectedCka = "E621E1F8-A36C-495B-93FC-0C247A3E6E5Q"
    let expectedActionParamType = "ButtonClick"
    let expectedActionParamLog = "In the Check screen"
    let expectedActionParamId = "abc123"
    let expectedActionParamDuration = "1 Second"
    let expectedActionParamAddLog = "Event on the Super Sale Campaign"
    let expectedUserIdentifier = "flo_test"
    let expectedEasyIdentifier = "123456"
    
    let nonEmptyActionParameters: GeoActionParameters
    let nilActionParameters: GeoActionParameters
    let pageVisitEvent: RAnalyticsEvent
    
    init() {
        nonEmptyActionParameters = GeoActionParameters(
            actionType: expectedActionParamType,
            actionLog: expectedActionParamLog,
            actionId: expectedActionParamId,
            actionDuration: expectedActionParamDuration,
            additionalLog: expectedActionParamAddLog)
        
        nilActionParameters = GeoActionParameters(
            actionType: nil,
            actionLog: nil,
            actionId: nil,
            actionDuration: nil,
            additionalLog: nil)
        
        pageVisitEvent = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
    }
    
    mutating func setUp() {
        urlSession.urlRequest = nil
        dependenciesContainer.session = urlSession
        dependenciesContainer.bundle = bundle
        dependenciesContainer.screenHandler = ScreenMock(bounds: CGRect(x: 0, y: 0, width: 375, height: 812))
        
        databaseConnection = RAnalyticsDatabase.mkAnalyticsDBConnection(
            databaseName: Self.databaseName,
            databaseParentDirectory: Self.databaseDirectory)
        database = RAnalyticsDatabase.database(connection: databaseConnection)
        databaseConfiguration = DatabaseConfiguration(database: database, tableName: Self.databaseTableName)
    }
    
    mutating func tearDown() {
        DatabaseTestUtils.deleteTableIfExists(databaseConfiguration.tableName, connection: databaseConnection)
        database.closeConnection()
        databaseConnection = nil
    }
    
    func createLocation(isAction: Bool = false,
                        actionParameters: GeoActionParameters? = nil) -> LocationModel {
        var location: CLLocation
        
        let coordinate = CLLocationCoordinate2D(latitude: expectedLatitude, longitude: expectedLongitude)
        location = CLLocation(
            coordinate: coordinate,
            altitude: expectedAltitude,
            horizontalAccuracy: expectedAccuracy,
            verticalAccuracy: expectedVerticalAccuracy,
            course: expectedBearing,
            courseAccuracy: expectedBearingAccuracy,
            speed: expectedSpeed,
            speedAccuracy: expectedSpeedAccuracy,
            timestamp: Date(timeIntervalSince1970: expectedTms))
        
        return LocationModel(location: location, isAction: isAction, actionParameters: actionParameters)
    }
    
    func createLocEvent() -> RAnalyticsEvent {
        RAnalyticsEvent(name: RAnalyticsEvent.Name.geoLocation, parameters: nil)
    }
    
    func createState() -> RAnalyticsState {
        let state = RAnalyticsState(sessionIdentifier: expectedSessionIdentifier, deviceIdentifier: expectedCkp)
        state.advertisingIdentifier = expectedCka
        state.userIdentifier = expectedUserIdentifier
        state.easyIdentifier = expectedEasyIdentifier
        return state
    }
    
    func verifyAutomaticFields(json: [String: Any], expectedLtm: String, expectedTs1: Double, expectedAccountIdentifier: Int64, expectedApplicationIdentifier: Int64, expectedLanguageCode: String) {
        #if SWIFT_PACKAGE
        let expectedAppName = "com.apple.dt.xctest.tool"
        #else
        let expectedAppName = "jp.co.rakuten.Host"
        #endif
        let expectedModel = UIDevice.current.modelIdentifier
        
        DispatchQueue.global(qos: .userInitiated).sync {
            #expect(json[PayloadParameterKeys.etype] as? String == RAnalyticsEvent.Name.geoLocation)
            #expect(json[PayloadParameterKeys.acc] as? Int64 == expectedAccountIdentifier)
            #expect(json[PayloadParameterKeys.aid] as? Int64 == expectedApplicationIdentifier)
            #expect((json[PayloadParameterKeys.Core.appVer] as? String)?.isEmpty == false)
            #expect(json[PayloadParameterKeys.Core.appName] as? String == expectedAppName)
            #expect(json[PayloadParameterKeys.Core.ts1] as? Double == expectedTs1)
            #expect(json[PayloadParameterKeys.Core.ver] as? String == CoreHelpers.Constants.sdkVersion)
            
            let mos = json[PayloadParameterKeys.Core.mos] as? String
            #expect(mos?.isEmpty == false)
            #expect(mos?.hasPrefix("iOS") == true)
            
            #expect(json[PayloadParameterKeys.Time.ltm] as? String == expectedLtm)
            #expect(json[PayloadParameterKeys.TimeZone.tzo] as? Int != nil)
            #expect(json[PayloadParameterKeys.Network.online] as? Bool == true)
            #expect(json[PayloadParameterKeys.Orientation.mori] as? Int == 1)
            #expect(json[PayloadParameterKeys.Telephony.mnetw] as? Int == 1)
            #expect(json[PayloadParameterKeys.Telephony.mnetwd] as? Int == 1)
            #expect(json[PayloadParameterKeys.Device.model] as? String == expectedModel)
            #expect(json[PayloadParameterKeys.Language.dln] as? String == expectedLanguageCode)
            #expect(json[PayloadParameterKeys.Device.res] as? String == expectedResolution)
            #expect(json[PayloadParameterKeys.UserAgent.ua] as? String == nil)
            #expect(json[PayloadParameterKeys.Identifier.ckp] as? String == expectedCkp)
            #expect(json[PayloadParameterKeys.Identifier.cka] as? String == expectedCka)
            #expect(json[PayloadParameterKeys.Identifier.cks] as? String == expectedSessionIdentifier)
            #expect(json[PayloadParameterKeys.Identifier.easyid] as? String == expectedEasyIdentifier)
        }
    }
    
    func verifyLocation(json: [String: Any]) {
        let location = json[PayloadParameterKeys.Location.loc] as? [String: Any]
        
        #expect(location != nil)
        #expect(location?[PayloadParameterKeys.Location.lat] as? CLLocationDegrees == expectedLatitude)
        #expect(location?[PayloadParameterKeys.Location.long] as? CLLocationDegrees == expectedLongitude)
        #expect(location?[PayloadParameterKeys.Location.accu] as? CLLocationAccuracy == expectedAccuracy)
        #expect(location?[PayloadParameterKeys.Location.tms] as? TimeInterval == expectedTms * 1000.0)
        #expect(location?[PayloadParameterKeys.Location.speed] as? CLLocationSpeed == expectedSpeed)
        #expect(location?[PayloadParameterKeys.Location.speedAccuracy] as? CLLocationSpeedAccuracy == expectedSpeedAccuracy)
        #expect(location?[PayloadParameterKeys.Location.altitude] as? CLLocationDistance == expectedAltitude)
        #expect(location?[PayloadParameterKeys.Location.verticalAccuracy] as? CLLocationAccuracy == expectedVerticalAccuracy)
        #expect(location?[PayloadParameterKeys.Location.bearing] as? CLLocationDegrees == expectedBearing)
        #expect(location?[PayloadParameterKeys.Location.bearingAccuracy] as? CLLocationAccuracy == expectedBearingAccuracy)
    }
    
    func verifyNonEmptyActionParameters(json: [String: Any]) {
        let actionParametersProperties = json[PayloadParameterKeys.ActionParameters.actionParams] as? [String: Any]
        
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.type] as? String == expectedActionParamType)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.log] as? String == expectedActionParamLog)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.identifier] as? String == expectedActionParamId)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.duration] as? String == expectedActionParamDuration)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.addLog] as? String == expectedActionParamAddLog)
    }
    
    // MARK: - Init Tests
    
    @Test("init should return nil when bundle has nil endpoint URL")
    mutating func testInitWithNilEndpointURL() {
        setUp()
        bundle.endpointAddress = nil
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, databaseConfiguration: databaseConfiguration)
        #expect(geoTracker == nil)
        tearDown()
    }
    
    @Test("init should return a new instance when bundle has non-nil endpoint URL")
    mutating func testInitWithNonNilEndpointURL() {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, databaseConfiguration: databaseConfiguration)
        #expect(geoTracker != nil)
        tearDown()
    }
    
    @Test("init should set expected endpoint URL")
    mutating func testInitSetsExpectedEndpointURL() {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, databaseConfiguration: databaseConfiguration)
        #expect(geoTracker?.endpointURL?.absoluteString == "https://endpoint.co.jp")
        tearDown()
    }
    
    // MARK: - Process Event Tests
    
    @Test("process should not process event when event is not loc")
    mutating func testProcessDoesNotProcessNonLocEvent() {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, databaseConfiguration: databaseConfiguration)
        let state = createState()
        #expect(geoTracker?.process(event: pageVisitEvent, state: state) == false)
        tearDown()
    }
    
    @Test("process should set nil httpBody when event is not loc")
    mutating func testProcessSetsNilHttpBodyForNonLocEvent() {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, databaseConfiguration: databaseConfiguration)
        let state = createState()
        _ = geoTracker?.process(event: pageVisitEvent, state: state)
        #expect(urlSession.urlRequest?.httpBody == nil)
        tearDown()
    }
    
    @Test("process should process event when event is loc")
    mutating func testProcessProcessesLocEvent() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, batchingDelay: 1.0, databaseConfiguration: databaseConfiguration)
        
        let state = createState()
        state.lastKnownLocation = createLocation()
        
        let urlSession = self.urlSession
        #expect(geoTracker?.process(event: createLocEvent(), state: state) == true)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        tearDown()
    }
    
    @Test("process should set non-nil httpBody when event is loc")
    mutating func testProcessSetsNonNilHttpBodyForLocEvent() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, batchingDelay: 1.0, databaseConfiguration: databaseConfiguration)
        
        let state = createState()
        state.lastKnownLocation = createLocation()
        
        let urlSession = self.urlSession
        _ = geoTracker?.process(event: createLocEvent(), state: state)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        #expect(urlSession.urlRequest?.httpBody != nil)
        tearDown()
    }
    
    @Test("process should send only one event")
    mutating func testProcessSendsOnlyOneEvent() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, batchingDelay: 1.0, databaseConfiguration: databaseConfiguration)
        
        let state = createState()
        state.lastKnownLocation = createLocation()
        
        let urlSession = self.urlSession
        _ = geoTracker?.process(event: createLocEvent(), state: state)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        
        let jsonArray = urlSession.urlRequest?.httpBody?.ratPayload
        #expect(jsonArray != nil)
        #expect(jsonArray?.count == 1)
        tearDown()
    }
    
    @Test("process should send expected RAT payload with nil action parameters when isAction is false")
    mutating func testProcessSendsExpectedPayloadWithNilActionParamsWhenIsActionFalse() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        let date = NSDate()
        let expectedLtm = date.toString
        let expectedTs1 = Swift.max(0, round(date.timeIntervalSince1970))
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, batchingDelay: 1.0, databaseConfiguration: databaseConfiguration)
        
        let state = createState()
        state.lastKnownLocation = createLocation()
        
        let urlSession = self.urlSession
        _ = geoTracker?.process(event: createLocEvent(), state: state)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        
        let json = urlSession.urlRequest?.httpBody?.ratPayload?.first
        #expect(json != nil)
        
        verifyAutomaticFields(
            json: json!,
            expectedLtm: expectedLtm,
            expectedTs1: expectedTs1,
            expectedAccountIdentifier: expectedAccountIdentifier,
            expectedApplicationIdentifier: expectedApplicationIdentifier,
            expectedLanguageCode: expectedLanguageCode)
        verifyLocation(json: json!)
        #expect(json?[PayloadParameterKeys.isAction] as? Bool == false)
        tearDown()
    }
    
    @Test("process should send expected RAT payload without action parameters properties when isAction is true")
    mutating func testProcessSendsExpectedPayloadWithoutActionParamsWhenIsActionTrue() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        let date = NSDate()
        let expectedLtm = date.toString
        let expectedTs1 = Swift.max(0, round(date.timeIntervalSince1970))
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer,
                                batchingDelay: 1.0,
                                databaseConfiguration: databaseConfiguration)
        
        let state = createState()
        state.lastKnownLocation = createLocation(isAction: true, actionParameters: GeoActionParameters())
        
        let urlSession = self.urlSession
        _ = geoTracker?.process(event: createLocEvent(), state: state)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        
        let json = urlSession.urlRequest?.httpBody?.ratPayload?.first
        #expect(json != nil)
        
        verifyAutomaticFields(json: json!, expectedLtm: expectedLtm, expectedTs1: expectedTs1, expectedAccountIdentifier: expectedAccountIdentifier, expectedApplicationIdentifier: expectedApplicationIdentifier, expectedLanguageCode: expectedLanguageCode)
        verifyLocation(json: json!)
        #expect(json?[PayloadParameterKeys.isAction] as? Bool == true)
        #expect(json?[PayloadParameterKeys.ActionParameters.actionParams] == nil)
        tearDown()
    }
    
    @Test("process should send expected RAT payload with nil action parameters properties when isAction is false and nil action parameters")
    mutating func testProcessSendsExpectedPayloadWithNilActionParamsPropertiesWhenIsActionFalse() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        let date = NSDate()
        let expectedLtm = date.toString
        let expectedTs1 = Swift.max(0, round(date.timeIntervalSince1970))
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, batchingDelay: 1.0, databaseConfiguration: databaseConfiguration)
        
        let state = createState()
        state.lastKnownLocation = createLocation(isAction: false, actionParameters: nilActionParameters)
        
        let urlSession = self.urlSession
        _ = geoTracker?.process(event: createLocEvent(), state: state)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        
        let json = urlSession.urlRequest?.httpBody?.ratPayload?.first
        #expect(json != nil)
        
        verifyAutomaticFields(json: json!, expectedLtm: expectedLtm, expectedTs1: expectedTs1, expectedAccountIdentifier: expectedAccountIdentifier, expectedApplicationIdentifier: expectedApplicationIdentifier, expectedLanguageCode: expectedLanguageCode)
        verifyLocation(json: json!)
        #expect(json?[PayloadParameterKeys.isAction] as? Bool == false)
        tearDown()
    }
    
    @Test("process should send expected RAT payload with nil action parameters properties when isAction is true and nil action parameters")
    mutating func testProcessSendsExpectedPayloadWithNilActionParamsPropertiesWhenIsActionTrue() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        let date = NSDate()
        let expectedLtm = date.toString
        let expectedTs1 = Swift.max(0, round(date.timeIntervalSince1970))
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, batchingDelay: 1.0, databaseConfiguration: databaseConfiguration)
        
        let state = createState()
        state.lastKnownLocation = createLocation(isAction: true, actionParameters: nilActionParameters)
        
        let urlSession = self.urlSession
        _ = geoTracker?.process(event: createLocEvent(), state: state)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        
        let json = urlSession.urlRequest?.httpBody?.ratPayload?.first
        #expect(json != nil)
        
        verifyAutomaticFields(json: json!, expectedLtm: expectedLtm, expectedTs1: expectedTs1, expectedAccountIdentifier: expectedAccountIdentifier, expectedApplicationIdentifier: expectedApplicationIdentifier, expectedLanguageCode: expectedLanguageCode)
        verifyLocation(json: json!)
        #expect(json?[PayloadParameterKeys.isAction] as? Bool == true)
        #expect(json?[PayloadParameterKeys.ActionParameters.actionParams] == nil)
        tearDown()
    }
    
    @Test("process should send expected RAT payload with nil action parameters when isAction is false and action parameters present")
    mutating func testProcessSendsExpectedPayloadWithNilActionParamsWhenIsActionFalseAndActionParamsPresent() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        let date = NSDate()
        let expectedLtm = date.toString
        let expectedTs1 = Swift.max(0, round(date.timeIntervalSince1970))
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, batchingDelay: 1.0, databaseConfiguration: databaseConfiguration)
        
        let state = createState()
        state.lastKnownLocation = createLocation(isAction: false, actionParameters: nonEmptyActionParameters)
        
        let urlSession = self.urlSession
        _ = geoTracker?.process(event: createLocEvent(), state: state)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        
        let json = urlSession.urlRequest?.httpBody?.ratPayload?.first
        #expect(json != nil)
        
        verifyAutomaticFields(json: json!, expectedLtm: expectedLtm, expectedTs1: expectedTs1, expectedAccountIdentifier: expectedAccountIdentifier, expectedApplicationIdentifier: expectedApplicationIdentifier, expectedLanguageCode: expectedLanguageCode)
        verifyLocation(json: json!)
        #expect(json?[PayloadParameterKeys.isAction] as? Bool == false)
        #expect(json?[PayloadParameterKeys.ActionParameters.actionParams] == nil)
        tearDown()
    }
    
    @Test("process should send expected RAT payload with expected action parameters when all are present")
    mutating func testProcessSendsExpectedPayloadWithAllActionParameters() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        let date = NSDate()
        let expectedLtm = date.toString
        let expectedTs1 = Swift.max(0, round(date.timeIntervalSince1970))
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, batchingDelay: 1.0, databaseConfiguration: databaseConfiguration)
        
        let state = createState()
        state.lastKnownLocation = createLocation(isAction: true, actionParameters: nonEmptyActionParameters)
        
        let urlSession = self.urlSession
        _ = geoTracker?.process(event: createLocEvent(), state: state)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        
        let json = urlSession.urlRequest?.httpBody?.ratPayload?.first
        #expect(json != nil)
        
        verifyAutomaticFields(json: json!, expectedLtm: expectedLtm, expectedTs1: expectedTs1, expectedAccountIdentifier: expectedAccountIdentifier, expectedApplicationIdentifier: expectedApplicationIdentifier, expectedLanguageCode: expectedLanguageCode)
        verifyLocation(json: json!)
        #expect(json?[PayloadParameterKeys.isAction] as? Bool == true)
        verifyNonEmptyActionParameters(json: json!)
        tearDown()
    }
    
    @Test("process should send expected RAT payload with only action type")
    mutating func testProcessSendsExpectedPayloadWithOnlyActionType() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        let date = NSDate()
        let expectedLtm = date.toString
        let expectedTs1 = Swift.max(0, round(date.timeIntervalSince1970))
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, batchingDelay: 1.0, databaseConfiguration: databaseConfiguration)
        
        let sentActionParameters = GeoActionParameters(
            actionType: expectedActionParamType,
            actionLog: nil,
            actionId: nil,
            actionDuration: nil,
            additionalLog: nil)
        
        let state = createState()
        state.lastKnownLocation = createLocation(isAction: true, actionParameters: sentActionParameters)
        
        let urlSession = self.urlSession
        _ = geoTracker?.process(event: createLocEvent(), state: state)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        
        let json = urlSession.urlRequest?.httpBody?.ratPayload?.first
        #expect(json != nil)
        
        verifyAutomaticFields(json: json!, expectedLtm: expectedLtm, expectedTs1: expectedTs1, expectedAccountIdentifier: expectedAccountIdentifier, expectedApplicationIdentifier: expectedApplicationIdentifier, expectedLanguageCode: expectedLanguageCode)
        verifyLocation(json: json!)
        
        let actionParametersProperties = json?[PayloadParameterKeys.ActionParameters.actionParams] as? [String: Any]
        #expect(json?[PayloadParameterKeys.isAction] as? Bool == true)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.type] as? String == expectedActionParamType)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.log] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.identifier] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.duration] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.addLog] as? String == nil)
        tearDown()
    }
    
    @Test("process should send expected RAT payload with only action log")
    mutating func testProcessSendsExpectedPayloadWithOnlyActionLog() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        let date = NSDate()
        let expectedLtm = date.toString
        let expectedTs1 = Swift.max(0, round(date.timeIntervalSince1970))
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, batchingDelay: 1.0, databaseConfiguration: databaseConfiguration)
        
        let sentActionParameters = GeoActionParameters(
            actionType: nil,
            actionLog: expectedActionParamLog,
            actionId: nil,
            actionDuration: nil,
            additionalLog: nil)
        
        let state = createState()
        state.lastKnownLocation = createLocation(isAction: true, actionParameters: sentActionParameters)
        
        let urlSession = self.urlSession
        _ = geoTracker?.process(event: createLocEvent(), state: state)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        
        let json = urlSession.urlRequest?.httpBody?.ratPayload?.first
        #expect(json != nil)
        
        verifyAutomaticFields(json: json!, expectedLtm: expectedLtm, expectedTs1: expectedTs1, expectedAccountIdentifier: expectedAccountIdentifier, expectedApplicationIdentifier: expectedApplicationIdentifier, expectedLanguageCode: expectedLanguageCode)
        verifyLocation(json: json!)
        
        let actionParametersProperties = json?[PayloadParameterKeys.ActionParameters.actionParams] as? [String: Any]
        #expect(json?[PayloadParameterKeys.isAction] as? Bool == true)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.type] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.log] as? String == expectedActionParamLog)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.identifier] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.duration] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.addLog] as? String == nil)
        tearDown()
    }
    
    @Test("process should send expected RAT payload with only action id")
    mutating func testProcessSendsExpectedPayloadWithOnlyActionId() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        let date = NSDate()
        let expectedLtm = date.toString
        let expectedTs1 = Swift.max(0, round(date.timeIntervalSince1970))
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, batchingDelay: 1.0, databaseConfiguration: databaseConfiguration)
        
        let sentActionParameters = GeoActionParameters(
            actionType: nil,
            actionLog: nil,
            actionId: expectedActionParamId,
            actionDuration: nil,
            additionalLog: nil)
        
        let state = createState()
        state.lastKnownLocation = createLocation(isAction: true, actionParameters: sentActionParameters)
        
        let urlSession = self.urlSession
        _ = geoTracker?.process(event: createLocEvent(), state: state)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        
        let json = urlSession.urlRequest?.httpBody?.ratPayload?.first
        #expect(json != nil)
        
        verifyAutomaticFields(json: json!, expectedLtm: expectedLtm, expectedTs1: expectedTs1, expectedAccountIdentifier: expectedAccountIdentifier, expectedApplicationIdentifier: expectedApplicationIdentifier, expectedLanguageCode: expectedLanguageCode)
        verifyLocation(json: json!)
        
        let actionParametersProperties = json?[PayloadParameterKeys.ActionParameters.actionParams] as? [String: Any]
        #expect(json?[PayloadParameterKeys.isAction] as? Bool == true)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.type] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.log] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.identifier] as? String == expectedActionParamId)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.duration] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.addLog] as? String == nil)
        tearDown()
    }
    
    @Test("process should send expected RAT payload with only action duration")
    mutating func testProcessSendsExpectedPayloadWithOnlyActionDuration() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        let date = NSDate()
        let expectedLtm = date.toString
        let expectedTs1 = Swift.max(0, round(date.timeIntervalSince1970))
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, batchingDelay: 1.0, databaseConfiguration: databaseConfiguration)
        
        let sentActionParameters = GeoActionParameters(
            actionType: nil,
            actionLog: nil,
            actionId: nil,
            actionDuration: expectedActionParamDuration,
            additionalLog: nil)
        
        let state = createState()
        state.lastKnownLocation = createLocation(isAction: true, actionParameters: sentActionParameters)
        
        let urlSession = self.urlSession
        _ = geoTracker?.process(event: createLocEvent(), state: state)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        
        let json = urlSession.urlRequest?.httpBody?.ratPayload?.first
        #expect(json != nil)
        
        verifyAutomaticFields(json: json!, expectedLtm: expectedLtm, expectedTs1: expectedTs1, expectedAccountIdentifier: expectedAccountIdentifier, expectedApplicationIdentifier: expectedApplicationIdentifier, expectedLanguageCode: expectedLanguageCode)
        verifyLocation(json: json!)
        
        let actionParametersProperties = json?[PayloadParameterKeys.ActionParameters.actionParams] as? [String: Any]
        #expect(json?[PayloadParameterKeys.isAction] as? Bool == true)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.type] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.log] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.identifier] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.duration] as? String == expectedActionParamDuration)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.addLog] as? String == nil)
        tearDown()
    }
    
    @Test("process should send expected RAT payload with only action add log")
    mutating func testProcessSendsExpectedPayloadWithOnlyActionAddLog() async throws {
        setUp()
        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
        dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
            bundle: bundle,
            deviceCapability: dependenciesContainer.deviceCapability,
            screenHandler: dependenciesContainer.screenHandler,
            telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
            notificationHandler: dependenciesContainer.notificationHandler,
            analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
            reachability: ReachabilityStub(flags: [.reachable]),
            userStorageHandler: dependenciesContainer.userStorageHandler)
        
        let expectedAccountIdentifier: Int64 = 123
        let expectedApplicationIdentifier: Int64 = 456
        let expectedLanguageCode = "en"
        bundle.accountIdentifier = expectedAccountIdentifier
        bundle.applicationIdentifier = expectedApplicationIdentifier
        bundle.languageCode = expectedLanguageCode
        
        let date = NSDate()
        let expectedLtm = date.toString
        let expectedTs1 = Swift.max(0, round(date.timeIntervalSince1970))
        
        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer, batchingDelay: 1.0, databaseConfiguration: databaseConfiguration)
        
        let sentActionParameters = GeoActionParameters(
            actionType: nil,
            actionLog: nil,
            actionId: nil,
            actionDuration: nil,
            additionalLog: expectedActionParamAddLog)
        
        let state = createState()
        state.lastKnownLocation = createLocation(isAction: true, actionParameters: sentActionParameters)
        
        let urlSession = self.urlSession
        _ = geoTracker?.process(event: createLocEvent(), state: state)
        try await TestingHelpers.eventually(timeout: 2.0) { urlSession.urlRequest != nil }
        
        let json = urlSession.urlRequest?.httpBody?.ratPayload?.first
        #expect(json != nil)
        
        verifyAutomaticFields(json: json!, expectedLtm: expectedLtm, expectedTs1: expectedTs1, expectedAccountIdentifier: expectedAccountIdentifier, expectedApplicationIdentifier: expectedApplicationIdentifier, expectedLanguageCode: expectedLanguageCode)
        verifyLocation(json: json!)
        
        let actionParametersProperties = json?[PayloadParameterKeys.ActionParameters.actionParams] as? [String: Any]
        #expect(json?[PayloadParameterKeys.isAction] as? Bool == true)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.type] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.log] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.identifier] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.duration] as? String == nil)
        #expect(actionParametersProperties?[PayloadParameterKeys.ActionParameters.addLog] as? String == expectedActionParamAddLog)
        tearDown()
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
// swiftlint:enable line_length

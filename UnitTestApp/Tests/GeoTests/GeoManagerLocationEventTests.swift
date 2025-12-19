import Testing
import Foundation
import CoreLocation
import UIKit.UIDevice
@testable import RakutenAnalytics

#if SWIFT_PACKAGE
import RAnalyticsTestHelpers
#endif

@Suite("GeoManager Location Event Processing")
struct GeoManagerLocationEventTests {
    static let coreLocationManager = CLLocationManager()
    static let dependenciesContainer = GeoDependenciesContainer()
    static let configurationStore = GeoConfigurationStore(userStorageHandler: dependenciesContainer.userStorageHandler)
    
    static let geoLocationManager = GeoLocationManager(
        bundle: BundleMock(),
        coreLocationManager: LocationManagerMock(),
        configurationStore: configurationStore)
    
    // MARK: - Basic Initialization Tests
    
    @Test("should not be nil on accessing shared instance")
    func testSharedInstance() {
        let _ = GeoManager.shared
    }
    
    @Test("should not be nil on creating a new instance")
    @MainActor
    func testNewInstance() {
        let manager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        let _ = manager
    }
    
    @Test("should call locationManager's requestLocation()")
    @MainActor
    func testRequestLocation() async throws {
        let locationManagerMock = GeoLocationManagerMock()
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: locationManagerMock,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer()))
        
        geoManager.requestLocation { _ in }
        
        try await TestingHelpers.eventuallyOnMain { locationManagerMock.requestLocationUserActionIsCalled }
        #expect(locationManagerMock.requestLocationUserActionIsCalled == true)
    }
    
    @Test("should call CLLocationManager's requestLocation()")
    @MainActor
    func testRequestLocationCallsCLLocationManager() async throws {
        let analyticsDependenciesContainer = SimpleContainerMock()
        let dependenciesContainer = SimpleContainerMock()
        let coreLocationManagerMock = LocationManagerMock()
        
        let geoLocationManager = GeoLocationManager(
            bundle: BundleMock(),
            coreLocationManager: coreLocationManagerMock,
            configurationStore: GeoManagerLocationEventTests.configurationStore)
        
        let geoManager = GeoManager(
            userStorageHandler: dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManager,
            device: UIDevice.current,
            tracker: TrackerMock(),
            analyticsManager: AnalyticsManager(dependenciesContainer: analyticsDependenciesContainer))
        
        geoManager.requestLocation { _ in }
        
        try await TestingHelpers.eventuallyOnMain { coreLocationManagerMock.requestLocationIsCalled }
        #expect(coreLocationManagerMock.requestLocationIsCalled == true)
    }
    
    // MARK: - Location Success Tests
    
    @Test("should process the location event with an expected name when action parameters are nil")
    @MainActor
    func testLocationEventNameWithNilActionParameters() async throws {
        let (result, trackerMock) = try await setupLocationTest(actionParameters: nil)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.event?.name == RAnalyticsEvent.Name.geoLocation)
    }
    
    @Test("should process the location event with empty parameters when action parameters are nil")
    @MainActor
    func testLocationEventEmptyParametersWithNilActionParameters() async throws {
        let (result, trackerMock) = try await setupLocationTest(actionParameters: nil)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.event?.parameters.isEmpty == true)
    }
    
    @Test("should process the location event with a non-empty cks when action parameters are nil")
    @MainActor
    func testLocationEventCksWithNilActionParameters() async throws {
        let (result, trackerMock) = try await setupLocationTest(actionParameters: nil)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.sessionIdentifier.isEmpty == false)
    }
    
    @Test("should process the location event with a non-empty ckp when action parameters are nil")
    @MainActor
    func testLocationEventCkpWithNilActionParameters() async throws {
        let (result, trackerMock) = try await setupLocationTest(actionParameters: nil)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.deviceIdentifier.isEmpty == false)
    }
    
    @Test("should process the location event with a non-empty userid when action parameters are nil")
    @MainActor
    func testLocationEventUseridWithNilActionParameters() async throws {
        let (result, trackerMock) = try await setupLocationTest(actionParameters: nil)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.userIdentifier == "flo_test")
    }
    
    @Test("should process the location event with a non-empty easyid when action parameters are nil")
    @MainActor
    func testLocationEventEasyidWithNilActionParameters() async throws {
        let (result, trackerMock) = try await setupLocationTest(actionParameters: nil)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.easyIdentifier == "123456")
    }
    
    @Test("should process the location event with a non-empty cka when action parameters are nil")
    @MainActor
    func testLocationEventCkaWithNilActionParameters() async throws {
        let (result, trackerMock) = try await setupLocationTest(actionParameters: nil)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.advertisingIdentifier == "E621E1F8-A36C-495B-93FC-0C247A3E6E5Q")
    }
    
    @Test("should return an expected location when action parameters are nil")
    @MainActor
    func testReturnExpectedLocationWithNilActionParameters() async throws {
        let location = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
        let expectedLocationModel = LocationModel(
            location: location,
            isAction: true,
            actionParameters: nil)
        let (result, _) = try await setupLocationTest(actionParameters: nil, location: location)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        
        var returnedLocationModel: LocationModel?
        if case .success(let locationModel) = result! {
            returnedLocationModel = locationModel
        }
        
        #expect(returnedLocationModel == expectedLocationModel)
    }
    
    @Test("should process the location event with an expected location model when action parameters are nil")
    @MainActor
    func testLocationEventLocationModelWithNilActionParameters() async throws {
        let location = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
        let expectedLocationModel = LocationModel(
            location: location,
            isAction: true,
            actionParameters: nil)
        let (result, trackerMock) = try await setupLocationTest(actionParameters: nil, location: location)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.lastKnownLocation == expectedLocationModel)
    }
    
    @Test("should process the location event with nil action parameters")
    @MainActor
    func testLocationEventNilActionParameters() async throws {
        let (result, trackerMock) = try await setupLocationTest(actionParameters: nil)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.lastKnownLocation?.actionParameters == nil)
    }
    
    // MARK: - Location Success Tests with Action Parameters
    
    @Test("should process the location event with an expected name when action parameters are not nil")
    @MainActor
    func testLocationEventNameWithActionParameters() async throws {
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        let (result, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.event?.name == RAnalyticsEvent.Name.geoLocation)
    }
    
    @Test("should process the location event with empty parameters when action parameters are not nil")
    @MainActor
    func testLocationEventEmptyParametersWithActionParameters() async throws {
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        let (result, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.event?.parameters.isEmpty == true)
    }
    
    @Test("should process the location event with a non-empty cks when action parameters are not nil")
    @MainActor
    func testLocationEventCksWithActionParameters() async throws {
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        let (result, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.sessionIdentifier.isEmpty == false)
    }
    
    @Test("should process the location event with a non-empty ckp when action parameters are not nil")
    @MainActor
    func testLocationEventCkpWithActionParameters() async throws {
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        let (result, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.deviceIdentifier.isEmpty == false)
    }
    
    @Test("should process the location event with a non-empty userid when action parameters are not nil")
    @MainActor
    func testLocationEventUseridWithActionParameters() async throws {
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        let (result, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.userIdentifier == "flo_test")
    }
    
    @Test("should process the location event with a non-empty easyid when action parameters are not nil")
    @MainActor
    func testLocationEventEasyidWithActionParameters() async throws {
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        let (result, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.easyIdentifier == "123456")
    }
    
    @Test("should process the location event with a non-empty cka when action parameters are not nil")
    @MainActor
    func testLocationEventCkaWithActionParameters() async throws {
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        let (result, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.advertisingIdentifier == "E621E1F8-A36C-495B-93FC-0C247A3E6E5Q")
    }
    
    @Test("should return an expected location when action parameters are not nil")
    @MainActor
    func testReturnExpectedLocationWithActionParameters() async throws {
        let location = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        
        let expectedLocationModel = LocationModel(
            location: location,
            isAction: true,
            actionParameters: actionParameters)
        
        let (result, _) = try await setupLocationTest(actionParameters: actionParameters, location: location)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        
        var returnedLocationModel: LocationModel?
        if case .success(let locationModel) = result! {
            returnedLocationModel = locationModel
        }
        
        #expect(returnedLocationModel == expectedLocationModel)
    }
    
    @Test("should process the location event with an expected location model when action parameters are not nil")
    @MainActor
    func testLocationEventLocationModelWithActionParameters() async throws {
        let location = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        let expectedLocationModel = LocationModel(
            location: location,
            isAction: true,
            actionParameters: actionParameters)
        
        let (result, trackerMock) = try await setupLocationTest(actionParameters: actionParameters, location: location)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.lastKnownLocation == expectedLocationModel)
    }
    
    @Test("should process the location event with an action type")
    @MainActor
    func testLocationEventActionType() async throws {
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        let (result, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.lastKnownLocation?.actionParameters?.actionType == "test-actionType")
    }
    
    @Test("should process the location event with an action log")
    @MainActor
    func testLocationEventActionLog() async throws {
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        let (result, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.lastKnownLocation?.actionParameters?.actionLog == "test-actionLog")
    }
    
    @Test("should process the location event with an action id")
    @MainActor
    func testLocationEventActionId() async throws {
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        let (result, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.lastKnownLocation?.actionParameters?.actionId == "test-actionId")
    }
    
    @Test("should process the location event with an action duration")
    @MainActor
    func testLocationEventActionDuration() async throws {
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        let (result, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.lastKnownLocation?.actionParameters?.actionDuration == "test-actionDuration")
    }
    
    @Test("should process the location event with an additional log")
    @MainActor
    func testLocationEventAdditionalLog() async throws {
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        let (result, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.state?.lastKnownLocation?.actionParameters?.additionalLog == "test-additionalLog")
    }
    
    // MARK: - Error Tests
    
    @Test("should return an error when core location manager returns an error")
    @MainActor
    func testReturnError() async throws {
        let expectedError = NSError(domain: "", code: 0, userInfo: nil)
        let (result, _) = try await setupErrorTest(expectedError: expectedError)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        
        var returnedError: NSError?
        if case .failure(let error) = result! {
            returnedError = error as NSError
        }
        
        #expect(returnedError == expectedError)
    }
    
    @Test("should not process the location event when core location manager returns an error")
    @MainActor
    func testNoLocationEventOnError() async throws {
        let expectedError = NSError(domain: "", code: 0, userInfo: nil)
        let (result, trackerMock) = try await setupErrorTest(expectedError: expectedError)
        
        try await TestingHelpers.eventuallyOnMain { result != nil }
        #expect(result != nil)
        #expect(trackerMock.event == nil)
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func setupLocationTest(actionParameters: GeoActionParameters?, location: CLLocation? = nil) async throws -> (GeoRequestLocationResult?, TrackerMock) {
        let analyticsDependenciesContainer = SimpleContainerMock()
        let dependenciesContainer = SimpleContainerMock()
        let testLocation = location ?? CLLocation(latitude: -56.6462520, longitude: -36.6462520)
        let trackerMock = TrackerMock()
        let coreLocationManagerMock = LocationManagerMock()
        let geoLocationManager = GeoLocationManager(
            bundle: BundleMock(),
            coreLocationManager: coreLocationManagerMock,
            configurationStore: GeoManagerLocationEventTests.configurationStore)
        let asIdentifierManagerMock = ASIdentifierManagerMock()
        asIdentifierManagerMock.advertisingIdentifierUUIDString = "E621E1F8-A36C-495B-93FC-0C247A3E6E5Q"
        let userDefaultsMock = UserDefaultsMock([:])
        userDefaultsMock.set(value: "flo_test", forKey: RAnalyticsExternalCollector.Constants.trackingIdentifierKey)
        let keychainHandlerMock = KeychainHandlerMock()
        keychainHandlerMock.set(value: "123456", for: RAnalyticsExternalCollector.Constants.easyIdentifierKey)
        
        analyticsDependenciesContainer.adIdentifierManager = asIdentifierManagerMock
        analyticsDependenciesContainer.userStorageHandler = userDefaultsMock
        analyticsDependenciesContainer.keychainHandler = keychainHandlerMock
        
        let geoManager = GeoManager(
            userStorageHandler: dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManager,
            device: UIDevice.current,
            tracker: trackerMock,
            analyticsManager: AnalyticsManager(dependenciesContainer: analyticsDependenciesContainer))
        
        var result: GeoRequestLocationResult?
        geoManager.requestLocation(actionParameters: actionParameters) { aResult in
            result = aResult
        }
        
        coreLocationManagerMock.delegate?.locationManager?(GeoManagerLocationEventTests.coreLocationManager, didUpdateLocations: [testLocation])
        
        return (result, trackerMock)
    }
    
    @MainActor
    private func setupErrorTest(expectedError: NSError) async throws -> (GeoRequestLocationResult?, TrackerMock) {
        let analyticsDependenciesContainer = SimpleContainerMock()
        let dependenciesContainer = SimpleContainerMock()
        let trackerMock = TrackerMock()
        let coreLocationManagerMock = LocationManagerMock()
        let geoLocationManager = GeoLocationManager(
            bundle: BundleMock(),
            coreLocationManager: coreLocationManagerMock,
            configurationStore: GeoManagerLocationEventTests.configurationStore)
        
        let geoManager = GeoManager(
            userStorageHandler: dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManager,
            device: UIDevice.current,
            tracker: trackerMock,
            analyticsManager: AnalyticsManager(dependenciesContainer: analyticsDependenciesContainer))
        
        var result: GeoRequestLocationResult?
        geoManager.requestLocation { aResult in
            result = aResult
        }
        
        coreLocationManagerMock.delegate?.locationManager?(GeoManagerLocationEventTests.coreLocationManager, didFailWithError: expectedError)
        
        return (result, trackerMock)
    }
}

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
        let analyticsManager = AnalyticsManager.shared()
        analyticsManager.add(TrackerMock())
        let manager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: Self.geoLocationManager,
            device: UIDevice.current,
            analyticsManager: analyticsManager)
        let _ = manager
    }

    @Test("should return location from requestLocation()")
    @MainActor
    func testRequestLocation() async throws {
        let locationManagerMock = GeoLocationManagerMock()
        let testLocation = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
        let expectedLocationModel = LocationModel(location: testLocation, isAction: true, actionParameters: nil)
        locationManagerMock.respondWithLocationOnUserActionRequest = testLocation
        let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
        analyticsManager.add(TrackerMock())
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: locationManagerMock,
            device: UIDevice.current,
            analyticsManager: analyticsManager)

        let locationModel = try await geoManager.requestLocation()
        #expect(locationModel == expectedLocationModel)
    }

    @Test("should return location from requestLocation() via CLLocationManager")
    @MainActor
    func testRequestLocationCallsCLLocationManager() async throws {
        let analyticsDependenciesContainer = SimpleContainerMock()
        let dependenciesContainer = SimpleContainerMock()
        let coreLocationManagerMock = LocationManagerMock()
        let testLocation = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
        let expectedLocationModel = LocationModel(location: testLocation, isAction: true, actionParameters: nil)
        coreLocationManagerMock.respondWithLocationOnRequest = testLocation
        coreLocationManagerMock.locationManagerForDelegateCallbacks = GeoManagerLocationEventTests.coreLocationManager

        let geoLocationManager = GeoLocationManager(
            bundle: BundleMock(),
            coreLocationManager: coreLocationManagerMock,
            configurationStore: GeoManagerLocationEventTests.configurationStore)

        let analyticsManager = AnalyticsManager(dependenciesContainer: analyticsDependenciesContainer)
        analyticsManager.add(TrackerMock())
        let geoManager = GeoManager(
            userStorageHandler: dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManager,
            device: UIDevice.current,
            analyticsManager: analyticsManager)

        let locationModel = try await geoManager.requestLocation()
        #expect(locationModel == expectedLocationModel)
    }

    @Suite("when location consent is disabled")
    struct WhenLocationConsentDisabledTests {
        @Test("requestLocation should throw without tracking when location consent is disabled")
        @MainActor
        func testRequestLocationThrowsWhenLocationDisabled() async throws {
            let consentMock = DataCollectionConsentStoreMock()
            consentMock.isPrivacyControlEnabled = true
            consentMock.enabledTypes = [.mobileNetwork, .deviceInformation]

            let analyticsDependenciesContainer = SimpleContainerMock()
            let dependenciesContainer = SimpleContainerMock()
            let trackerMock = TrackerMock()
            let coreLocationManagerMock = LocationManagerMock()
            let geoLocationManager = GeoLocationManager(
                bundle: BundleMock(),
                coreLocationManager: coreLocationManagerMock,
                configurationStore: GeoManagerLocationEventTests.configurationStore)

            let analyticsManager = AnalyticsManager(dependenciesContainer: analyticsDependenciesContainer)
            analyticsManager.add(trackerMock)

            let geoManager = GeoManager(
                userStorageHandler: dependenciesContainer.userStorageHandler,
                geoLocationManager: geoLocationManager,
                device: UIDevice.current,
                analyticsManager: analyticsManager,
                consentStore: consentMock)

            let testLocation = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
            coreLocationManagerMock.respondWithLocationOnRequest = testLocation
            coreLocationManagerMock.locationManagerForDelegateCallbacks = GeoManagerLocationEventTests.coreLocationManager

            do {
                _ = try await geoManager.requestLocation()
                Issue.record("Expected requestLocation to throw when location consent is disabled")
            } catch {
                #expect((error as NSError).localizedDescription == "Location data collection is disabled.")
            }
            #expect(trackerMock.event == nil)
        }
    }

    // MARK: - Location Success Tests

    @Test("should process the location event with an expected name when action parameters are nil")
    @MainActor
    func testLocationEventNameWithNilActionParameters() async throws {
        let (_, trackerMock) = try await setupLocationTest(actionParameters: nil)
        #expect(trackerMock.event?.name == RAnalyticsEvent.Name.geoLocation)
    }

    @Test("should process the location event with empty parameters when action parameters are nil")
    @MainActor
    func testLocationEventEmptyParametersWithNilActionParameters() async throws {
        let (_, trackerMock) = try await setupLocationTest(actionParameters: nil)
        #expect(trackerMock.event?.parameters.isEmpty == true)
    }

    @Test("should process the location event with a non-empty cks when action parameters are nil")
    @MainActor
    func testLocationEventCksWithNilActionParameters() async throws {
        let (_, trackerMock) = try await setupLocationTest(actionParameters: nil)
        #expect(trackerMock.state?.sessionIdentifier.isEmpty == false)
    }

    @Test("should process the location event with a non-empty ckp when action parameters are nil")
    @MainActor
    func testLocationEventCkpWithNilActionParameters() async throws {
        let (_, trackerMock) = try await setupLocationTest(actionParameters: nil)
        #expect(trackerMock.state?.deviceIdentifier.isEmpty == false)
    }

    @Test("should process the location event with a non-empty userid when action parameters are nil")
    @MainActor
    func testLocationEventUseridWithNilActionParameters() async throws {
        let (_, trackerMock) = try await setupLocationTest(actionParameters: nil)
        #expect(trackerMock.state?.userIdentifier == "flo_test")
    }

    @Test("should process the location event with a non-empty easyid when action parameters are nil")
    @MainActor
    func testLocationEventEasyidWithNilActionParameters() async throws {
        let (_, trackerMock) = try await setupLocationTest(actionParameters: nil)
        #expect(trackerMock.state?.easyIdentifier == "123456")
    }

    @Test("should process the location event with a non-empty cka when action parameters are nil")
    @MainActor
    func testLocationEventCkaWithNilActionParameters() async throws {
        let (_, trackerMock) = try await setupLocationTest(actionParameters: nil)
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
        let (locationModel, _) = try await setupLocationTest(actionParameters: nil, location: location)
        #expect(locationModel == expectedLocationModel)
    }

    @Test("should process the location event with an expected location model when action parameters are nil")
    @MainActor
    func testLocationEventLocationModelWithNilActionParameters() async throws {
        let location = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
        let expectedLocationModel = LocationModel(
            location: location,
            isAction: true,
            actionParameters: nil)
        let (_, trackerMock) = try await setupLocationTest(actionParameters: nil, location: location)
        #expect(trackerMock.state?.lastKnownLocation == expectedLocationModel)
    }

    @Test("should process the location event with nil action parameters")
    @MainActor
    func testLocationEventNilActionParameters() async throws {
        let (_, trackerMock) = try await setupLocationTest(actionParameters: nil)
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
        let (_, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
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
        let (_, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
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
        let (_, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
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
        let (_, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
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
        let (_, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
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
        let (_, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
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
        let (_, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
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

        let (locationModel, _) = try await setupLocationTest(actionParameters: actionParameters, location: location)
        #expect(locationModel == expectedLocationModel)
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

        let (_, trackerMock) = try await setupLocationTest(actionParameters: actionParameters, location: location)
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
        let (_, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
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
        let (_, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
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
        let (_, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
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
        let (_, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
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
        let (_, trackerMock) = try await setupLocationTest(actionParameters: actionParameters)
        #expect(trackerMock.state?.lastKnownLocation?.actionParameters?.additionalLog == "test-additionalLog")
    }

    // MARK: - Cancellation Tests

    @Test("requestLocation resumes with CancellationError when task is cancelled")
    @MainActor
    func testRequestLocationCancellation() async throws {
        let locationManagerMock = GeoLocationManagerMock()
        let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
        analyticsManager.add(TrackerMock())
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: locationManagerMock,
            device: UIDevice.current,
            analyticsManager: analyticsManager)

        let requestTask = Task {
            try await geoManager.requestLocation()
        }
        try await Task.sleep(nanoseconds: 10_000_000)
        requestTask.cancel()

        do {
            _ = try await requestTask.value
            Issue.record("Expected requestLocation to throw CancellationError")
        } catch is CancellationError {
            // Expected
        } catch {
            Issue.record("Expected CancellationError, got \(error)")
        }
    }

    @Test("second requestLocation cancels the first in-flight request")
    @MainActor
    func testRequestLocationSupersedesInFlightRequest() async throws {
        let locationManagerMock = GeoLocationManagerMock()
        let testLocation = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
        let expectedLocationModel = LocationModel(location: testLocation, isAction: true, actionParameters: nil)
        let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
        analyticsManager.add(TrackerMock())
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: locationManagerMock,
            device: UIDevice.current,
            analyticsManager: analyticsManager)

        let firstTask = Task {
            try await geoManager.requestLocation()
        }
        try await Task.sleep(nanoseconds: 10_000_000)

        locationManagerMock.respondWithLocationOnUserActionRequest = testLocation
        let secondLocation = try await geoManager.requestLocation()

        do {
            _ = try await firstTask.value
            Issue.record("Expected first requestLocation to throw CancellationError")
        } catch is CancellationError {
            // Expected
        } catch {
            Issue.record("Expected CancellationError, got \(error)")
        }
        #expect(secondLocation == expectedLocationModel)
    }

    @Test("clearData cancels an in-flight requestLocation")
    @MainActor
    func testClearDataCancelsInFlightRequestLocation() async throws {
        let locationManagerMock = GeoLocationManagerMock()
        let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
        analyticsManager.add(TrackerMock())
        let geoManager = GeoManager(
            userStorageHandler: Self.dependenciesContainer.userStorageHandler,
            geoLocationManager: locationManagerMock,
            device: UIDevice.current,
            analyticsManager: analyticsManager)

        let requestTask = Task {
            try await geoManager.requestLocation()
        }
        try await Task.sleep(nanoseconds: 10_000_000)
        try await geoManager.clearData()

        do {
            _ = try await requestTask.value
            Issue.record("Expected requestLocation to throw CancellationError after clearData")
        } catch is CancellationError {
            // Expected
        } catch {
            Issue.record("Expected CancellationError, got \(error)")
        }
    }

    // MARK: - Error Tests

    @Test("should return an error when core location manager returns an error")
    @MainActor
    func testReturnError() async throws {
        let expectedError = NSError(domain: "", code: 0, userInfo: nil)
        let (error, _) = try await setupErrorTest(expectedError: expectedError)
        #expect(error as NSError == expectedError)
    }

    @Test("should not process the location event when core location manager returns an error")
    @MainActor
    func testNoLocationEventOnError() async throws {
        let expectedError = NSError(domain: "", code: 0, userInfo: nil)
        let (_, trackerMock) = try await setupErrorTest(expectedError: expectedError)
        #expect(trackerMock.event == nil)
    }

    // MARK: - Helper Methods

    @MainActor
    private func setupLocationTest(actionParameters: GeoActionParameters?, location: CLLocation? = nil) async throws -> (LocationModel, TrackerMock) {
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
        try keychainHandlerMock.set(value: "123456", for: RAnalyticsExternalCollector.Constants.easyIdentifierKey)

        analyticsDependenciesContainer.adIdentifierManager = asIdentifierManagerMock
        analyticsDependenciesContainer.userStorageHandler = userDefaultsMock
        analyticsDependenciesContainer.keychainHandler = keychainHandlerMock

        let analyticsManager = AnalyticsManager(dependenciesContainer: analyticsDependenciesContainer)
        analyticsManager.add(trackerMock)
        let geoManager = GeoManager(
            userStorageHandler: dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManager,
            device: UIDevice.current,
            analyticsManager: analyticsManager)

        coreLocationManagerMock.respondWithLocationOnRequest = testLocation
        coreLocationManagerMock.locationManagerForDelegateCallbacks = GeoManagerLocationEventTests.coreLocationManager
        let locationModel = try await geoManager.requestLocation(actionParameters: actionParameters)
        return (locationModel, trackerMock)
    }

    @MainActor
    private func setupErrorTest(expectedError: NSError) async throws -> (Error, TrackerMock) {
        let analyticsDependenciesContainer = SimpleContainerMock()
        let dependenciesContainer = SimpleContainerMock()
        let trackerMock = TrackerMock()
        let coreLocationManagerMock = LocationManagerMock()
        let geoLocationManager = GeoLocationManager(
            bundle: BundleMock(),
            coreLocationManager: coreLocationManagerMock,
            configurationStore: GeoManagerLocationEventTests.configurationStore)

        let analyticsManager = AnalyticsManager(dependenciesContainer: analyticsDependenciesContainer)
        analyticsManager.add(trackerMock)
        let geoManager = GeoManager(
            userStorageHandler: dependenciesContainer.userStorageHandler,
            geoLocationManager: geoLocationManager,
            device: UIDevice.current,
            analyticsManager: analyticsManager)

        coreLocationManagerMock.respondWithErrorOnRequest = expectedError
        coreLocationManagerMock.locationManagerForDelegateCallbacks = GeoManagerLocationEventTests.coreLocationManager
        do {
            _ = try await geoManager.requestLocation()
            Issue.record("Expected requestLocation to throw")
            return (expectedError, trackerMock)
        } catch {
            return (error, trackerMock)
        }
    }
}

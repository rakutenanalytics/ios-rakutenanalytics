import Testing
@testable import RakutenAnalytics
import CoreLocation.CLLocationManager

#if SWIFT_PACKAGE
import RAnalyticsTestHelpers
#endif

@Suite("GeoLocationManager")
struct GeoLocationManagerSpec {
    static let dependenciesContainer = GeoDependenciesContainer()
    static let userStorageHandler = dependenciesContainer.userStorageHandler
    static let configurationStore = GeoConfigurationStore(userStorageHandler: userStorageHandler)
    static let coreLocationManager = CLLocationManager()
    static let expectedError = NSError(domain: "", code: 0, userInfo: nil)
    static let location = CLLocation(latitude: -56.6462520, longitude: -36.6462520)
    static let expectedUserActionLocationModel = LocationModel(
        location: location,
        isAction: true,
        actionParameters: nil)
    static let expectedContinualLocationModel = LocationModel(
        location: location,
        isAction: false,
        actionParameters: nil)
    
    var coreLocationManagerMock: LocationManagerMock!
    var geoLocationManager: GeoLocationManager!
    var geoLocationManagerMock: GeoLocationManagerMock!
    
    mutating func setUp() {
        coreLocationManagerMock = LocationManagerMock()
        geoLocationManager = GeoLocationManager(
            bundle: BundleMock(),
            coreLocationManager: coreLocationManagerMock,
            configurationStore: Self.configurationStore)
        geoLocationManagerMock = GeoLocationManagerMock()
    }
    
    @Test("should set a non-nil core location manager delegate")
    mutating func testCoreLocationManagerDelegate() {
        setUp()
        #expect(coreLocationManagerMock.delegate as? GeoLocationManager == geoLocationManager)
    }
    
    @Test("should set desiredAccuracy to configured value")
    func testDesiredAccuracy() {
        #expect(Self.coreLocationManager.desiredAccuracy == kCLLocationAccuracyBest)
    }
    
    @Test("should set allowsBackgroundLocationUpdates as per configured capabilities")
    func testAllowsBackgroundLocationUpdates() {
        #expect(Self.coreLocationManager.allowsBackgroundLocationUpdates == false)
    }
    
    @Test("should return false for allowsBackgroundLocationUpdates by default")
    mutating func testDefaultAllowsBackgroundLocationUpdates() {
        setUp()
        #expect(coreLocationManagerMock.allowsBackgroundLocationUpdates == false)
    }
    
    @Test("should return true when allowsBackgroundLocationUpdates is set to true")
    mutating func testSetAllowsBackgroundLocationUpdates() {
        setUp()
        coreLocationManagerMock.allowsBackgroundLocationUpdates = true
        #expect(coreLocationManagerMock.allowsBackgroundLocationUpdates == true)
    }
    
    @Test("should not be nil on instantiation")
    mutating func testInstantiation() {
        setUp()
        #expect(geoLocationManager != nil)
    }
    
    @Test("should call CLLocationManager's requestLocationUpdate(for: .userAction)")
    mutating func testRequestLocationUpdateUserAction() async {
        setUp()
        geoLocationManager.requestLocationUpdate(for: .userAction)
        try? await Task.sleep(nanoseconds: 10_000_000)
        #expect(coreLocationManagerMock.requestLocationIsCalled == true)
    }
    
    @Test("should return an expected location when requestLocationUpdate(for: .userAction) is called and core location manager returns a location")
    mutating func testUserActionLocationUpdate() async {
        setUp()
        geoLocationManager.requestLocationUpdate(for: .userAction)
        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didUpdateLocations: [Self.location])
        geoLocationManagerMock.geoLocationManager(didUpdateLocation: Self.location, for: .userAction)
        
        try? await Task.sleep(nanoseconds: 10_000_000)
        
        #expect(geoLocationManagerMock.delegateGeoLocationManagerDidUpdateLocationIsCalled == true)
        #expect(geoLocationManagerMock.locationModel != nil)
        #expect(geoLocationManagerMock.locationModel == Self.expectedUserActionLocationModel)
        #expect(geoLocationManagerMock.locationModel.isAction == true)
    }
    
    @Test("should return an error when requestLocationUpdate(for: .userAction) is called and core location manager returns an error")
    mutating func testUserActionLocationError() async {
        setUp()
        geoLocationManager.requestLocationUpdate(for: .userAction)
        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didFailWithError: Self.expectedError)
        geoLocationManagerMock.geoLocationManager(didFailWithError: Self.expectedError, for: .userAction)
        
        try? await Task.sleep(nanoseconds: 10_000_000)
        
        #expect(geoLocationManagerMock.delegateGeoLocationManagerDidFailWithErrorIsCalled == true)
        #expect(geoLocationManagerMock.locationError != nil)
        #expect(geoLocationManagerMock.locationError == Self.expectedError)
    }
    
    @Test("should be called when state is outside and region identifier is correct")
    mutating func testDidDetermineStateOutsideCorrectIdentifier() {
        setUp()
        geoLocationManagerMock.delegateCLLocationManagerDidDetermineStateIsCalled = false
        
        let monitoredRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 1.2345, longitude: 6.7890),
            radius: 300,
            identifier: "GeoLocationCollectionRegionIdentifier")
        
        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didDetermineState: .outside, for: monitoredRegion)
        geoLocationManagerMock.locationManager(Self.coreLocationManager, didDetermineState: .outside, for: monitoredRegion)
        
        #expect(geoLocationManagerMock.delegateCLLocationManagerDidDetermineStateIsCalled == true)
    }
    
    @Test("should not be called when state is not outside and region identifier is incorrect")
    mutating func testDidDetermineStateInsideIncorrectIdentifier() {
        setUp()
        geoLocationManagerMock.delegateCLLocationManagerDidDetermineStateIsCalled = false
        
        let monitoredRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 1.2345, longitude: 6.7890),
            radius: 300,
            identifier: "BadGeoLocationCollectionRegionIdentifier")
        
        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didDetermineState: .inside, for: monitoredRegion)
        geoLocationManagerMock.locationManager(Self.coreLocationManager, didDetermineState: .inside, for: monitoredRegion)
        
        #expect(geoLocationManagerMock.delegateCLLocationManagerDidDetermineStateIsCalled == false)
    }
    
    @Test("should not be called when state is outside and region identifier is incorrect")
    mutating func testDidDetermineStateOutsideIncorrectIdentifier() {
        setUp()
        geoLocationManagerMock.delegateCLLocationManagerDidDetermineStateIsCalled = false
        
        let monitoredRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 1.2345, longitude: 6.7890),
            radius: 300,
            identifier: "BadGeoLocationCollectionRegionIdentifier")
        
        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didDetermineState: .outside, for: monitoredRegion)
        geoLocationManagerMock.locationManager(Self.coreLocationManager, didDetermineState: .outside, for: monitoredRegion)
        
        #expect(geoLocationManagerMock.delegateCLLocationManagerDidDetermineStateIsCalled == false)
    }
    
    @Test("should not be called when state is not outside and region identifier is correct")
    mutating func testDidDetermineStateInsideCorrectIdentifier() {
        setUp()
        geoLocationManagerMock.delegateCLLocationManagerDidDetermineStateIsCalled = false
        
        let monitoredRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 1.2345, longitude: 6.7890),
            radius: 300,
            identifier: "GeoLocationCollectionRegionIdentifier")
        
        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didDetermineState: .inside, for: monitoredRegion)
        geoLocationManagerMock.locationManager(Self.coreLocationManager, didDetermineState: .inside, for: monitoredRegion)
        
        #expect(geoLocationManagerMock.delegateCLLocationManagerDidDetermineStateIsCalled == false)
    }
    
    @Test("should call CLLocationManager's requestLocationUpdate(for: .continual)")
    mutating func testRequestLocationUpdateContinual() async {
        setUp()
        geoLocationManager.requestLocationUpdate(for: .continual)
        try? await Task.sleep(nanoseconds: 10_000_000)
        #expect(coreLocationManagerMock.requestLocationIsCalled == true)
    }
    
    @Test("should return an expected location when requestLocationUpdate(for: .continual) is called and core location manager returns a location")
    mutating func testContinualLocationUpdate() async {
        setUp()
        geoLocationManager.requestLocationUpdate(for: .continual)
        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didUpdateLocations: [Self.location])
        geoLocationManagerMock.geoLocationManager(didUpdateLocation: Self.location, for: .continual)
        
        try? await Task.sleep(nanoseconds: 10_000_000)
        
        #expect(geoLocationManagerMock.delegateGeoLocationManagerDidUpdateLocationIsCalled == true)
        #expect(geoLocationManagerMock.locationModel != nil)
        #expect(geoLocationManagerMock.locationModel == Self.expectedContinualLocationModel)
        #expect(geoLocationManagerMock.locationModel.isAction == false)
    }
    
    @Test("should return an error when requestLocationUpdate(for: .continual) is called and core location manager returns an error")
    mutating func testContinualLocationError() async {
        setUp()
        geoLocationManager.requestLocationUpdate(for: .continual)
        coreLocationManagerMock.delegate?.locationManager?(Self.coreLocationManager, didFailWithError: Self.expectedError)
        geoLocationManagerMock.geoLocationManager(didFailWithError: Self.expectedError, for: .continual)
        
        try? await Task.sleep(nanoseconds: 10_000_000)
        
        #expect(geoLocationManagerMock.delegateGeoLocationManagerDidFailWithErrorIsCalled == true)
        #expect(geoLocationManagerMock.locationError != nil)
        #expect(geoLocationManagerMock.locationError == Self.expectedError)
    }
}

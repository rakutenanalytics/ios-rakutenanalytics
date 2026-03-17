import Foundation
import CoreLocation
@preconcurrency @testable import RakutenAnalytics

// MARK: - LocationModel Factory

extension LocationModel {
    public static func create(
        latitude: CLLocationDegrees = -56.6462520,
        longitude: CLLocationDegrees = -36.6462520,
        horizontalAccuracy: CLLocationAccuracy = 10,
        speed: CLLocationSpeed = 5,
        speedAccuracy: CLLocationSpeedAccuracy = 10,
        verticalAccuracy: CLLocationAccuracy = 9,
        altitude: CLLocationDistance = 150,
        course: CLLocationDirection = 5,
        courseAccuracy: CLLocationDirectionAccuracy = 1,
        timestamp: Date = Date(timeIntervalSince1970: 1679054447.532),
        isAction: Bool = false,
        actionParameters: GeoActionParameters? = nil) -> LocationModel {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let location = CLLocation(
                coordinate: coordinate,
                altitude: altitude,
                horizontalAccuracy: horizontalAccuracy,
                verticalAccuracy: verticalAccuracy,
                course: course,
                courseAccuracy: courseAccuracy,
                speed: speed,
                speedAccuracy: speedAccuracy,
                timestamp: timestamp)
            
            return LocationModel(location: location, isAction: isAction, actionParameters: actionParameters)
        }
}

// MARK: - PayloadTestHelper

public enum PayloadTestHelper {
    public static let bundle: BundleMock = {
        let bundle = BundleMock.create()
        bundle.languageCode = Bundle.main.languageCode
        bundle.shortVersion = Bundle.main.shortVersion
        bundle.version = Bundle.main.version
        bundle.bundleIdentifier = Bundle.main.bundleIdentifier
        bundle.preferredLocalization = Bundle.main.preferredLocalizations.first
        return bundle
    }()
    
    // MARK: - Test Helper
    
    public struct TestHelper {
        var databaseConnection: SQlite3Pointer!
        var database: RAnalyticsDatabase!
        public let dependenciesContainer = SimpleContainerMock()
        public var ratTracker: RAnalyticsRATTracker!
        public let reachabilityMock = ReachabilityMock()
        public let expecter = RAnalyticsRATExpecter()
        
        public init() {}
        
        mutating public func setUp() {
            let databaseTableName = "testTableName_RAnalyticsRATTrackerTests"
            databaseConnection = DatabaseTestUtils.openRegularConnection()!
            database = DatabaseTestUtils.mkDatabase(connection: databaseConnection)
            dependenciesContainer.bundle = PayloadTestHelper.bundle
            dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database, tableName: databaseTableName)
            dependenciesContainer.session = SwiftyURLSessionMock()
            dependenciesContainer.deviceCapability = DeviceMock()
            dependenciesContainer.telephonyNetworkInfoHandler = TelephonyNetworkInfoMock()
            dependenciesContainer.analyticsStatusBarOrientationGetter = ApplicationMock(.portrait)
            dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(
                bundle: PayloadTestHelper.bundle,
                deviceCapability: dependenciesContainer.deviceCapability,
                screenHandler: dependenciesContainer.screenHandler,
                telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
                notificationHandler: dependenciesContainer.notificationHandler,
                analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
                reachability: reachabilityMock,
                userStorageHandler: dependenciesContainer.userStorageHandler)
            reachabilityMock.flags = nil
            
            ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
            ratTracker.set(batchingDelay: 0)
            
            expecter.dependenciesContainer = dependenciesContainer
            expecter.endpointURL = PayloadTestHelper.bundle.endpointAddress
            expecter.databaseTableName = dependenciesContainer.databaseConfiguration?.tableName
            expecter.databaseConnection = databaseConnection
            expecter.ratTracker = ratTracker
        }
        
        mutating public func tearDown() {
            DatabaseTestUtils.deleteTableIfExists(dependenciesContainer.databaseConfiguration!.tableName, connection: databaseConnection)
            database.closeConnection()
            databaseConnection = nil
        }
    }
}

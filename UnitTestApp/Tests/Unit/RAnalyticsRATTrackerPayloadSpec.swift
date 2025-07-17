// swiftlint:disable line_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable control_statement

import Quick
import Nimble
import CoreTelephony
import SQLite3
import UIKit.UIDevice
import SystemConfiguration
import CoreLocation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - LocationModel Factory

extension LocationModel {
    static func create(latitude: CLLocationDegrees = -56.6462520,
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
        let location: CLLocation
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        if #available(iOS 13.4, *) {
            location = CLLocation(coordinate: coordinate,
                                  altitude: altitude,
                                  horizontalAccuracy: horizontalAccuracy,
                                  verticalAccuracy: verticalAccuracy,
                                  course: course,
                                  courseAccuracy: courseAccuracy,
                                  speed: speed,
                                  speedAccuracy: speedAccuracy,
                                  timestamp: timestamp)
        } else {
            location = CLLocation(coordinate: coordinate,
                                  altitude: altitude,
                                  horizontalAccuracy: horizontalAccuracy,
                                  verticalAccuracy: verticalAccuracy,
                                  course: course,
                                  speed: speed,
                                  timestamp: timestamp)
        }

        return LocationModel(location: location,
                             isAction: isAction,
                             actionParameters: actionParameters)
    }
}

// MARK: - RAnalyticsRATTrackerPayloadSpec

class RAnalyticsRATTrackerPayloadSpec: QuickSpec {
    override class func spec() {
        describe("RAnalyticsRATTracker") {
            let bundle = BundleMock.create()
            bundle.languageCode = Bundle.main.languageCode
            bundle.shortVersion = Bundle.main.shortVersion
            bundle.version = Bundle.main.version
            bundle.bundleIdentifier = Bundle.main.bundleIdentifier
            let expecter = RAnalyticsRATExpecter()
            var databaseConnection: SQlite3Pointer!
            var database: RAnalyticsDatabase!
            let dependenciesContainer = SimpleContainerMock()
            var ratTracker: RAnalyticsRATTracker!
            let reachabilityMock = ReachabilityMock()

            beforeEach {
                let databaseTableName = "testTableName_RAnalyticsRATTrackerSpec"
                databaseConnection = DatabaseTestUtils.openRegularConnection()!
                database = DatabaseTestUtils.mkDatabase(connection: databaseConnection)
                dependenciesContainer.bundle = bundle
                dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database, tableName: databaseTableName)
                dependenciesContainer.session = SwiftyURLSessionMock()
                dependenciesContainer.deviceCapability = DeviceMock()
                dependenciesContainer.telephonyNetworkInfoHandler = TelephonyNetworkInfoMock()
                dependenciesContainer.analyticsStatusBarOrientationGetter = ApplicationMock(.portrait)
                dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(bundle: bundle,
                                                                                      deviceCapability: dependenciesContainer.deviceCapability,
                                                                                      screenHandler: dependenciesContainer.screenHandler,
                                                                                      telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
                                                                                      notificationHandler: dependenciesContainer.notificationHandler,
                                                                                      analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
                                                                                      reachability: reachabilityMock)
                reachabilityMock.flags = nil

                ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                ratTracker.set(batchingDelay: 0)

                expecter.dependenciesContainer = dependenciesContainer
                expecter.endpointURL = bundle.endpointAddress
                expecter.databaseTableName = dependenciesContainer.databaseConfiguration?.tableName
                expecter.databaseConnection = databaseConnection
                expecter.ratTracker = ratTracker
            }

            afterEach {
                DatabaseTestUtils.deleteTableIfExists(dependenciesContainer.databaseConfiguration!.tableName, connection: databaseConnection)
                database.closeConnection()
                databaseConnection = nil
            }

            describe("process(event:state:)") {
                context("Core parameters") {
                    it("should set a non-nil app_ver") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let ts1 = payload?["app_ver"] as? String
                        expect(ts1).to(equal(bundle.shortVersion))
                    }

                    it("should set app_name to the app's bundle identifier") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let appName = payload?["app_name"] as? String
                        #if SWIFT_PACKAGE
                        expect(appName).to(equal("com.apple.dt.xctest.tool"))
                        #else
                        expect(appName).to(equal("jp.co.rakuten.Host"))
                        #endif
                    }

                    it("should set mos to iOS {version_number}") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let mos = payload?["mos"] as? String
                        expect(mos).to(equal(UIDevice.current.systemName + " " + UIDevice.current.systemVersion))
                    }

                    it("should set ver to the SDK version") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let ver = payload?["ver"] as? String
                        expect(ver).to(equal(CoreHelpers.Constants.sdkVersion))
                    }

                    it("should set a non-nil ts1") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let ts1 = payload?["ts1"] as? TimeInterval
                        expect(ts1).toNot(beNil())
                    }
                }

                context("Device Language Code") {
                    let deviceLanguageCodes = ["jp", "en", "de", "fr", "hi"]

                    func verify(deviceLanguageCode: String) {
                        it("should set a non-nil dln") {
                            var payload: [String: Any]?

                            bundle.languageCode = deviceLanguageCode

                            expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let dln = payload?["dln"] as? String
                            expect(dln).to(equal(deviceLanguageCode))
                        }
                    }

                    deviceLanguageCodes.forEach { deviceLanguageCode in
                        verify(deviceLanguageCode: deviceLanguageCode)
                    }
                }

                context("Location") {
                    it("should set a non-empty loc dictionary") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]
                        expect(loc).toNot(beNil())
                    }

                    func verifyNilVerticalAccuracy(for locationModel: LocationModel) {
                        var payload: [String: Any]?

                        let state = Tracking.defaultState
                        state.lastKnownLocation = locationModel

                        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let verticalAccuracy = loc?["vertical_accuracy"] as? NSNumber
                        expect(verticalAccuracy?.doubleValue).to(beNil())
                    }

                    func verifyNilAltitude(for locationModel: LocationModel) {
                        var payload: [String: Any]?

                        let state = Tracking.defaultState
                        state.lastKnownLocation = locationModel

                        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let altitude = loc?["altitude"] as? NSNumber
                        expect(altitude?.doubleValue).to(beNil())
                    }

                    context("When vertical accuracy < 0") {
                        let locationModel = LocationModel.create(verticalAccuracy: -1)

                        it("should not set vertical accuracy") {
                            verifyNilVerticalAccuracy(for: locationModel)
                        }

                        it("should not set altitude") {
                            verifyNilAltitude(for: locationModel)
                        }
                    }

                    context("When vertical accuracy == 0") {
                        let locationModel = LocationModel.create(verticalAccuracy: 0)

                        it("should not set vertical accuracy") {
                            verifyNilVerticalAccuracy(for: locationModel)
                        }

                        it("should not set altitude") {
                            verifyNilAltitude(for: locationModel)
                        }
                    }

                    context("When vertical accuracy > 0") {
                        let locationModel = LocationModel.create(verticalAccuracy: 10, altitude: 153)
                        var state: RAnalyticsState!

                        beforeEach {
                            state = Tracking.defaultState
                            state.lastKnownLocation = locationModel
                        }

                        it("should set vertical accuracy") {
                            var payload: [String: Any]?

                            expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let loc = payload?["loc"] as? [String: Any]

                            let verticalAccuracy = loc?["vertical_accuracy"] as? NSNumber
                            expect(verticalAccuracy?.doubleValue).to(equal(10))
                        }

                        it("should set altitude") {
                            var payload: [String: Any]?

                            expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let loc = payload?["loc"] as? [String: Any]

                            let altitude = loc?["altitude"] as? NSNumber
                            expect(altitude?.doubleValue).to(equal(153))
                        }
                    }

                    it("should set a non-nil tms") {
                        let timestamp: TimeInterval = 1679991767.626
                        let locationModel = LocationModel.create(timestamp: Date(timeIntervalSince1970: timestamp))

                        var payload: [String: Any]?

                        let state = Tracking.defaultState
                        state.lastKnownLocation = locationModel

                        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let tms = loc?["tms"] as? NSNumber
                        expect(tms?.doubleValue).to(equal(timestamp * 1000.0))
                    }

                    func verifyHorizontalAccuracy(for locationModel: LocationModel, expectedHorizontalAccuracy: CLLocationAccuracy) {
                        var payload: [String: Any]?

                        let state = Tracking.defaultState
                        state.lastKnownLocation = locationModel

                        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let accu = loc?["accu"] as? NSNumber
                        expect(accu?.doubleValue).to(equal(expectedHorizontalAccuracy))
                    }

                    func verifyNilCoordinates(for locationModel: LocationModel) {
                        it("should not set accu") {
                            var payload: [String: Any]?

                            let state = Tracking.defaultState
                            state.lastKnownLocation = locationModel

                            expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let loc = payload?["loc"] as? [String: Any]

                            let accu = loc?["accu"] as? NSNumber
                            expect(accu?.doubleValue).to(beNil())
                        }

                        it("should not set lat") {
                            var payload: [String: Any]?

                            let state = Tracking.defaultState
                            state.lastKnownLocation = locationModel

                            expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let loc = payload?["loc"] as? [String: Any]

                            let lat = loc?["lat"] as? NSNumber
                            expect(lat?.doubleValue).to(beNil())
                        }

                        it("should not set long") {
                            var payload: [String: Any]?

                            let state = Tracking.defaultState
                            state.lastKnownLocation = locationModel

                            expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let loc = payload?["loc"] as? [String: Any]

                            let long = loc?["long"] as? NSNumber
                            expect(long?.doubleValue).to(beNil())
                        }
                    }

                    context("When horizontal accuracy < 0") {
                        verifyNilCoordinates(for: LocationModel.create(horizontalAccuracy: -9))
                    }

                    context("When latitude has an unexpected value") {
                        verifyNilCoordinates(for: LocationModel.create(latitude: 5600))
                    }

                    context("When longitude has an unexpected value") {
                        verifyNilCoordinates(for: LocationModel.create(latitude: -432))
                    }

                    context("When horizontal accuracy < 0 and latitude & longitude have unexpected values") {
                        verifyNilCoordinates(for: LocationModel.create(latitude: 5600,
                                                                       longitude: -432,
                                                                       horizontalAccuracy: -9))
                    }

                    func verifyCoordinates(for locationModel: LocationModel,
                                           expectedLatitude: CLLocationDegrees,
                                           expectedLongitude: CLLocationDegrees) {
                        it("should set a non-nil lat") {
                            var payload: [String: Any]?

                            let state = Tracking.defaultState
                            state.lastKnownLocation = locationModel

                            expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let loc = payload?["loc"] as? [String: Any]

                            let lat = loc?["lat"] as? NSNumber
                            expect(lat?.doubleValue).to(equal(expectedLatitude))
                        }

                        it("should set a non-nil long") {
                            var payload: [String: Any]?

                            let state = Tracking.defaultState
                            state.lastKnownLocation = locationModel

                            expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let loc = payload?["loc"] as? [String: Any]

                            let long = loc?["long"] as? NSNumber
                            expect(long?.doubleValue).to(equal(expectedLongitude))
                        }
                    }

                    context("When horizontal accuracy == 0") {
                        let locationModel = LocationModel.create(latitude: -56.6462520,
                                                                 longitude: -36.6462520,
                                                                 horizontalAccuracy: 0)

                        it("should set accu to an expected value") {
                            verifyHorizontalAccuracy(for: locationModel, expectedHorizontalAccuracy: 0)
                        }

                        verifyCoordinates(for: locationModel,
                                          expectedLatitude: -56.6462520,
                                          expectedLongitude: -36.6462520)
                    }

                    context("When horizontal accuracy > 0") {
                        let locationModel = LocationModel.create(latitude: -56.6462520,
                                                                 longitude: -36.6462520,
                                                                 horizontalAccuracy: 10)

                        it("should set accu to an expected value") {
                            verifyHorizontalAccuracy(for: locationModel, expectedHorizontalAccuracy: 10)
                        }

                        verifyCoordinates(for: locationModel,
                                          expectedLatitude: -56.6462520,
                                          expectedLongitude: -36.6462520)
                    }

                    func verifyNilSpeedParameters(for locationModel: LocationModel) {
                        it("should not set speed accuracy") {
                            var payload: [String: Any]?

                            let state = Tracking.defaultState
                            state.lastKnownLocation = locationModel

                            expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let loc = payload?["loc"] as? [String: Any]

                            let speedAccuracy = loc?["speed_accuracy"] as? NSNumber
                            expect(speedAccuracy?.doubleValue).to(beNil())
                        }

                        it("should not set speed") {
                            var payload: [String: Any]?

                            let state = Tracking.defaultState
                            state.lastKnownLocation = locationModel

                            expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let loc = payload?["loc"] as? [String: Any]

                            let speed = loc?["speed"] as? NSNumber
                            expect(speed?.doubleValue).to(beNil())
                        }
                    }

                    context("When speed accuracy < 0") {
                        context("When speed > 0") {
                            verifyNilSpeedParameters(for: LocationModel.create(speed: 180, speedAccuracy: -7))
                        }

                        context("When speed == 0") {
                            verifyNilSpeedParameters(for: LocationModel.create(speed: 0, speedAccuracy: -7))
                        }
                    }

                    context("When speed < 0") {
                        context("When speed accuracy > 0") {
                            verifyNilSpeedParameters(for: LocationModel.create(speed: -180, speedAccuracy: 7))
                        }

                        context("When speed accuracy == 0") {
                            verifyNilSpeedParameters(for: LocationModel.create(speed: -180, speedAccuracy: 0))
                        }
                    }

                    context("When speed accuracy < 0 and speed < 0") {
                        context("When speed accuracy < 0") {
                            verifyNilSpeedParameters(for: LocationModel.create(speed: -180, speedAccuracy: -7))
                        }
                    }

                    func verifySpeedAccuracy(for locationModel: LocationModel, expectedSpeedAccuracy: CLLocationSpeedAccuracy) {
                        var payload: [String: Any]?

                        let state = Tracking.defaultState
                        state.lastKnownLocation = locationModel

                        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let speedAccuracy = loc?["speed_accuracy"] as? NSNumber
                        expect(speedAccuracy?.doubleValue).to(equal(expectedSpeedAccuracy))
                    }

                    func verifySpeed(for locationModel: LocationModel, expectedSpeed: CLLocationSpeed) {
                        var payload: [String: Any]?

                        let state = Tracking.defaultState
                        state.lastKnownLocation = locationModel

                        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let speed = loc?["speed"] as? NSNumber
                        expect(speed?.doubleValue).to(equal(expectedSpeed))
                    }

                    context("When speed accuracy == 0") {
                        let locationModel = LocationModel.create(speed: 54,
                                                                 speedAccuracy: 0)
                        it("should set speed accuracy") {
                            verifySpeedAccuracy(for: locationModel, expectedSpeedAccuracy: 0)
                        }

                        it("should set speed to an expected value") {
                            verifySpeed(for: locationModel, expectedSpeed: 54)
                        }
                    }

                    context("When speed accuracy > 0") {
                        let locationModel = LocationModel.create(speed: 180,
                                                                 speedAccuracy: 7)

                        it("should set speed accuracy") {
                            verifySpeedAccuracy(for: locationModel, expectedSpeedAccuracy: 7)
                        }

                        it("should set speed to an expected value") {
                            verifySpeed(for: locationModel, expectedSpeed: 180)
                        }
                    }

                    func verifyNilBearingParameters(for locationModel: LocationModel) {
                        it("should not set bearing accuracy") {
                            var payload: [String: Any]?

                            let state = Tracking.defaultState
                            state.lastKnownLocation = locationModel

                            expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let loc = payload?["loc"] as? [String: Any]

                            let bearing = loc?["bearing_accuracy"] as? NSNumber
                            expect(bearing?.doubleValue).to(beNil())
                        }

                        it("should not set bearing") {
                            var payload: [String: Any]?

                            let state = Tracking.defaultState
                            state.lastKnownLocation = locationModel

                            expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let loc = payload?["loc"] as? [String: Any]

                            let bearing = loc?["bearing"] as? NSNumber
                            expect(bearing?.doubleValue).to(beNil())
                        }
                    }

                    context("When course accuracy < 0") {
                        context("When course > 0") {
                            verifyNilBearingParameters(for: LocationModel.create(course: 2, courseAccuracy: -1))
                        }

                        context("When course == 0") {
                            verifyNilBearingParameters(for: LocationModel.create(course: 0, courseAccuracy: -1))
                        }
                    }

                    context("When course < 0") {
                        context("When course accuracy > 0") {
                            verifyNilBearingParameters(for: LocationModel.create(course: -2, courseAccuracy: 1))
                        }

                        context("When course accuracy == 0") {
                            verifyNilBearingParameters(for: LocationModel.create(course: -2, courseAccuracy: 0))
                        }
                    }

                    context("When course < 0 and course accuracy < 0") {
                        verifyNilBearingParameters(for: LocationModel.create(course: -2, courseAccuracy: -1))
                    }

                    func verifyBearingAccuracy(for locationModel: LocationModel, expectedBearingAccuracy: CLLocationDirectionAccuracy) {
                        var payload: [String: Any]?

                        let state = Tracking.defaultState
                        state.lastKnownLocation = locationModel

                        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let bearingAccuracy = loc?["bearing_accuracy"] as? NSNumber
                        expect(bearingAccuracy?.doubleValue).to(equal(expectedBearingAccuracy))
                    }

                    func verifyBearing(for locationModel: LocationModel, expectedBearing: CLLocationDirection) {
                        var payload: [String: Any]?

                        let state = Tracking.defaultState
                        state.lastKnownLocation = locationModel

                        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let bearing = loc?["bearing"] as? NSNumber
                        expect(bearing?.doubleValue).to(equal(expectedBearing))
                    }

                    context("When course accuracy == 0") {
                        let locationModel = LocationModel.create(course: 2,
                                                                 courseAccuracy: 0)

                        it("should set bearing accuracy") {
                            verifyBearingAccuracy(for: locationModel, expectedBearingAccuracy: 0)
                        }

                        it("should set bearing") {
                            verifyBearing(for: locationModel, expectedBearing: 2)
                        }
                    }

                    context("When course accuracy > 0") {
                        let locationModel = LocationModel.create(course: 2,
                                                                 courseAccuracy: 19)

                        it("should set bearing accuracy") {
                            verifyBearingAccuracy(for: locationModel, expectedBearingAccuracy: 19)
                        }

                        it("should set bearing") {
                            verifyBearing(for: locationModel, expectedBearing: 2)
                        }
                    }
                }

                context("Network status") {
                    context("When reachabilityStatus is not set") {
                        it("should not set online") {
                            var payload: [String: Any]?

                            reachabilityMock.flags = nil

                            expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let online = payload?["online"] as? NSNumber
                            expect(online).to(beNil())
                        }
                    }

                    context("When there is no network connection") {
                        it("should set online to false") {
                            var payload: [String: Any]?

                            reachabilityMock.flags = .connectionRequired

                            expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let online = payload?["online"] as? NSNumber
                            expect(online?.boolValue).to(beFalse())
                        }
                    }

                    context("When there is a wwan connection") {
                        it("should set online to true") {
                            var payload: [String: Any]?

                            reachabilityMock.flags = [.isWWAN, .reachable]

                            expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let online = payload?["online"] as? NSNumber
                            expect(online?.boolValue).to(beTrue())
                        }
                    }

                    context("When there is a wifi connection") {
                        it("should set online to true") {
                            var payload: [String: Any]?

                            reachabilityMock.flags = [.isDirect, .reachable]

                            expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let online = payload?["online"] as? NSNumber
                            expect(online?.boolValue).to(beTrue())
                        }
                    }
                }

                context("Start time") {
                    it("should set a non-nil ltm") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let ltm = payload?["ltm"] as? String
                        expect(ltm).toNot(beNil())
                    }
                }

                context("Time zone") {
                    it("should set a non-nil tzo") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let tzo = payload?["tzo"] as? NSNumber
                        expect(tzo).toNot(beNil())
                    }
                }

                context("Session Identifier") {
                    it("should set cks to CA7A88AR-82FE-40C9-A836-B1B3455DECAF") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let cks = payload?["cks"] as? String
                        expect(cks).to(equal("CA7A88AR-82FE-40C9-A836-B1B3455DECAF"))
                    }
                }

                context("Device Identifier") {
                    it("should set ckp to deviceId") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let ckp = payload?["ckp"] as? String
                        expect(ckp).to(equal("deviceId"))
                    }
                }

                context("IDFA") {
                    it("should set cka to adId") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let cka = payload?["cka"] as? String
                        expect(cka).to(equal("adId"))
                    }
                }

                context("User Agent") {
                    it("should set ua to jp.co.rakuten.Host/1.0") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let ua = payload?["ua"] as? String
                        #if SWIFT_PACKAGE
                        expect(ua).to(equal("com.apple.dt.xctest.tool/\(Tracking.defaultState.currentVersion)"))
                        #else
                        expect(ua).to(equal("jp.co.rakuten.Host/\(Tracking.defaultState.currentVersion)"))
                        #endif

                    }
                }

                context("Device") {
                    context("Model") {
                        it("should set a non-nil model") {
                            var payload: [String: Any]?

                            expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let model = payload?["model"] as? String
                            expect(model).toNot(beNil())
                        }
                    }

                    context("Resolution") {
                        it("should set a non-nil res") {
                            var payload: [String: Any]?

                            expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let res = payload?["res"] as? String
                            expect(res).toNot(beNil())
                        }
                    }

                    context("Battery infos") {
                        it("should process an event with battery infos") {
                            var payload: [String: Any]?

                            expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())

                            let powerstatus = payload?["powerstatus"] as? NSNumber
                            let mbat = payload?["mbat"] as? String
                            expect(powerstatus?.intValue).to(equal(0))
                            expect(mbat).to(equal("50"))
                        }
                    }
                }

                context("mnetw and mnetwd") {
                    context("Wwan") {
                        it("should process an event with no primary radio and no secondary radio when the network status is offline") {
                            verify(primaryRadio: "", secondaryRadio: "", reachabilityStatus: .wwan)
                        }

                        it("should process an event with Edge primary radio and LTE secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM") {
                            verify(primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyLTE, reachabilityStatus: .wwan)
                        }

                        it("should process an event with LTE primary radio and Edge secondary radio when the network status is wwan and the radio is LTE for the main carrier and Edge for the eSIM") {
                            verify(primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyEdge, reachabilityStatus: .wwan)
                        }

                        if #available(iOS 14.1, *) {
                            it("should process an event with Edge primary radio and 5G secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM") {
                                verify(primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyNR, reachabilityStatus: .wwan)
                            }

                            it("should process an event with 5G primary radio and Edge secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM") {
                                verify(primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyEdge, reachabilityStatus: .wwan)
                            }

                            it("should process an event with Edge primary radio and 5G secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM") {
                                verify(primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyNR, reachabilityStatus: .wwan)
                            }

                            it("should process an event with 5G primary radio and Edge secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM") {
                                verify(primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyLTE, reachabilityStatus: .wwan)
                            }
                        }

                        context("Edge") {
                            it("should process an event with Edge primary radio and no secondary radio when the network status is wwan and the radio is not LTE and there is only one carrier") {
                                verify(primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: "", reachabilityStatus: .wwan)
                            }

                            it("should process an event with no primary radio and Edge secondary radio when the network status is wwan and the radio is LTE and there is only one carrier") {
                                verify(primaryRadio: "", secondaryRadio: CTRadioAccessTechnologyEdge, reachabilityStatus: .wwan)
                            }

                            it("should process an event with Edge primary radio and Edge secondary radio when the network status is wwan and the radio is LTE for both carriers") {
                                verify(primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyEdge, reachabilityStatus: .wwan)
                            }
                        }

                        context("LTE") {
                            it("should process an event with LTE primary radio and no secondary radio when the network status is wwan and the radio is LTE and there is only one carrier") {
                                verify(primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: "", reachabilityStatus: .wwan)
                            }

                            it("should process an event with no primary radio and LTE secondary radio when the network status is wwan and the radio is LTE and there is only one carrier") {
                                verify(primaryRadio: "", secondaryRadio: CTRadioAccessTechnologyLTE, reachabilityStatus: .wwan)
                            }

                            it("should process an event with LTE primary radio and LTE secondary radio when the network status is wwan and the radio is LTE for both carriers") {
                                verify(primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyLTE, reachabilityStatus: .wwan)
                            }
                        }

                        context("5G") {
                            if #available(iOS 14.1, *) {
                                it("should process an event with 5G primary radio and no secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM") {
                                    verify(primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: "", reachabilityStatus: .wwan)
                                }

                                it("should process an event with no primary radio and 5G secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM") {
                                    verify(primaryRadio: "", secondaryRadio: CTRadioAccessTechnologyNR, reachabilityStatus: .wwan)
                                }

                                it("should process an event with 5G primary radio and 5G secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM") {
                                    verify(primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyNR, reachabilityStatus: .wwan)
                                }
                            }
                        }
                    }

                    context("Wifi") {
                        it("should process an event with wifi when there is no primary radio, no secondary radio and the network status is wifi") {
                            verify(primaryRadio: "", secondaryRadio: "", reachabilityStatus: .wifi)
                        }

                        context("Edge") {
                            it("should process an event with wifi when there is Edge primary radio, no secondary radio and the network status is wifi") {
                                verify(primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: "", reachabilityStatus: .wifi)
                            }

                            it("should process an event with wifi when there is no primary radio, Edge secondary radio and the network status is wifi") {
                                verify(primaryRadio: "", secondaryRadio: CTRadioAccessTechnologyEdge, reachabilityStatus: .wifi)
                            }

                            it("should process an event with wifi when there is Edge primary radio, Edge secondary radio and the network status is wifi") {
                                verify(primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyEdge, reachabilityStatus: .wifi)
                            }
                        }

                        context("LTE") {
                            it("should process an event with wifi when there is LTE primary radio, no secondary radio and the network status is wifi") {
                                verify(primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: "", reachabilityStatus: .wifi)
                            }

                            it("should process an event with wifi when there is no primary radio, LTE secondary radio and the network status is wifi") {
                                verify(primaryRadio: "", secondaryRadio: CTRadioAccessTechnologyLTE, reachabilityStatus: .wifi)
                            }

                            it("should process an event with wifi when there is LTE primary radio, LTE secondary radio and the network status is wifi") {
                                verify(primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyLTE, reachabilityStatus: .wifi)
                            }
                        }

                        context("5G") {
                            if #available(iOS 14.1, *) {
                                it("should process an event with wifi when there is 5G primary radio, no secondary radio and the network status is wifi") {
                                    verify(primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: "", reachabilityStatus: .wifi)
                                }

                                it("should process an event with wifi when there is no primary radio, 5G secondary radio and the network status is wifi") {
                                    verify(primaryRadio: "", secondaryRadio: CTRadioAccessTechnologyNR, reachabilityStatus: .wifi)
                                }

                                it("should process an event with wifi when there is 5G primary radio, 5G secondary radio and the network status is wifi") {
                                    verify(primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyNR, reachabilityStatus: .wifi)
                                }
                            }
                        }
                    }

                    func verify(primaryRadio: String, secondaryRadio: String, reachabilityStatus: RATReachabilityStatus) {
                        var payload: [String: Any]?

                        switch(reachabilityStatus) {
                        case .wifi:
                            reachabilityMock.flags = [.isDirect, .reachable]
                        case .wwan:
                            reachabilityMock.flags = [.isWWAN, .reachable]
                        case .offline:
                            reachabilityMock.flags = [.connectionRequired]
                        }

                        let telephonyNetworkInfo = dependenciesContainer.telephonyNetworkInfoHandler as? TelephonyNetworkInfoMock
                        telephonyNetworkInfo?.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryRadio,
                                                                                     TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryRadio]

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        if reachabilityStatus == .wifi {
                            expect((payload?["mnetw"] as? NSNumber)?.intValue).to(equal(RATMobileNetworkType.wifi.rawValue))
                            expect((payload?["mnetwd"] as? NSNumber)?.intValue).to(equal(RATMobileNetworkType.wifi.rawValue))
                        } else {
                            if primaryRadio.isEmpty {
                                expect(payload?["mnetw"] as? String).to(equal(""))

                            } else {
                                expect((payload?["mnetw"] as? NSNumber)?.intValue).to(equal(primaryRadio.networkType.rawValue))
                            }

                            if secondaryRadio.isEmpty {
                                expect(payload?["mnetwd"] as? String).to(equal(""))

                            } else {
                                expect((payload?["mnetwd"] as? NSNumber)?.intValue).to(equal(secondaryRadio.networkType.rawValue))
                            }
                        }
                    }
                }

                context("Batching Delay") {
                    it("should set the expected batching delay to the sender when the RAT tracker batching delay is set") {
                        let delay = 15.0
                        ratTracker.set(batchingDelay: delay)
                        expectBatchingDelay(equal: delay)
                    }

                    it("should set the expected batching delay to the sender when the RAT tracker batching delay block is set") {
                        let delay = 10.0
                        ratTracker.set(batchingDelayBlock: { delay })
                        expectBatchingDelay(equal: delay)
                    }

                    func expectBatchingDelay(equal value: TimeInterval) {
                        let processed = ratTracker.process(event: Tracking.defaultEvent, state: Tracking.defaultState)
                        expect(processed).to(beTrue())

                        let sender = ratTracker.perform(Selector((("sender"))))?.takeUnretainedValue() as? RAnalyticsSender

                        var uploadTimerInterval: TimeInterval?

                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                            uploadTimerInterval = sender?.uploadTimerInterval
                        }
                        expect(uploadTimerInterval).toEventually(equal(value))
                    }
                }

                context("mori") {
                    it("should set the mori value to 1") {
                        let statusBarOrientationGetter = dependenciesContainer.analyticsStatusBarOrientationGetter as? ApplicationMock
                        statusBarOrientationGetter?.injectedValue = .portrait
                        expectMori(equal: 1)
                    }

                    it("should set the mori value to 1") {
                        let statusBarOrientationGetter = dependenciesContainer.analyticsStatusBarOrientationGetter as? ApplicationMock
                        statusBarOrientationGetter?.injectedValue = .portraitUpsideDown
                        expectMori(equal: 1)
                    }

                    it("should set the mori value to 2") {
                        let statusBarOrientationGetter = dependenciesContainer.analyticsStatusBarOrientationGetter as? ApplicationMock
                        statusBarOrientationGetter?.injectedValue = .landscapeLeft
                        expectMori(equal: 2)
                    }

                    it("should set the mori value to 2") {
                        let statusBarOrientationGetter = dependenciesContainer.analyticsStatusBarOrientationGetter as? ApplicationMock
                        statusBarOrientationGetter?.injectedValue = .landscapeRight
                        expectMori(equal: 2)
                    }

                    it("should set the mori value to 1") {
                        let statusBarOrientationGetter = dependenciesContainer.analyticsStatusBarOrientationGetter as? ApplicationMock
                        statusBarOrientationGetter?.injectedValue = .unknown
                        expectMori(equal: 1)
                    }

                    it("should set the mori value to 1") {
                        dependenciesContainer.analyticsStatusBarOrientationGetter = nil
                        ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                        ratTracker.set(batchingDelay: 0)

                        expecter.dependenciesContainer = dependenciesContainer
                        expecter.ratTracker = ratTracker
                        expectMori(equal: 1)
                    }

                    func expectMori(equal value: Int) {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect((payload?["mori"] as? NSNumber)?.intValue).to(equal(value))
                    }
                }

                context("easyid") {
                    it("should set the easyid") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(payload?["easyid"] as? String).to(equal("easyId"))
                    }

                    it("should not set the easyid when the state's easyIdentifier is not set") {
                        var payload: [String: Any]?

                        let state = RAnalyticsState(sessionIdentifier: "CA7A88AR-82FE-40C9-A836-B1B3455DECAF",
                                                    deviceIdentifier: "deviceId")
                        state.easyIdentifier = nil

                        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(payload?["easyid"] as? String).to(beNil())
                    }
                }
            }
        }
    }
}

// swiftlint:enable line_length
// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
// swiftlint:enable control_statement

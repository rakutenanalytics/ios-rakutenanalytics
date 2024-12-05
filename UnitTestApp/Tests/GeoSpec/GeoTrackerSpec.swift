// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable line_length

import Quick
import Nimble
import SQLite3
import Foundation
import UIKit
import CoreLocation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class GeoTrackerSpec: QuickSpec {
    override func spec() {
        describe("GeoTracker") {
            let databaseDirectory = FileManager.SearchPathDirectory.documentDirectory
            let databaseName = "test_RAnalyticsSDKTracker.db"
            let databaseTableName = "testTableName_SDKTrackerSpec"
            let urlSession = SwiftyURLSessionMock()
            let bundle = BundleMock()
            var databaseConnection: SQlite3Pointer!
            var database: RAnalyticsDatabase!
            var databaseConfiguration: DatabaseConfiguration!
            let dependenciesContainer = GeoContainerMock()
            var geoTracker: GeoTracker!

            beforeEach {
                urlSession.urlRequest = nil
                dependenciesContainer.session = urlSession
                dependenciesContainer.bundle = bundle
                dependenciesContainer.screenHandler = ScreenMock(bounds: CGRect(x: 0, y: 0, width: 375, height: 812))

                databaseConnection = RAnalyticsDatabase.mkAnalyticsDBConnection(databaseName: databaseName,
                                                                                databaseParentDirectory: databaseDirectory)
                database = RAnalyticsDatabase.database(connection: databaseConnection)
                databaseConfiguration = DatabaseConfiguration(database: database, tableName: databaseTableName)
            }

            afterEach {
                DatabaseTestUtils.deleteTableIfExists(databaseConfiguration.tableName, connection: databaseConnection)
                database.closeConnection()
                databaseConnection = nil
            }

            describe("init(dependenciesContainer:databaseConfiguration:)") {
                context("When the bundle has a nil endpoint URL") {
                    beforeEach {
                        bundle.endpointAddress = nil
                        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer,
                                                databaseConfiguration: databaseConfiguration)
                    }

                    it("should return nil") {
                        expect(geoTracker).to(beNil())
                    }
                }

                context("When the bundle has a non-nil endpoint URL") {
                    beforeEach {
                        bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
                        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer,
                                                databaseConfiguration: databaseConfiguration)
                    }

                    it("should return a new instance of GeoTracker") {
                        expect(geoTracker).toNot(beNil())
                    }

                    it("should set an expected endpoint to the GeoTracker instance") {
                        expect(geoTracker.endpointURL?.absoluteString).to(equal("https://endpoint.co.jp"))
                    }
                }
            }

            describe("process(event:state:)") {
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

                func createLocation(isAction: Bool = false,
                                    actionParameters: GeoActionParameters? = nil) -> LocationModel {
                    var location: CLLocation

                    let coordinate = CLLocationCoordinate2D(latitude: expectedLatitude, longitude: expectedLongitude)

                    if #available(iOS 13.4, *) {
                        location = CLLocation(coordinate: coordinate,
                                          altitude: expectedAltitude,
                                          horizontalAccuracy: expectedAccuracy,
                                          verticalAccuracy: expectedVerticalAccuracy,
                                          course: expectedBearing,
                                          courseAccuracy: expectedBearingAccuracy,
                                          speed: expectedSpeed,
                                          speedAccuracy: expectedSpeedAccuracy,
                                          timestamp: Date(timeIntervalSince1970: expectedTms))
                    } else {
                        location = CLLocation(coordinate: coordinate,
                                                  altitude: expectedAltitude,
                                                  horizontalAccuracy: expectedAccuracy,
                                                  verticalAccuracy: expectedVerticalAccuracy,
                                                  course: expectedBearing,
                                                  speed: expectedSpeed,
                                                  timestamp: Date(timeIntervalSince1970: expectedTms))
                    }

                    return LocationModel(location: location,
                                         isAction: isAction,
                                         actionParameters: actionParameters)
                }

                let nonEmptyActionParameters = GeoActionParameters(actionType: expectedActionParamType,
                                                                   actionLog: expectedActionParamLog,
                                                                   actionId: expectedActionParamId,
                                                                   actionDuration: expectedActionParamDuration,
                                                                   additionalLog: expectedActionParamAddLog)

                let nilActionParameters = GeoActionParameters(actionType: nil,
                                                              actionLog: nil,
                                                              actionId: nil,
                                                              actionDuration: nil,
                                                              additionalLog: nil)

                func createLocEvent() -> RAnalyticsEvent {
                    RAnalyticsEvent(name: RAnalyticsEvent.Name.geoLocation, parameters: nil)
                }

                let pageVisitEvent = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit,
                                                     parameters: nil)
                let state = RAnalyticsState(sessionIdentifier: expectedSessionIdentifier,
                                            deviceIdentifier: expectedCkp)
                state.advertisingIdentifier = expectedCka
                state.userIdentifier = expectedUserIdentifier
                state.easyIdentifier = expectedEasyIdentifier

                beforeEach {
                    bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
                    dependenciesContainer.automaticFieldsBuilder = AutomaticFieldsBuilder(bundle: bundle,
                                                                                          deviceCapability: dependenciesContainer.deviceCapability,
                                                                                          screenHandler: dependenciesContainer.screenHandler,
                                                                                          telephonyNetworkInfoHandler: dependenciesContainer.telephonyNetworkInfoHandler,
                                                                                          notificationHandler: dependenciesContainer.notificationHandler,
                                                                                          analyticsStatusBarOrientationGetter: dependenciesContainer.analyticsStatusBarOrientationGetter,
                                                                                          reachability: Reachability(hostname: ReachabilityConstants.host))
                }

                context("When the event is not loc") {
                    beforeEach {
                        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer,
                                                databaseConfiguration: databaseConfiguration)
                    }

                    it("should not process the event") {
                        expect(geoTracker?.process(event: pageVisitEvent, state: state)).to(beFalse())
                    }

                    it("should set nil data to request's httpBody") {
                        _ = geoTracker?.process(event: pageVisitEvent, state: state)

                        expect(urlSession.urlRequest?.httpBody).to(beNil())
                    }
                }

                context("When the event is loc") {
                    let expectedAccountIdentifier: Int64 = 123
                    let expectedApplicationIdentifier: Int64 = 456
                    let expectedLanguageCode = "en"
                    var date: NSDate!
                    var expectedLtm: String!
                    var expectedTs1: TimeInterval!

                    beforeEach {
                        date = NSDate()
                        expectedLtm = date.toString
                        expectedTs1 = Swift.max(0, round(date.timeIntervalSince1970))
                        bundle.accountIdentifier = expectedAccountIdentifier
                        bundle.applicationIdentifier = expectedApplicationIdentifier
                        bundle.languageCode = expectedLanguageCode

                        geoTracker = GeoTracker(dependenciesContainer: dependenciesContainer,
                                                batchingDelay: 1.0,
                                                databaseConfiguration: databaseConfiguration)
                    }

                    it("should process the event") {
                        state.lastKnownLocation = createLocation()

                        expect(geoTracker?.process(event: createLocEvent(), state: state)).to(beTrue())
                        expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))
                    }

                    it("should set a non-nil httpBody to the URL request") {
                        state.lastKnownLocation = createLocation()

                        _ = geoTracker?.process(event: createLocEvent(), state: state)
                        expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))

                        expect(urlSession.urlRequest?.httpBody).toNot(beNil())
                    }

                    it("should send only one event") {
                        state.lastKnownLocation = createLocation()

                        _ = geoTracker?.process(event: createLocEvent(), state: state)

                        expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))

                        let jsonArray = urlSession.urlRequest?.httpBody?.ratPayload

                        expect(jsonArray).toNot(beNil())
                        expect(jsonArray?.count).to(equal(1))
                    }

                    func verifyAutomaticFields(json: [String: Any], expectedLtm: String, expectedTs1: Double) {
                        #if SWIFT_PACKAGE
                        let expectedAppName = "com.apple.dt.xctest.tool"
                        #else
                        let expectedAppName = "jp.co.rakuten.Host"
                        #endif
                        let expectedModel = UIDevice.current.modelIdentifier

                        expect(json[PayloadParameterKeys.etype] as? String).to(equal(RAnalyticsEvent.Name.geoLocation))

                        expect(json[PayloadParameterKeys.acc] as? Int64).to(equal(expectedAccountIdentifier))

                        expect(json[PayloadParameterKeys.aid] as? Int64).to(equal(expectedApplicationIdentifier))

                        expect(json[PayloadParameterKeys.Core.appVer] as? String).toNot(beEmpty())

                        expect(json[PayloadParameterKeys.Core.appName] as? String).to(equal(expectedAppName))

                        expect(json[PayloadParameterKeys.Core.ts1] as? Double).to(equal(expectedTs1))

                        expect(json[PayloadParameterKeys.Core.ver] as? String).to(equal(CoreHelpers.Constants.sdkVersion))

                        let mos = json[PayloadParameterKeys.Core.mos] as? String
                        expect(mos).toNot(beEmpty())
                        expect(mos?.hasPrefix("iOS")).to(beTrue())

                        expect(json[PayloadParameterKeys.Time.ltm] as? String).to(equal(expectedLtm))

                        expect(json[PayloadParameterKeys.TimeZone.tzo] as? Int).toNot(beNil())

                        expect(json[PayloadParameterKeys.Network.online] as? Bool).to(beTrue())

                        expect(json[PayloadParameterKeys.Orientation.mori] as? Int).to(equal(1))

                        expect(json[PayloadParameterKeys.Telephony.mnetw] as? Int).to(equal(1))

                        expect(json[PayloadParameterKeys.Telephony.mnetwd] as? Int).to(equal(1))

                        expect(json[PayloadParameterKeys.Device.model] as? String).to(equal(expectedModel))

                        expect(json[PayloadParameterKeys.Language.dln] as? String).to(equal(expectedLanguageCode))

                        expect(json[PayloadParameterKeys.Device.res] as? String).to(equal(expectedResolution))

                        expect(json[PayloadParameterKeys.UserAgent.ua] as? String).to(beNil())

                        expect(json[PayloadParameterKeys.Identifier.ckp] as? String).to(equal(expectedCkp))

                        expect(json[PayloadParameterKeys.Identifier.cka] as? String).to(equal(expectedCka))

                        expect(json[PayloadParameterKeys.Identifier.cks] as? String).to(equal(expectedSessionIdentifier))

                        expect(json[PayloadParameterKeys.Identifier.userid] as? String).to(equal(expectedUserIdentifier))

                        expect(json[PayloadParameterKeys.Identifier.easyid] as? String).to(equal(expectedEasyIdentifier))
                    }

                    func verifyLocation(json: [String: Any]) {
                        let location: [String: Any]! = json[PayloadParameterKeys.Location.loc] as? [String: Any]

                        expect(location).toNot(beNil())

                        expect(location[PayloadParameterKeys.Location.lat] as? CLLocationDegrees).to(equal(expectedLatitude))

                        expect(location[PayloadParameterKeys.Location.long] as? CLLocationDegrees).to(equal(expectedLongitude))

                        expect(location[PayloadParameterKeys.Location.accu] as? CLLocationAccuracy).to(equal(expectedAccuracy))

                        expect(location[PayloadParameterKeys.Location.tms] as? TimeInterval).to(equal(expectedTms*1000.0))

                        expect(location[PayloadParameterKeys.Location.speed] as? CLLocationSpeed).to(equal(expectedSpeed))

                        expect(location[PayloadParameterKeys.Location.speedAccuracy] as? CLLocationSpeedAccuracy).to(equal(expectedSpeedAccuracy))

                        expect(location[PayloadParameterKeys.Location.altitude] as? CLLocationDistance).to(equal(expectedAltitude))

                        expect(location[PayloadParameterKeys.Location.verticalAccuracy] as? CLLocationAccuracy).to(equal(expectedVerticalAccuracy))

                        expect(location[PayloadParameterKeys.Location.bearing] as? CLLocationDegrees).to(equal(expectedBearing))

                        expect(location[PayloadParameterKeys.Location.bearingAccuracy] as? CLLocationAccuracy).to(equal(expectedBearingAccuracy))
                    }

                    func verifyNonEmptyActionParameters(json: [String: Any]) {
                        let actionParametersProperties: [String: Any]! = json[PayloadParameterKeys.ActionParameters.actionParams] as? [String: Any]

                        expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.type] as? String).to(equal(expectedActionParamType))
                        expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.log] as? String).to(equal(expectedActionParamLog))
                        expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.identifier] as? String).to(equal(expectedActionParamId))
                        expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.duration] as? String).to(equal(expectedActionParamDuration))
                        expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.addLog] as? String).to(equal(expectedActionParamAddLog))
                    }

                    context("When loc event is sent without action parameters") {
                        context("When isAction is false") {
                            it("should send the expected RAT payload with nil action parameters") {
                                state.lastKnownLocation = createLocation()

                                _ = geoTracker?.process(event: createLocEvent(), state: state)

                                expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))

                                let json: [String: Any]! = urlSession.urlRequest?.httpBody?.ratPayload?.first

                                verifyAutomaticFields(json: json, expectedLtm: expectedLtm, expectedTs1: expectedTs1)
                                verifyLocation(json: json)

                                expect(json[PayloadParameterKeys.isAction] as? Bool).to(beFalse())

                            }
                        }

                        context("When isAction is true") {
                            it("should send the expected RAT payload without nil action parameters properties") {
                                state.lastKnownLocation = createLocation(isAction: true,
                                                                         actionParameters: GeoActionParameters())

                                _ = geoTracker?.process(event: createLocEvent(), state: state)

                                expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))

                                let json: [String: Any]! = urlSession.urlRequest?.httpBody?.ratPayload?.first

                                verifyAutomaticFields(json: json, expectedLtm: expectedLtm, expectedTs1: expectedTs1)
                                verifyLocation(json: json)

                                expect(json[PayloadParameterKeys.isAction] as? Bool).to(beTrue())

                                expect(json[PayloadParameterKeys.ActionParameters.actionParams]).to(beNil())
                            }
                        }
                    }

                    context("When loc event is sent with nil action parameters") {
                        context("When isAction is false") {
                            it("should send the expected RAT payload with nil action parameters properties") {
                                state.lastKnownLocation = createLocation(isAction: false,
                                                                         actionParameters: nilActionParameters)

                                _ = geoTracker?.process(event: createLocEvent(), state: state)

                                expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))

                                let json: [String: Any]! = urlSession.urlRequest?.httpBody?.ratPayload?.first

                                verifyAutomaticFields(json: json, expectedLtm: expectedLtm, expectedTs1: expectedTs1)
                                verifyLocation(json: json)

                                expect(json[PayloadParameterKeys.isAction] as? Bool).to(beFalse())

                            }
                        }

                        context("When isAction is true") {
                            it("should send the expected RAT payload with nil action parameters properties") {
                                state.lastKnownLocation = createLocation(isAction: true,
                                                                         actionParameters: nilActionParameters)

                                _ = geoTracker?.process(event: createLocEvent(), state: state)

                                expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))

                                let json: [String: Any]! = urlSession.urlRequest?.httpBody?.ratPayload?.first

                                verifyAutomaticFields(json: json, expectedLtm: expectedLtm, expectedTs1: expectedTs1)
                                verifyLocation(json: json)

                                expect(json[PayloadParameterKeys.isAction] as? Bool).to(beTrue())

                                expect(json[PayloadParameterKeys.ActionParameters.actionParams]).to(beNil())
                            }
                        }
                    }

                    context("When loc event is sent with action parameters") {
                        context("When isAction is false") {
                            it("should send the expected RAT payload with nil action parameters") {
                                state.lastKnownLocation = createLocation(isAction: false,
                                                                         actionParameters: nonEmptyActionParameters)

                                _ = geoTracker?.process(event: createLocEvent(), state: state)

                                expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))

                                let json: [String: Any]! = urlSession.urlRequest?.httpBody?.ratPayload?.first

                                verifyAutomaticFields(json: json, expectedLtm: expectedLtm, expectedTs1: expectedTs1)
                                verifyLocation(json: json)

                                expect(json[PayloadParameterKeys.isAction] as? Bool).to(beFalse())

                                expect(json[PayloadParameterKeys.ActionParameters.actionParams]).to(beNil())
                            }
                        }

                        context("When isAction is true") {
                            context("When all action parameters are present") {
                                it("should send the expected RAT payload with expected ation parameters") {
                                    state.lastKnownLocation = createLocation(isAction: true,
                                                                             actionParameters: nonEmptyActionParameters)

                                    _ = geoTracker?.process(event: createLocEvent(), state: state)

                                    expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))

                                    let json: [String: Any]! = urlSession.urlRequest?.httpBody?.ratPayload?.first

                                    verifyAutomaticFields(json: json, expectedLtm: expectedLtm, expectedTs1: expectedTs1)
                                    verifyLocation(json: json)

                                    expect(json[PayloadParameterKeys.isAction] as? Bool).to(beTrue())

                                    verifyNonEmptyActionParameters(json: json)
                                }
                            }

                            context("When only action type is present") {
                                it("should send the expected RAT payload with only action type") {
                                    let sentActionParameters = GeoActionParameters(actionType: expectedActionParamType,
                                                                                   actionLog: nil,
                                                                                   actionId: nil,
                                                                                   actionDuration: nil,
                                                                                   additionalLog: nil)

                                    state.lastKnownLocation = createLocation(isAction: true,
                                                                             actionParameters: sentActionParameters)

                                    _ = geoTracker?.process(event: createLocEvent(), state: state)

                                    expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))

                                    let json: [String: Any]! = urlSession.urlRequest?.httpBody?.ratPayload?.first

                                    verifyAutomaticFields(json: json, expectedLtm: expectedLtm, expectedTs1: expectedTs1)
                                    verifyLocation(json: json)

                                    let actionParametersProperties: [String: Any]! = json[PayloadParameterKeys.ActionParameters.actionParams] as? [String: Any]
                                    expect(json[PayloadParameterKeys.isAction] as? Bool).to(beTrue())

                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.type] as? String).to(equal(expectedActionParamType))
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.log] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.identifier] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.duration] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.addLog] as? String).to(beNil())
                                }
                            }

                            context("When only action log is present") {
                                it("should send the expected RAT payload with only action log") {
                                    let sentActionParameters = GeoActionParameters(actionType: nil,
                                                                                   actionLog: expectedActionParamLog,
                                                                                   actionId: nil,
                                                                                   actionDuration: nil,
                                                                                   additionalLog: nil)

                                    state.lastKnownLocation = createLocation(isAction: true,
                                                                             actionParameters: sentActionParameters)

                                    _ = geoTracker?.process(event: createLocEvent(), state: state)

                                    expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))

                                    let json: [String: Any]! = urlSession.urlRequest?.httpBody?.ratPayload?.first

                                    verifyAutomaticFields(json: json, expectedLtm: expectedLtm, expectedTs1: expectedTs1)
                                    verifyLocation(json: json)

                                    let actionParametersProperties: [String: Any]! = json[PayloadParameterKeys.ActionParameters.actionParams] as? [String: Any]
                                    expect(json[PayloadParameterKeys.isAction] as? Bool).to(beTrue())

                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.type] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.log] as? String).to(equal(expectedActionParamLog))
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.identifier] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.duration] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.addLog] as? String).to(beNil())
                                }
                            }

                            context("When only action id is present") {
                                it("should send the expected RAT payload with only action id") {
                                    let sentActionParameters = GeoActionParameters(actionType: nil,
                                                                                   actionLog: nil,
                                                                                   actionId: expectedActionParamId,
                                                                                   actionDuration: nil,
                                                                                   additionalLog: nil)

                                    state.lastKnownLocation = createLocation(isAction: true,
                                                                             actionParameters: sentActionParameters)

                                    _ = geoTracker?.process(event: createLocEvent(), state: state)

                                    expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))

                                    let json: [String: Any]! = urlSession.urlRequest?.httpBody?.ratPayload?.first

                                    verifyAutomaticFields(json: json, expectedLtm: expectedLtm, expectedTs1: expectedTs1)
                                    verifyLocation(json: json)

                                    let actionParametersProperties: [String: Any]! = json[PayloadParameterKeys.ActionParameters.actionParams] as? [String: Any]
                                    expect(json[PayloadParameterKeys.isAction] as? Bool).to(beTrue())

                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.type] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.log] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.identifier] as? String).to(equal(expectedActionParamId))
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.duration] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.addLog] as? String).to(beNil())
                                }
                            }

                            context("When only action duration is present") {
                                it("should send the expected RAT payload with only action duration") {
                                    let sentActionParameters = GeoActionParameters(actionType: nil,
                                                                                   actionLog: nil,
                                                                                   actionId: nil,
                                                                                   actionDuration: expectedActionParamDuration,
                                                                                   additionalLog: nil)

                                    state.lastKnownLocation = createLocation(isAction: true,
                                                                             actionParameters: sentActionParameters)

                                    _ = geoTracker?.process(event: createLocEvent(), state: state)

                                    expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))

                                    let json: [String: Any]! = urlSession.urlRequest?.httpBody?.ratPayload?.first

                                    verifyAutomaticFields(json: json, expectedLtm: expectedLtm, expectedTs1: expectedTs1)
                                    verifyLocation(json: json)

                                    let actionParametersProperties: [String: Any]! = json[PayloadParameterKeys.ActionParameters.actionParams] as? [String: Any]
                                    expect(json[PayloadParameterKeys.isAction] as? Bool).to(beTrue())

                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.type] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.log] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.identifier] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.duration] as? String).to(equal(expectedActionParamDuration))
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.addLog] as? String).to(beNil())
                                }
                            }

                            context("When only action add log is present") {
                                it("should send the expected RAT payload with only action add log") {
                                    let sentActionParameters = GeoActionParameters(actionType: nil,
                                                                                   actionLog: nil,
                                                                                   actionId: nil,
                                                                                   actionDuration: nil,
                                                                                   additionalLog: expectedActionParamAddLog)

                                    state.lastKnownLocation = createLocation(isAction: true,
                                                                             actionParameters: sentActionParameters)

                                    _ = geoTracker?.process(event: createLocEvent(), state: state)

                                    expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))

                                    let json: [String: Any]! = urlSession.urlRequest?.httpBody?.ratPayload?.first

                                    verifyAutomaticFields(json: json, expectedLtm: expectedLtm, expectedTs1: expectedTs1)
                                    verifyLocation(json: json)

                                    let actionParametersProperties: [String: Any]! = json[PayloadParameterKeys.ActionParameters.actionParams] as? [String: Any]
                                    expect(json[PayloadParameterKeys.isAction] as? Bool).to(beTrue())

                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.type] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.log] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.identifier] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.duration] as? String).to(beNil())
                                    expect(actionParametersProperties[PayloadParameterKeys.ActionParameters.addLog] as? String).to(equal(expectedActionParamAddLog))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
// swiftlint:enable line_length

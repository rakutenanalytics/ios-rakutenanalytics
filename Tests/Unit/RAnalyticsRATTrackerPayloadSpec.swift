// swiftlint:disable line_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import Quick
import Nimble
import CoreTelephony
import SQLite3
import UIKit.UIDevice
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsRATTrackerPayloadSpec

class RAnalyticsRATTrackerPayloadSpec: QuickSpec {
    override func spec() {
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

            beforeEach {
                let databaseTableName = "testTableName_RAnalyticsRATTrackerSpec"
                databaseConnection = DatabaseTestUtils.openRegularConnection()!
                database = DatabaseTestUtils.mkDatabase(connection: databaseConnection)
                dependenciesContainer.bundle = bundle
                dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database, tableName: databaseTableName)
                dependenciesContainer.session = SwityURLSessionMock()
                dependenciesContainer.deviceCapability = DeviceMock()
                dependenciesContainer.telephonyNetworkInfoHandler = TelephonyNetworkInfoMock()
                dependenciesContainer.analyticsStatusBarOrientationGetter = ApplicationMock(.portrait)

                ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                ratTracker.set(batchingDelay: 0)
                ratTracker.reachabilityStatus = nil

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

                context("Language Code") {
                    it("should set a non-nil dln") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let dln = payload?["dln"] as? String
                        expect(dln).to(equal(bundle.languageCode as? String))
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

                    it("should set a non-nil accu") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let accu = loc?["accu"] as? NSNumber
                        expect(accu?.intValue).toNot(beNil())
                    }

                    it("should set a non-nil altitude") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let altitude = loc?["altitude"] as? NSNumber
                        expect(altitude?.intValue).toNot(beNil())
                    }

                    it("should set a non-nil tms") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let tms = loc?["tms"] as? NSNumber
                        expect(tms?.intValue).toNot(beNil())
                    }

                    it("should set a non-nil lat") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let lat = loc?["lat"] as? NSNumber
                        expect(lat?.intValue).toNot(beNil())
                    }

                    it("should set a non-nil long") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let long = loc?["long"] as? NSNumber
                        expect(long?.intValue).toNot(beNil())
                    }

                    it("should set a non-nil speed") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let loc = payload?["loc"] as? [String: Any]

                        let speed = loc?["speed"] as? NSNumber
                        expect(speed?.intValue).toNot(beNil())
                    }
                }

                context("Network status") {
                    context("When reachabilityStatus is not set") {
                        it("should not set online") {
                            var payload: [String: Any]?

                            expecter.ratTracker.reachabilityStatus = nil

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

                            expecter.ratTracker.reachabilityStatus = NSNumber(value: RATReachabilityStatus.offline.rawValue)

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

                            expecter.ratTracker.reachabilityStatus = NSNumber(value: RATReachabilityStatus.wwan.rawValue)

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

                            expecter.ratTracker.reachabilityStatus = NSNumber(value: RATReachabilityStatus.wifi.rawValue)

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
                    it("should set cks to CA7A88AB-82FE-40C9-A836-B1B3455DECAB") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())

                        let cks = payload?["cks"] as? String
                        expect(cks).to(equal("CA7A88AB-82FE-40C9-A836-B1B3455DECAB"))
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

                context("mcn and mcnd") {
                    context("When there is no carrier") {
                        context("And the connection is offline") {
                            it("should process an event without mcn and mcnd ") {
                                ratTracker.reachabilityStatus = NSNumber(value: RATReachabilityStatus.offline.rawValue)

                                verifyEmptyMcnAndMcnd()
                            }
                        }

                        context("And the connection is WWAN") {
                            it("should process an event without mcn and mcnd ") {
                                ratTracker.reachabilityStatus = NSNumber(value: RATReachabilityStatus.wwan.rawValue)

                                verifyEmptyMcnAndMcnd()
                            }
                        }

                        context("And the connection is Wifi") {
                            it("should process an event without mcn and mcnd ") {
                                ratTracker.reachabilityStatus = NSNumber(value: RATReachabilityStatus.wifi.rawValue)

                                verifyEmptyMcnAndMcnd()
                            }
                        }

                        func verifyEmptyMcnAndMcnd() {
                            var payload: [String: Any]?

                            let primaryCarrier = CarrierMock()
                            primaryCarrier.carrierName = nil
                            primaryCarrier.mobileNetworkCode = nil

                            let secondaryCarrier = CarrierMock()
                            secondaryCarrier.carrierName = nil
                            secondaryCarrier.mobileNetworkCode = nil

                            let telephonyNetworkInfo = dependenciesContainer.telephonyNetworkInfoHandler as? TelephonyNetworkInfoMock
                            telephonyNetworkInfo?.subscribers = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryCarrier,
                                                                 TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryCarrier]
                            telephonyNetworkInfo?.serviceCurrentRadioAccessTechnology = nil

                            expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(payload?["mcn"] as? String).to(equal(""))
                            expect(payload?["mcnd"] as? String).to(equal(""))
                        }
                    }

                    context("When there is only one carrier") {
                        it("should process an event with mcn and no mcnd") {
                            let expectedMcnValue = "Rakuten Mobile"

                            var payload: [String: Any]?

                            let primaryCarrier = CarrierMock()
                            primaryCarrier.carrierName = "Rakuten Mobile"
                            primaryCarrier.mobileNetworkCode = "12345"

                            let secondaryCarrier = CarrierMock()
                            secondaryCarrier.carrierName = nil
                            secondaryCarrier.mobileNetworkCode = nil

                            let telephonyNetworkInfo = dependenciesContainer.telephonyNetworkInfoHandler as? TelephonyNetworkInfoMock
                            telephonyNetworkInfo?.subscribers = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryCarrier,
                                                                 TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryCarrier]

                            telephonyNetworkInfo?.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: CTRadioAccessTechnologyLTE,
                                                                                         TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: ""]

                            expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(payload?["mcn"] as? String).to(equal(expectedMcnValue))
                            expect(payload?["mcnd"] as? String).to(equal(""))
                        }
                    }

                    context("when there are two carriers") {
                        it("should process an event with mcn and mcnd") {
                            ratTracker.reachabilityStatus = NSNumber(value: RATReachabilityStatus.wifi.rawValue)

                            let expectedMcnValue = "Rakuten Mobile"
                            let expectedMcndValue = "Ubigi"

                            var payload: [String: Any]?

                            let primaryCarrier = CarrierMock()
                            primaryCarrier.carrierName = "Rakuten Mobile"
                            primaryCarrier.mobileNetworkCode = "12345"

                            let secondaryCarrier = CarrierMock()
                            secondaryCarrier.carrierName = "Ubigi"
                            secondaryCarrier.mobileNetworkCode = "67890"

                            let telephonyNetworkInfo = dependenciesContainer.telephonyNetworkInfoHandler as? TelephonyNetworkInfoMock
                            telephonyNetworkInfo?.subscribers = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryCarrier,
                                                                 TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryCarrier]

                            telephonyNetworkInfo?.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: CTRadioAccessTechnologyLTE,
                                                                                         TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: CTRadioAccessTechnologyLTE]

                            expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                                payload = $0.first
                            }
                            expect(payload).toEventuallyNot(beNil())
                            expect(payload?["mcn"] as? String).to(equal(expectedMcnValue))
                            expect(payload?["mcnd"] as? String).to(equal(expectedMcndValue))
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

                        ratTracker.reachabilityStatus = NSNumber(value: reachabilityStatus.rawValue)

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

                context("userid") {
                    it("should set the userid") {
                        var payload: [String: Any]?

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(payload?["userid"] as? String).to(equal("userId"))
                    }

                    it("should not set the userid when the state's userIdentifier is not set") {
                        var payload: [String: Any]?

                        let state = RAnalyticsState(sessionIdentifier: "CA7A88AB-82FE-40C9-A836-B1B3455DECAB",
                                                    deviceIdentifier: "deviceId")
                        state.userIdentifier = nil

                        expecter.expectEvent(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(payload?["userid"] as? String).to(beNil())
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

                        let state = RAnalyticsState(sessionIdentifier: "CA7A88AB-82FE-40C9-A836-B1B3455DECAB",
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

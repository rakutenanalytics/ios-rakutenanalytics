// swiftlint:disable line_length

import Quick
import Nimble
import CoreTelephony
import SQLite3
@testable import RAnalytics

// MARK: - RAnalyticsRATTrackerPayloadSpec

class RAnalyticsRATTrackerPayloadSpec: QuickSpec {
    override func spec() {
        describe("RAnalyticsRATTracker") {
            let expecter = RAnalyticsRATExpecter()
            var databaseConnection: SQlite3Pointer!
            var database: RAnalyticsDatabase!
            let dependenciesContainer = SimpleContainerMock()
            var ratTracker: RAnalyticsRATTracker!

            beforeEach {
                let databaseTableName = "testTableName_RAnalyticsRATTrackerSpec"
                databaseConnection = DatabaseTestUtils.openRegularConnection()!
                database = DatabaseTestUtils.mkDatabase(connection: databaseConnection)
                let bundle = BundleMock()
                bundle.mutableEndpointAddress = URL(string: "https://endpoint.co.jp/")!
                dependenciesContainer.bundle = bundle
                dependenciesContainer.databaseConfiguration = DatabaseConfiguration(database: database, tableName: databaseTableName)
                dependenciesContainer.session = SwityURLSessionMock()
                dependenciesContainer.deviceCapability = DeviceMock()
                dependenciesContainer.telephonyNetworkInfoHandler = TelephonyNetworkInfoMock()
                dependenciesContainer.analyticsStatusBarOrientationGetter = ApplicationMock(.portrait)

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

                context("mcn and mcnd") {
                    it("should process an event without mcn and mcnd when there is no carrier") {
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

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(payload?["mcn"] as? String).to(equal(""))
                        expect(payload?["mcnd"] as? String).to(equal(""))
                    }

                    it("should process an event with mcn and no mcnd when there is only one carrier") {
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

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(payload?["mcn"] as? String).to(equal("Rakuten Mobile"))
                        expect(payload?["mcnd"] as? String).to(equal(""))
                    }

                    it("should process an event with mcn and mcnd when there are two carriers") {
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

                        expecter.expectEvent(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                            payload = $0.first
                        }
                        expect(payload).toEventuallyNot(beNil())
                        expect(payload?["mcn"] as? String).to(equal("Rakuten Mobile"))
                        expect(payload?["mcnd"] as? String).to(equal("Ubigi"))
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

                        let sender = ratTracker.perform(Selector(("sender")))?.takeUnretainedValue() as? RAnalyticsSender

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

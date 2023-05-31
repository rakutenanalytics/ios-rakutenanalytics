// swiftlint:disable line_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import Quick
import Nimble
import CoreTelephony
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - TelephonyHandlerSpec

final class TelephonyHandlerSpec: QuickSpec {
    override func spec() {
        describe("TelephonyHandler") {
            let telephonyNetworkInfo = TelephonyNetworkInfoMock()

            let telephonyHandler = TelephonyHandler(telephonyNetworkInfo: telephonyNetworkInfo,
                                                    notificationCenter: NotificationCenter.default)

            telephonyHandler.reachabilityStatus = NSNumber(value: 1)

            afterEach {
                telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = nil
            }

            describe("mcn, mcnd, simopn, simop") {
                it(#"should return mcn == "", mcnd == "", simopn == "", simop == "" when there are no carriers"#) {
                    telephonyNetworkInfo.subscribers = nil
                    telephonyNetworkInfo.safeDataServiceIdentifier = nil

                    expect(telephonyHandler.mcn).to(beEmpty())
                    expect(telephonyHandler.mcnd).to(beEmpty())
                    expect(telephonyHandler.simopn).to(beEmpty())
                    expect(telephonyHandler.simop).to(beEmpty())
                }

                context("when there is only one carrier (Physical SIM is primary)") {
                    it(#"should return mcn == Carrier1, mcnd == "", simopn == Carrier1, simop == 23420 when the Physical SIM radio is not empty"#) {
                        let simop = primaryCarrier.mobileCountryCode.combine(with: primaryCarrier.mobileNetworkCode)
                        telephonyNetworkInfo.subscribers = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryCarrier]
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.primaryCarrierKey

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: CTRadioAccessTechnologyLTE,
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: ""]

                        expect(telephonyHandler.mcn).to(equal(primaryCarrier.carrierName))
                        expect(telephonyHandler.mcnd).to(beEmpty())
                        expect(telephonyHandler.simopn).to(equal(primaryCarrier.carrierName))
                        expect(telephonyHandler.simop).to(equal(simop))
                    }

                    it(#"should return mcn == "", mcnd == "", simopn == "", simop == "" when the Physical SIM radio is empty"#) {
                        telephonyNetworkInfo.subscribers = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryCarrier]
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.primaryCarrierKey

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: "",
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: ""]

                        expect(telephonyHandler.mcn).to(beEmpty())
                        expect(telephonyHandler.mcnd).to(beEmpty())
                        expect(telephonyHandler.simopn).to(beEmpty())
                        expect(telephonyHandler.simop).to(beEmpty())
                    }
                }

                context("when there is only one carrier (eSIM is primary)") {
                    it(#"should return mcn == Carrier2, mcnd == "", simopn == Carrier2, simop == 20825  when the eSIM radio is not empty"#) {
                        let simop = secondaryCarrier.mobileCountryCode.combine(with: secondaryCarrier.mobileNetworkCode)

                        telephonyNetworkInfo.subscribers = [TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryCarrier]
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.secondaryCarrierKey

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: "",
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: CTRadioAccessTechnologyLTE]

                        expect(telephonyHandler.mcn).to(equal(secondaryCarrier.carrierName))
                        expect(telephonyHandler.mcnd).to(beEmpty())
                        expect(telephonyHandler.simopn).to(equal(secondaryCarrier.carrierName))
                        expect(telephonyHandler.simop).to(equal(simop))
                    }

                    it(#"should return mcn == "", mcnd == "", simopn == "", simop == "" when the eSIM radio is empty"#) {
                        telephonyNetworkInfo.subscribers = [TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryCarrier]
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.secondaryCarrierKey

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: "",
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: ""]

                        expect(telephonyHandler.mcn).to(beEmpty())
                        expect(telephonyHandler.mcnd).to(beEmpty())
                        expect(telephonyHandler.simopn).to(beEmpty())
                        expect(telephonyHandler.simop).to(beEmpty())
                    }
                }

                context("when the primary carrier is Carrier1 (Physical SIM), the secondary carrier is Carrier 2 (eSIM)") {
                    it(#"should return mcn == "", mcnd == "", simopn == "", simop == "" when the radios are empty"#) {
                        telephonyNetworkInfo.subscribers = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryCarrier,
                                                            TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryCarrier]
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.primaryCarrierKey

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: "",
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: ""]

                        expect(telephonyHandler.mcn).to(beEmpty())
                        expect(telephonyHandler.mcnd).to(beEmpty())
                        expect(telephonyHandler.simopn).to(beEmpty())
                        expect(telephonyHandler.simop).to(beEmpty())
                    }

                    it(#"should return mcn == Carrier1, mcnd == "", simopn == Carrier1, simop == 23420  when only the Physical SIM radio is not empty"#) {
                        let simop = primaryCarrier.mobileCountryCode.combine(with: primaryCarrier.mobileNetworkCode)
                        telephonyNetworkInfo.subscribers = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryCarrier,
                                                            TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryCarrier]
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.primaryCarrierKey

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: CTRadioAccessTechnologyLTE,
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: ""]

                        expect(telephonyHandler.mcn).to(equal(primaryCarrier.carrierName))
                        expect(telephonyHandler.mcnd).to(beEmpty())
                        expect(telephonyHandler.simopn).to(equal(primaryCarrier.carrierName))
                        expect(telephonyHandler.simop).to(equal(simop))
                    }

                    it(#"should return mcn == "", mcnd == Carrier2, simopn == "", simop == "" when only the eSIM radio is not empty"#) {
                        telephonyNetworkInfo.subscribers = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryCarrier,
                                                            TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryCarrier]
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.primaryCarrierKey

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: "",
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: CTRadioAccessTechnologyLTE]

                        expect(telephonyHandler.mcn).to(beEmpty())
                        expect(telephonyHandler.mcnd).to(equal(secondaryCarrier.carrierName))
                        expect(telephonyHandler.simopn).to(beEmpty())
                        expect(telephonyHandler.simop).to(beEmpty())
                    }

                    it("should return mcn == Carrier1, mcnd == Carrier2, simopn == Carrier1, simop == 23420 when the radios are not empty") {
                        let simop = primaryCarrier.mobileCountryCode.combine(with: primaryCarrier.mobileNetworkCode)
                        telephonyNetworkInfo.subscribers = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryCarrier,
                                                            TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryCarrier]
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.primaryCarrierKey

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: CTRadioAccessTechnologyLTE,
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: CTRadioAccessTechnologyLTE]

                        expect(telephonyHandler.mcn).to(equal(primaryCarrier.carrierName))
                        expect(telephonyHandler.mcnd).to(equal(secondaryCarrier.carrierName))
                        expect(telephonyHandler.simopn).to(equal(primaryCarrier.carrierName))
                        expect(telephonyHandler.simop).to(equal(simop))
                    }
                }

                context("when the primary carrier is Carrier2 (eSIM), the secondary carrier is Carrier1 (Physical SIM)") {
                    it(#"should return mcn == "", mcnd == "", simopn == "", simop == "" when the radios are empty"#) {
                        telephonyNetworkInfo.subscribers = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryCarrier,
                                                            TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryCarrier]
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.secondaryCarrierKey

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: "",
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: ""]

                        expect(telephonyHandler.mcn).to(beEmpty())
                        expect(telephonyHandler.mcnd).to(beEmpty())
                        expect(telephonyHandler.simopn).to(beEmpty())
                        expect(telephonyHandler.simop).to(beEmpty())
                    }

                    it(#"should return mcn == "", mcnd == Carrier1, simopn == "", simop == "" when the eSIM radio is empty"#) {
                        telephonyNetworkInfo.subscribers = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryCarrier,
                                                            TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryCarrier]
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.secondaryCarrierKey

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: CTRadioAccessTechnologyLTE,
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: ""]

                        expect(telephonyHandler.mcn).to(beEmpty())
                        expect(telephonyHandler.mcnd).to(equal(primaryCarrier.carrierName))
                        expect(telephonyHandler.simopn).to(beEmpty())
                        expect(telephonyHandler.simop).to(beEmpty())
                    }

                    it(#"should return mcn == Carrier2, mcnd == "", simopn == Carrier2, simop == 20825 when the Physical SIM radio is empty"#) {
                        let simop = secondaryCarrier.mobileCountryCode.combine(with: secondaryCarrier.mobileNetworkCode)

                        telephonyNetworkInfo.subscribers = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryCarrier,
                                                            TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryCarrier]
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.secondaryCarrierKey

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: "",
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: CTRadioAccessTechnologyLTE]

                        expect(telephonyHandler.mcn).to(equal(secondaryCarrier.carrierName))
                        expect(telephonyHandler.mcnd).to(beEmpty())
                        expect(telephonyHandler.simopn).to(equal(secondaryCarrier.carrierName))
                        expect(telephonyHandler.simop).to(equal(simop))
                    }

                    it("should return mcn == Carrier2, mcnd == Carrier1, simopn == Carrier2, simop == 20825 when the radios are not empty") {
                        let simop = secondaryCarrier.mobileCountryCode.combine(with: secondaryCarrier.mobileNetworkCode)

                        telephonyNetworkInfo.subscribers = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryCarrier,
                                                            TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryCarrier]
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.secondaryCarrierKey

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: CTRadioAccessTechnologyLTE,
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: CTRadioAccessTechnologyLTE]

                        expect(telephonyHandler.mcn).to(equal(secondaryCarrier.carrierName))
                        expect(telephonyHandler.mcnd).to(equal(primaryCarrier.carrierName))
                        expect(telephonyHandler.simopn).to(equal(secondaryCarrier.carrierName))
                        expect(telephonyHandler.simop).to(equal(simop))
                    }
                }
            }

            describe("mnetw and mnetwd") {
                it("should return mnetw == nil, mnetwd == nil when there are no radios") {
                    telephonyNetworkInfo.safeDataServiceIdentifier = nil
                    telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = nil

                    expect(telephonyHandler.mnetw).to(beNil())
                    expect(telephonyHandler.mnetwd).to(beNil())
                }

                it("should return mnetw == 3, mnetwd == nil when there are only one radio (Physical SIM is primary)") {
                    telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.primaryCarrierKey
                    telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: CTRadioAccessTechnologyEdge]

                    expect(telephonyHandler.mnetw?.intValue).to(equal(CTRadioAccessTechnologyEdge.networkType.rawValue))
                    expect(telephonyHandler.mnetwd).to(beNil())
                }

                it("should return mnetw == 4, mnetwd == nil when there are only one radio (Physical SIM is primary)") {
                    telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.primaryCarrierKey
                    telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: CTRadioAccessTechnologyLTE]

                    expect(telephonyHandler.mnetw?.intValue).to(equal(CTRadioAccessTechnologyLTE.networkType.rawValue))
                    expect(telephonyHandler.mnetwd).to(beNil())
                }

                if #available(iOS 14.1, *) {
                    it("should return mnetw == 5, mnetwd == nil when there are only one radio (Physical SIM is primary)") {
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.primaryCarrierKey
                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: CTRadioAccessTechnologyNR]

                        expect(telephonyHandler.mnetw?.intValue).to(equal(CTRadioAccessTechnologyNR.networkType.rawValue))
                        expect(telephonyHandler.mnetwd).to(beNil())
                    }
                }

                it("should return mnetw == 3, mnetwd == nil when there are only one radio (eSIM is primary)") {
                    telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.secondaryCarrierKey
                    telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: CTRadioAccessTechnologyEdge]

                    expect(telephonyHandler.mnetw?.intValue).to(equal(CTRadioAccessTechnologyEdge.networkType.rawValue))
                    expect(telephonyHandler.mnetwd).to(beNil())
                }

                it("should return mnetw == 4, mnetwd == nil when there are only one radio (eSIM is primary)") {
                    telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.secondaryCarrierKey
                    telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: CTRadioAccessTechnologyLTE]

                    expect(telephonyHandler.mnetw?.intValue).to(equal(CTRadioAccessTechnologyLTE.networkType.rawValue))
                    expect(telephonyHandler.mnetwd).to(beNil())
                }

                if #available(iOS 14.1, *) {
                    it("should return mnetw == 5, mnetwd == nil when there are only one radio (eSIM is primary)") {
                        telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.secondaryCarrierKey
                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: CTRadioAccessTechnologyNR]

                        expect(telephonyHandler.mnetw?.intValue).to(equal(CTRadioAccessTechnologyNR.networkType.rawValue))
                        expect(telephonyHandler.mnetwd).to(beNil())
                    }
                }

                context("Physical SIM Card is primary") {
                    it("should return mnetw == nil, mnetwd == nil when the primary radio is empty, the secondary radio is empty") {
                        verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: "", secondaryRadio: "")
                    }

                    it("should return mnetw == 3, mnetwd == 3 when the primary radio is Edge, the secondary radio is Edge") {
                        verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyEdge)
                    }

                    it("should return mnetw == 3, mnetwd == 4 when the primary radio is Edge, the secondary radio is LTE") {
                        verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyLTE)
                    }

                    if #available(iOS 14.1, *) {
                        it("should return mnetw == 3, mnetwd == 5 when the primary radio is Edge, the secondary radio is 5G") {
                            verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyNR)
                        }
                    }

                    it("should return mnetw == 4, mnetwd == 3 when the primary radio is LTE, the secondary radio is Edge") {
                        verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyEdge)
                    }

                    it("should return mnetw == 4, mnetwd == 4 when the primary radio is LTE, the secondary radio is Edge") {
                        verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyLTE)
                    }

                    if #available(iOS 14.1, *) {
                        it("should return mnetw == 4, mnetwd == 5 when the primary radio is LTE, the secondary radio is 5G") {
                            verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyNR)
                        }

                        it("should return mnetw == 5, mnetwd == 3 when the primary radio is 5G, the secondary radio is Edge") {
                            verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyEdge)
                        }

                        it("should return mnetw == 5, mnetwd == 4 when the primary radio is 5G, the secondary radio is LTE") {
                            verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyLTE)
                        }

                        it("should return mnetw == 5, mnetwd == 5 when the primary radio is 5G, the secondary radio is 5G") {
                            verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyNR)
                        }
                    }

                    func verify(dataServiceIdentifier: String, primaryRadio: String, secondaryRadio: String) {
                        telephonyNetworkInfo.safeDataServiceIdentifier = dataServiceIdentifier

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryRadio,
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryRadio]

                        if primaryRadio.isEmpty {
                            expect(telephonyHandler.mnetw).to(beNil())

                        } else {
                            expect(telephonyHandler.mnetw?.intValue).to(equal(primaryRadio.networkType.rawValue))
                        }

                        if secondaryRadio.isEmpty {
                            expect(telephonyHandler.mnetwd).to(beNil())

                        } else {
                            expect(telephonyHandler.mnetwd?.intValue).to(equal(secondaryRadio.networkType.rawValue))
                        }
                    }
                }

                context("eSIM Card is primary") {
                    it("should return mnetw == nil, mnetwd == nil when the primary radio is empty, the secondary radio is empty") {
                        verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: "", secondaryRadio: "")
                    }

                    it("should return mnetw == 3, mnetwd == 3 when the primary radio is Edge, the secondary radio is Edge") {
                        verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyEdge)
                    }

                    it("should return mnetw == 4, mnetwd == 3 when the primary radio is Edge, the secondary radio is LTE") {
                        verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyLTE)
                    }

                    if #available(iOS 14.1, *) {
                        it("should return mnetw == 5, mnetwd == 3 when the primary radio is Edge, the secondary radio is 5G") {
                            verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyNR)
                        }
                    }

                    it("should return mnetw == 3, mnetwd == 4 when the primary radio is LTE, the secondary radio is Edge") {
                        verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyEdge)
                    }

                    it("should return mnetw == 4, mnetwd == 4 when the primary radio is LTE, the secondary radio is LTE") {
                        verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyLTE)
                    }

                    if #available(iOS 14.1, *) {
                        it("should return mnetw == 5, mnetwd == 4 when the primary radio is LTE, the secondary radio is 5G") {
                            verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyNR)
                        }

                        it("should return mnetw == 3, mnetwd == 5 when the primary radio is 5G, the secondary radio is Edge") {
                            verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyEdge)
                        }

                        it("should return mnetw == 4, mnetwd == 5 when the primary radio is 5G, the secondary radio is LTE") {
                            verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyLTE)
                        }

                        it("should return mnetw == 5, mnetwd == 5 when the primary radio is 5G, the secondary radio is 5G") {
                            verify(dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyNR)
                        }
                    }

                    func verify(dataServiceIdentifier: String, primaryRadio: String, secondaryRadio: String) {
                        telephonyNetworkInfo.safeDataServiceIdentifier = dataServiceIdentifier

                        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryRadio,
                                                                                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryRadio]

                        if primaryRadio.isEmpty {
                            expect(telephonyHandler.mnetw).to(beNil())

                        } else {
                            expect(telephonyHandler.mnetw?.intValue).to(equal(secondaryRadio.networkType.rawValue))
                        }

                        if secondaryRadio.isEmpty {
                            expect(telephonyHandler.mnetwd).to(beNil())

                        } else {
                            expect(telephonyHandler.mnetwd?.intValue).to(equal(primaryRadio.networkType.rawValue))
                        }
                    }
                }
            }
        }
    }
}

// swiftlint:enable line_length
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length

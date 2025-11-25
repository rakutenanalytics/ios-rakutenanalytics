// swiftlint:disable line_length

import Quick
import Nimble
import CoreTelephony
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - TelephonyHandlerSpec

final class TelephonyHandlerSpec: QuickSpec {
    override class func spec() {
        describe("TelephonyHandler") {
            let telephonyNetworkInfo = TelephonyNetworkInfoMock()
            let userStorageHandler = UserDefaultsMock([:])

            let telephonyHandler = TelephonyHandler(telephonyNetworkInfo: telephonyNetworkInfo,
                                                    notificationCenter: NotificationCenter.default,
                                                    userStorageHandler: userStorageHandler)

            telephonyHandler.reachabilityStatus = NSNumber(value: 1)

            afterEach {
                telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = nil
                telephonyHandler.mcn = nil
                telephonyHandler.mcnd = nil
                userStorageHandler.dictionary?.removeAll()
            }

            describe("Mobile Carrier Name - Primary") {
                context("when setting mcn") {
                    it("should store the value in user storage") {
                        let carrierName = "Rakuten Mobile"
                        telephonyHandler.mcn = carrierName
                        
                        expect(userStorageHandler.object(forKey: UserDefaultsKeys.carrierPrimaryNameKey) as? String).to(equal(carrierName))
                        expect(telephonyHandler.mcn).to(equal(carrierName))
                    }
                    
                    it("should remove the value from user storage when set to nil") {
                        telephonyHandler.mcn = "Rakuten Mobile"
                        expect(userStorageHandler.object(forKey: UserDefaultsKeys.carrierPrimaryNameKey)).toNot(beNil())
                        
                        telephonyHandler.mcn = nil
                        expect(userStorageHandler.object(forKey: UserDefaultsKeys.carrierPrimaryNameKey)).to(beNil())
                        expect(telephonyHandler.mcn).to(beNil())
                    }
                    
                    it("should handle empty string") {
                        telephonyHandler.mcn = ""
                        
                        expect(userStorageHandler.object(forKey: UserDefaultsKeys.carrierPrimaryNameKey) as? String).to(equal(""))
                        expect(telephonyHandler.mcn).to(equal(""))
                    }
                }
            }

            describe("Mobile Carrier Name - Dual/Secondary") {
                context("when setting mcnd") {
                    it("should store the value in user storage") {
                        let carrierName = "NTT Docomo"
                        telephonyHandler.mcnd = carrierName
                        
                        expect(userStorageHandler.object(forKey: UserDefaultsKeys.carrierSecondaryNameKey) as? String).to(equal(carrierName))
                        expect(telephonyHandler.mcnd).to(equal(carrierName))
                    }
                    
                    it("should remove the value from user storage when set to nil") {
                        telephonyHandler.mcnd = "NTT Docomo"
                        expect(userStorageHandler.object(forKey: UserDefaultsKeys.carrierSecondaryNameKey)).toNot(beNil())
                        
                        telephonyHandler.mcnd = nil
                        expect(userStorageHandler.object(forKey: UserDefaultsKeys.carrierSecondaryNameKey)).to(beNil())
                        expect(telephonyHandler.mcnd).to(beNil())
                    }
                    
                    it("should handle empty string") {
                        telephonyHandler.mcnd = ""
                        
                        expect(userStorageHandler.object(forKey: UserDefaultsKeys.carrierSecondaryNameKey) as? String).to(equal(""))
                        expect(telephonyHandler.mcnd).to(equal(""))
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

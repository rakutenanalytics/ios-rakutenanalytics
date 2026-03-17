// swiftlint:disable line_length

import Testing
import CoreTelephony
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - TelephonyHandlerTests

@Suite("TelephonyHandler")
struct TelephonyHandlerTests {
    let telephonyNetworkInfo = TelephonyNetworkInfoMock()
    let userStorageHandler = UserDefaultsMock([:])
    var telephonyHandler: TelephonyHandler!
    
    mutating func setUp() {
        telephonyHandler = TelephonyHandler(telephonyNetworkInfo: telephonyNetworkInfo, notificationCenter: NotificationCenter.default, userStorageHandler: userStorageHandler)
        telephonyHandler.reachabilityStatus = NSNumber(value: 1)
    }
    
    mutating func tearDown() {
        telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = nil
        telephonyHandler.mcn = nil
        telephonyHandler.mcnd = nil
        userStorageHandler.dictionary?.removeAll()
    }
    
    @Suite("Mobile Carrier Name - Primary")
    struct MobileCarrierNamePrimaryTests {
        @Suite("when setting mcn")
        struct WhenSettingMcnTests {
            @Test("should store the value in user storage")
            func testShouldStoreValueInUserStorage() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                let carrierName = "Rakuten Mobile"
                spec.telephonyHandler.mcn = carrierName
                
                #expect(spec.userStorageHandler.object(forKey: UserDefaultsKeys.carrierPrimaryNameKey) as? String == carrierName)
                #expect(spec.telephonyHandler.mcn == carrierName)
            }
            
            @Test("should remove the value from user storage when set to nil")
            func testShouldRemoveValueWhenSetToNil() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                spec.telephonyHandler.mcn = "Rakuten Mobile"
                #expect(spec.userStorageHandler.object(forKey: UserDefaultsKeys.carrierPrimaryNameKey) != nil)
                
                spec.telephonyHandler.mcn = nil
                #expect(spec.userStorageHandler.object(forKey: UserDefaultsKeys.carrierPrimaryNameKey) == nil)
                #expect(spec.telephonyHandler.mcn == nil)
            }
            
            @Test("should handle empty string")
            func testShouldHandleEmptyString() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                spec.telephonyHandler.mcn = ""
                
                #expect(spec.userStorageHandler.object(forKey: UserDefaultsKeys.carrierPrimaryNameKey) as? String == "")
                #expect(spec.telephonyHandler.mcn == "")
            }
        }
    }
    
    @Suite("Mobile Carrier Name - Dual/Secondary")
    struct MobileCarrierNameDualSecondaryTests {
        @Suite("when setting mcnd")
        struct WhenSettingMcndTests {
            @Test("should store the value in user storage")
            func testShouldStoreValueInUserStorage() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                let carrierName = "NTT Docomo"
                spec.telephonyHandler.mcnd = carrierName
                
                #expect(spec.userStorageHandler.object(forKey: UserDefaultsKeys.carrierSecondaryNameKey) as? String == carrierName)
                #expect(spec.telephonyHandler.mcnd == carrierName)
            }
            
            @Test("should remove the value from user storage when set to nil")
            func testShouldRemoveValueWhenSetToNil() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                spec.telephonyHandler.mcnd = "NTT Docomo"
                #expect(spec.userStorageHandler.object(forKey: UserDefaultsKeys.carrierSecondaryNameKey) != nil)
                
                spec.telephonyHandler.mcnd = nil
                #expect(spec.userStorageHandler.object(forKey: UserDefaultsKeys.carrierSecondaryNameKey) == nil)
                #expect(spec.telephonyHandler.mcnd == nil)
            }
            
            @Test("should handle empty string")
            func testShouldHandleEmptyString() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                spec.telephonyHandler.mcnd = ""
                
                #expect(spec.userStorageHandler.object(forKey: UserDefaultsKeys.carrierSecondaryNameKey) as? String == "")
                #expect(spec.telephonyHandler.mcnd == "")
            }
        }
    }
    
    @Suite("mnetw and mnetwd")
    struct MnetwAndMnetwdTests {
        @Test("should return mnetw == nil, mnetwd == nil when there are no radios")
        func testShouldReturnNilWhenNoRadios() {
            var spec = TelephonyHandlerTests()
            spec.setUp()
            defer { spec.tearDown() }
            
            spec.telephonyNetworkInfo.safeDataServiceIdentifier = nil
            spec.telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = nil
            
            #expect(spec.telephonyHandler.mnetw == nil)
            #expect(spec.telephonyHandler.mnetwd == nil)
        }
        
        @Test("should return mnetw == 3, mnetwd == nil when there are only one radio (Physical SIM is primary)")
        func testShouldReturnMnetw3WhenOneRadioPhysicalSIMPrimaryEdge() {
            var spec = TelephonyHandlerTests()
            spec.setUp()
            defer { spec.tearDown() }
            
            spec.telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.primaryCarrierKey
            spec.telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: CTRadioAccessTechnologyEdge]
            
            #expect(spec.telephonyHandler.mnetw?.intValue == CTRadioAccessTechnologyEdge.networkType.rawValue)
            #expect(spec.telephonyHandler.mnetwd == nil)
        }
        
        @Test("should return mnetw == 4, mnetwd == nil when there are only one radio (Physical SIM is primary)")
        func testShouldReturnMnetw4WhenOneRadioPhysicalSIMPrimaryLTE() {
            var spec = TelephonyHandlerTests()
            spec.setUp()
            defer { spec.tearDown() }
            
            spec.telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.primaryCarrierKey
            spec.telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: CTRadioAccessTechnologyLTE]
            
            #expect(spec.telephonyHandler.mnetw?.intValue == CTRadioAccessTechnologyLTE.networkType.rawValue)
            #expect(spec.telephonyHandler.mnetwd == nil)
        }
        
        @Test("should return mnetw == 5, mnetwd == nil when there are only one radio (Physical SIM is primary)")
        func testShouldReturnMnetw5WhenOneRadioPhysicalSIMPrimaryNR() {
            var spec = TelephonyHandlerTests()
            spec.setUp()
            defer { spec.tearDown() }
            
            spec.telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.primaryCarrierKey
            spec.telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: CTRadioAccessTechnologyNR]
            
            #expect(spec.telephonyHandler.mnetw?.intValue == CTRadioAccessTechnologyNR.networkType.rawValue)
            #expect(spec.telephonyHandler.mnetwd == nil)
        }
        
        @Test("should return mnetw == 3, mnetwd == nil when there are only one radio (eSIM is primary)")
        func testShouldReturnMnetw3WhenOneRadioESIMPrimaryEdge() {
            var spec = TelephonyHandlerTests()
            spec.setUp()
            defer { spec.tearDown() }
            
            spec.telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.secondaryCarrierKey
            spec.telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: CTRadioAccessTechnologyEdge]
            
            #expect(spec.telephonyHandler.mnetw?.intValue == CTRadioAccessTechnologyEdge.networkType.rawValue)
            #expect(spec.telephonyHandler.mnetwd == nil)
        }
        
        @Test("should return mnetw == 4, mnetwd == nil when there are only one radio (eSIM is primary)")
        func testShouldReturnMnetw4WhenOneRadioESIMPrimaryLTE() {
            var spec = TelephonyHandlerTests()
            spec.setUp()
            defer { spec.tearDown() }
            
            spec.telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.secondaryCarrierKey
            spec.telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: CTRadioAccessTechnologyLTE]
            
            #expect(spec.telephonyHandler.mnetw?.intValue == CTRadioAccessTechnologyLTE.networkType.rawValue)
            #expect(spec.telephonyHandler.mnetwd == nil)
        }
        
        @Test("should return mnetw == 5, mnetwd == nil when there are only one radio (eSIM is primary)")
        func testShouldReturnMnetw5WhenOneRadioESIMPrimaryNR() {
            var spec = TelephonyHandlerTests()
            spec.setUp()
            defer { spec.tearDown() }
            
            spec.telephonyNetworkInfo.safeDataServiceIdentifier = TelephonyNetworkInfoMock.Constants.secondaryCarrierKey
            spec.telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: CTRadioAccessTechnologyNR]
            
            #expect(spec.telephonyHandler.mnetw?.intValue == CTRadioAccessTechnologyNR.networkType.rawValue)
            #expect(spec.telephonyHandler.mnetwd == nil)
        }
        
        @Suite("Physical SIM Card is primary")
        struct PhysicalSIMCardIsPrimaryTests {
            static func verify(spec: inout TelephonyHandlerTests, dataServiceIdentifier: String, primaryRadio: String, secondaryRadio: String) {
                spec.telephonyNetworkInfo.safeDataServiceIdentifier = dataServiceIdentifier
                
                spec.telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [
                    TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryRadio,
                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryRadio]
                
                if primaryRadio.isEmpty {
                    #expect(spec.telephonyHandler.mnetw == nil)
                } else {
                    #expect(spec.telephonyHandler.mnetw?.intValue == primaryRadio.networkType.rawValue)
                }
                
                if secondaryRadio.isEmpty {
                    #expect(spec.telephonyHandler.mnetwd == nil)
                } else {
                    #expect(spec.telephonyHandler.mnetwd?.intValue == secondaryRadio.networkType.rawValue)
                }
            }
            
            @Test("should return mnetw == nil, mnetwd == nil when the primary radio is empty, the secondary radio is empty")
            func testShouldReturnNilWhenBothRadiosEmpty() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: "", secondaryRadio: "")
            }
            
            @Test("should return mnetw == 3, mnetwd == 3 when the primary radio is Edge, the secondary radio is Edge")
            func testShouldReturnMnetw3Mnetwd3WhenBothEdge() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyEdge)
            }
            
            @Test("should return mnetw == 3, mnetwd == 4 when the primary radio is Edge, the secondary radio is LTE")
            func testShouldReturnMnetw3Mnetwd4WhenEdgeLTE() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyLTE)
            }
            
            @Test("should return mnetw == 3, mnetwd == 5 when the primary radio is Edge, the secondary radio is 5G")
            func testShouldReturnMnetw3Mnetwd5WhenEdgeNR() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyNR)
            }
            
            @Test("should return mnetw == 4, mnetwd == 3 when the primary radio is LTE, the secondary radio is Edge")
            func testShouldReturnMnetw4Mnetwd3WhenLTEEdge() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyEdge)
            }
            
            @Test("should return mnetw == 4, mnetwd == 4 when the primary radio is LTE, the secondary radio is Edge")
            func testShouldReturnMnetw4Mnetwd4WhenBothLTE() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyLTE)
            }
            
            @Test("should return mnetw == 4, mnetwd == 5 when the primary radio is LTE, the secondary radio is 5G")
            func testShouldReturnMnetw4Mnetwd5WhenLTENR() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyNR)
            }
            
            @Test("should return mnetw == 5, mnetwd == 3 when the primary radio is 5G, the secondary radio is Edge")
            func testShouldReturnMnetw5Mnetwd3WhenNREdge() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyEdge)
            }
            
            @Test("should return mnetw == 5, mnetwd == 4 when the primary radio is 5G, the secondary radio is LTE")
            func testShouldReturnMnetw5Mnetwd4WhenNRLTE() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyLTE)
            }
            
            @Test("should return mnetw == 5, mnetwd == 5 when the primary radio is 5G, the secondary radio is 5G")
        func testShouldReturnMnetw5Mnetwd5WhenBothNR() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.primaryCarrierKey, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyNR)
            }
        }
        
        @Suite("eSIM Card is primary")
        struct ESIMCardIsPrimaryTests {
            static func verify(spec: inout TelephonyHandlerTests, dataServiceIdentifier: String, primaryRadio: String, secondaryRadio: String) {
                spec.telephonyNetworkInfo.safeDataServiceIdentifier = dataServiceIdentifier
                
                spec.telephonyNetworkInfo.serviceCurrentRadioAccessTechnology = [
                    TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryRadio,
                    TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryRadio]
                
                if primaryRadio.isEmpty {
                    #expect(spec.telephonyHandler.mnetw == nil)
                } else {
                    #expect(spec.telephonyHandler.mnetw?.intValue == secondaryRadio.networkType.rawValue)
                }
                
                if secondaryRadio.isEmpty {
                    #expect(spec.telephonyHandler.mnetwd == nil)
                } else {
                    #expect(spec.telephonyHandler.mnetwd?.intValue == primaryRadio.networkType.rawValue)
                }
            }
            
            @Test("should return mnetw == nil, mnetwd == nil when the primary radio is empty, the secondary radio is empty")
            func testShouldReturnNilWhenBothRadiosEmpty() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: "", secondaryRadio: "")
            }
            
            @Test("should return mnetw == 3, mnetwd == 3 when the primary radio is Edge, the secondary radio is Edge")
            func testShouldReturnMnetw3Mnetwd3WhenBothEdge() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyEdge)
            }
            
            @Test("should return mnetw == 4, mnetwd == 3 when the primary radio is Edge, the secondary radio is LTE")
            func testShouldReturnMnetw4Mnetwd3WhenEdgeLTE() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyLTE)
            }
            
            @Test("should return mnetw == 5, mnetwd == 3 when the primary radio is Edge, the secondary radio is 5G")
            func testShouldReturnMnetw5Mnetwd3WhenEdgeNR() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyNR)
            }
            
            @Test("should return mnetw == 3, mnetwd == 4 when the primary radio is LTE, the secondary radio is Edge")
            func testShouldReturnMnetw3Mnetwd4WhenLTEEdge() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyEdge)
            }
            
            @Test("should return mnetw == 4, mnetwd == 4 when the primary radio is LTE, the secondary radio is LTE")
            func testShouldReturnMnetw4Mnetwd4WhenBothLTE() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyLTE)
            }
            
            @Test("should return mnetw == 5, mnetwd == 4 when the primary radio is LTE, the secondary radio is 5G")
            func testShouldReturnMnetw5Mnetwd4WhenLTENR() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyNR)
            }
            
            @Test("should return mnetw == 3, mnetwd == 5 when the primary radio is 5G, the secondary radio is Edge")
            func testShouldReturnMnetw3Mnetwd5WhenNREdge() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyEdge)
            }
            
            @Test("should return mnetw == 4, mnetwd == 5 when the primary radio is 5G, the secondary radio is LTE")
            func testShouldReturnMnetw4Mnetwd5WhenNRLTE() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyLTE)
            }
            
            @Test("should return mnetw == 5, mnetwd == 5 when the primary radio is 5G, the secondary radio is 5G")
        func testShouldReturnMnetw5Mnetwd5WhenBothNR() {
                var spec = TelephonyHandlerTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                Self.verify(spec: &spec, dataServiceIdentifier: TelephonyNetworkInfoMock.Constants.secondaryCarrierKey, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyNR)
            }
        }
    }
}

// swiftlint:enable line_length

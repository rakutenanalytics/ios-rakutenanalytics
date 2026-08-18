// swiftlint:disable line_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable control_statement

import Foundation
import Testing
import CoreTelephony
import SystemConfiguration
@preconcurrency @testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("RAnalyticsRATTracker")
struct RAnalyticsRATTrackerPayloadNetworkTests {
    @Suite("process(event:state:)")
    struct ProcessEventStateTests {
        @Suite("Network status")
        struct NetworkStatusTests {
            var helper = PayloadTestHelper.TestHelper()
            
            @Suite("When reachabilityStatus is not set")
            struct WhenReachabilityStatusIsNotSetTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should not set online")
                mutating func testShouldNotSetOnline() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    var payload: [String: Any]?
                    
                    helper.reachabilityMock.flags = nil
                    
                    try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                        payload = $0.first
                    }
                    
                    let online = payload?["online"] as? NSNumber
                    #expect(online == nil)
                }
            }
            
            @Suite("When there is no network connection")
            struct WhenThereIsNoNetworkConnectionTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should set online to false")
                mutating func testShouldSetOnlineToFalse() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    var payload: [String: Any]?
                    
                    helper.reachabilityMock.flags = .connectionRequired
                    
                    try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                        payload = $0.first
                    }
                    
                    let online = payload?["online"] as? NSNumber
                    #expect(online?.boolValue == false)
                }
            }
            
            @Suite("When there is a wwan connection")
            struct WhenThereIsAWwanConnectionTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should set online to true")
                mutating func testShouldSetOnlineToTrue() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    var payload: [String: Any]?
                    
                    helper.reachabilityMock.flags = [.isWWAN, .reachable]
                    
                    try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                        payload = $0.first
                    }
                    
                    let online = payload?["online"] as? NSNumber
                    #expect(online?.boolValue == true)
                }
            }
            
            @Suite("When there is a wifi connection")
            struct WhenThereIsAWifiConnectionTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should set online to true")
                mutating func testShouldSetOnlineToTrue() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    var payload: [String: Any]?
                    
                    helper.reachabilityMock.flags = [.isDirect, .reachable]
                    
                    try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                        payload = $0.first
                    }
                    
                    let online = payload?["online"] as? NSNumber
                    #expect(online?.boolValue == true)
                }
            }
        }
        
        @Suite("Mobile Carrier Names")
        struct MobileCarrierNamesTests {
            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should include mcn when set via ratTracker")
            mutating func testShouldIncludeMcnWhenSetViaRatTracker() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                helper.ratTracker.updateCarrierNames(mcn: "Rakuten Mobile", mcnd: nil)
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let mcn = payload?["mcn"] as? String
                #expect(mcn == "Rakuten Mobile")
                #expect(payload?["mcnd"] == nil)
                
                helper.ratTracker.updateCarrierNames(mcn: nil, mcnd: nil)
            }
            
            @Test("should include mcnd when set via ratTracker")
            mutating func testShouldIncludeMcndWhenSetViaRatTracker() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                helper.ratTracker.updateCarrierNames(mcn: nil, mcnd: "NTT Docomo")
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let mcnd = payload?["mcnd"] as? String
                #expect(mcnd == "NTT Docomo")
                #expect(payload?["mcn"] == nil)
                
                helper.ratTracker.updateCarrierNames(mcn: nil, mcnd: nil)
            }
            
            @Test("should include both mcn and mcnd when both are set")
            mutating func testShouldIncludeBothMcnAndMcndWhenBothAreSet() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                helper.ratTracker.updateCarrierNames(mcn: "Primary Carrier", mcnd: "Secondary Carrier")
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let mcn = payload?["mcn"] as? String
                let mcnd = payload?["mcnd"] as? String
                
                #expect(mcn == "Primary Carrier")
                #expect(mcnd == "Secondary Carrier")
                
                helper.ratTracker.updateCarrierNames(mcn: nil, mcnd: nil)
            }
            
            @Test("should not include mcn or mcnd when they are empty strings")
            mutating func testShouldNotIncludeMcnOrMcndWhenTheyAreEmptyStrings() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                helper.ratTracker.updateCarrierNames(mcn: "", mcnd: "")
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                #expect(payload?["mcn"] == nil)
                #expect(payload?["mcnd"] == nil)
                
                helper.ratTracker.updateCarrierNames(mcn: nil, mcnd: nil)
            }
        }
        
        @Suite("mnetw and mnetwd")
        struct MnetwAndMnetwdTests {
            static func verify(helper: inout PayloadTestHelper.TestHelper, primaryRadio: String, secondaryRadio: String, reachabilityStatus: RATReachabilityStatus) async throws {
                var payload: [String: Any]?
                
                switch(reachabilityStatus) {
                case .wifi:
                    helper.reachabilityMock.flags = [.isDirect, .reachable]
                case .wwan:
                    helper.reachabilityMock.flags = [.isWWAN, .reachable]
                case .offline:
                    helper.reachabilityMock.flags = [.connectionRequired]
                }
                
                let telephonyNetworkInfo = helper.dependenciesContainer.telephonyNetworkInfoHandler as? TelephonyNetworkInfoMock
                telephonyNetworkInfo?.serviceCurrentRadioAccessTechnology = [TelephonyNetworkInfoMock.Constants.primaryCarrierKey: primaryRadio,
                                                                             TelephonyNetworkInfoMock.Constants.secondaryCarrierKey: secondaryRadio]
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                if reachabilityStatus == .wifi {
                    #expect((payload?["mnetw"] as? NSNumber)?.intValue == RATMobileNetworkType.wifi.rawValue)
                    #expect((payload?["mnetwd"] as? NSNumber)?.intValue == RATMobileNetworkType.wifi.rawValue)
                } else {
                    if primaryRadio.isEmpty {
                        #expect(payload?["mnetw"] as? String == "")
                    } else {
                        #expect((payload?["mnetw"] as? NSNumber)?.intValue == primaryRadio.networkType.rawValue)
                    }
                    
                    if secondaryRadio.isEmpty {
                        #expect(payload?["mnetwd"] as? String == "")
                    } else {
                        #expect((payload?["mnetwd"] as? NSNumber)?.intValue == secondaryRadio.networkType.rawValue)
                    }
                }
            }
            
            @Suite("Wwan")
            struct WwanTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should process an event with no primary radio and no secondary radio when the network status is offline")
                mutating func testShouldProcessEventWithNoPrimaryRadioAndNoSecondaryRadio() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: "", secondaryRadio: "", reachabilityStatus: .wwan)
                }
                
                @Test("should process an event with Edge primary radio and LTE secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM")
                mutating func testShouldProcessEventWithEdgePrimaryRadioAndLTESecondaryRadio() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyLTE, reachabilityStatus: .wwan)
                }
                
                @Test("should process an event with LTE primary radio and Edge secondary radio when the network status is wwan and the radio is LTE for the main carrier and Edge for the eSIM")
                mutating func testShouldProcessEventWithLTEPrimaryRadioAndEdgeSecondaryRadio() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyEdge, reachabilityStatus: .wwan)
                }
                
                @Test("should process an event with Edge primary radio and 5G secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM")
                mutating func testShouldProcessEventWithEdgePrimaryRadioAnd5GSecondaryRadio() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyNR, reachabilityStatus: .wwan)
                }
                
                @Test("should process an event with 5G primary radio and Edge secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM")
                mutating func testShouldProcessEventWith5GPrimaryRadioAndEdgeSecondaryRadio() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyEdge, reachabilityStatus: .wwan)
                }
                
                @Test("should process an event with Edge primary radio and 5G secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM")
                mutating func testShouldProcessEventWithLTEPrimaryRadioAnd5GSecondaryRadio() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyNR, reachabilityStatus: .wwan)
                }
                
                @Test("should process an event with 5G primary radio and Edge secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM")
                mutating func testShouldProcessEventWith5GPrimaryRadioAndLTESecondaryRadio() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyLTE, reachabilityStatus: .wwan)
                }
                
                @Suite("Edge")
                struct EdgeTests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should process an event with Edge primary radio and no secondary radio when the network status is wwan and the radio is not LTE and there is only one carrier")
                    mutating func testShouldProcessEventWithEdgePrimaryRadioAndNoSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: "", reachabilityStatus: .wwan)
                    }
                    
                    @Test("should process an event with no primary radio and Edge secondary radio when the network status is wwan and the radio is LTE and there is only one carrier")
                    mutating func testShouldProcessEventWithNoPrimaryRadioAndEdgeSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: "", secondaryRadio: CTRadioAccessTechnologyEdge, reachabilityStatus: .wwan)
                    }
                    
                    @Test("should process an event with Edge primary radio and Edge secondary radio when the network status is wwan and the radio is LTE for both carriers")
                    mutating func testShouldProcessEventWithEdgePrimaryRadioAndEdgeSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyEdge, reachabilityStatus: .wwan)
                    }
                }
                
                @Suite("LTE")
                struct LTETests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should process an event with LTE primary radio and no secondary radio when the network status is wwan and the radio is LTE and there is only one carrier")
                    mutating func testShouldProcessEventWithLTEPrimaryRadioAndNoSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: "", reachabilityStatus: .wwan)
                    }
                    
                    @Test("should process an event with no primary radio and LTE secondary radio when the network status is wwan and the radio is LTE and there is only one carrier")
                    mutating func testShouldProcessEventWithNoPrimaryRadioAndLTESecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: "", secondaryRadio: CTRadioAccessTechnologyLTE, reachabilityStatus: .wwan)
                    }
                    
                    @Test("should process an event with LTE primary radio and LTE secondary radio when the network status is wwan and the radio is LTE for both carriers")
                    mutating func testShouldProcessEventWithLTEPrimaryRadioAndLTESecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyLTE, reachabilityStatus: .wwan)
                    }
                }
                
                @Suite("5G")
                struct FiveGTests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should process an event with 5G primary radio and no secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM")
                    mutating func testShouldProcessEventWith5GPrimaryRadioAndNoSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: "", reachabilityStatus: .wwan)
                    }
                    
                    @Test("should process an event with no primary radio and 5G secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM")
                    mutating func testShouldProcessEventWithNoPrimaryRadioAnd5GSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: "", secondaryRadio: CTRadioAccessTechnologyNR, reachabilityStatus: .wwan)
                    }
                    
                    @Test("should process an event with 5G primary radio and 5G secondary radio when the network status is wwan and the radio is Edge for the main carrier and LTE for the eSIM")
                    mutating func testShouldProcessEventWith5GPrimaryRadioAnd5GSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyNR, reachabilityStatus: .wwan)
                    }
                }
            }
            
            @Suite("Wifi")
            struct WifiTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should process an event with wifi when there is no primary radio, no secondary radio and the network status is wifi")
                mutating func testShouldProcessEventWithWifiWhenNoPrimaryRadioAndNoSecondaryRadio() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: "", secondaryRadio: "", reachabilityStatus: .wifi)
                }
                
                @Suite("Edge")
                struct EdgeTests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should process an event with wifi when there is Edge primary radio, no secondary radio and the network status is wifi")
                    mutating func testShouldProcessEventWithWifiWhenEdgePrimaryRadioAndNoSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: "", reachabilityStatus: .wifi)
                    }
                    
                    @Test("should process an event with wifi when there is no primary radio, Edge secondary radio and the network status is wifi")
                    mutating func testShouldProcessEventWithWifiWhenNoPrimaryRadioAndEdgeSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: "", secondaryRadio: CTRadioAccessTechnologyEdge, reachabilityStatus: .wifi)
                    }
                    
                    @Test("should process an event with wifi when there is Edge primary radio, Edge secondary radio and the network status is wifi")
                    mutating func testShouldProcessEventWithWifiWhenEdgePrimaryRadioAndEdgeSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyEdge, secondaryRadio: CTRadioAccessTechnologyEdge, reachabilityStatus: .wifi)
                    }
                }
                
                @Suite("LTE")
                struct LTETests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should process an event with wifi when there is LTE primary radio, no secondary radio and the network status is wifi")
                    mutating func testShouldProcessEventWithWifiWhenLTEPrimaryRadioAndNoSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: "", reachabilityStatus: .wifi)
                    }
                    
                    @Test("should process an event with wifi when there is no primary radio, LTE secondary radio and the network status is wifi")
                    mutating func testShouldProcessEventWithWifiWhenNoPrimaryRadioAndLTESecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: "", secondaryRadio: CTRadioAccessTechnologyLTE, reachabilityStatus: .wifi)
                    }
                    
                    @Test("should process an event with wifi when there is LTE primary radio, LTE secondary radio and the network status is wifi")
                    mutating func testShouldProcessEventWithWifiWhenLTEPrimaryRadioAndLTESecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyLTE, secondaryRadio: CTRadioAccessTechnologyLTE, reachabilityStatus: .wifi)
                    }
                }
                
                @Suite("5G")
                struct FiveGTests {
                    var helper = PayloadTestHelper.TestHelper()
                    
                    @Test("should process an event with wifi when there is 5G primary radio, no secondary radio and the network status is wifi")
                    mutating func testShouldProcessEventWithWifiWhen5GPrimaryRadioAndNoSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: "", reachabilityStatus: .wifi)
                    }
                    
                    @Test("should process an event with wifi when there is no primary radio, 5G secondary radio and the network status is wifi")
                    mutating func testShouldProcessEventWithWifiWhenNoPrimaryRadioAnd5GSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: "", secondaryRadio: CTRadioAccessTechnologyNR, reachabilityStatus: .wifi)
                    }
                    
                    @Test("should process an event with wifi when there is 5G primary radio, 5G secondary radio and the network status is wifi")
                    mutating func testShouldProcessEventWithWifiWhen5GPrimaryRadioAnd5GSecondaryRadio() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        try await MnetwAndMnetwdTests.verify(helper: &helper, primaryRadio: CTRadioAccessTechnologyNR, secondaryRadio: CTRadioAccessTechnologyNR, reachabilityStatus: .wifi)
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

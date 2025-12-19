// swiftlint:disable line_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable control_statement

import Foundation
import Testing
@preconcurrency @testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsRATTrackerProcessPushTests

@Suite("RAnalyticsRATTracker")
struct RAnalyticsRATTrackerProcessPushTests {
    @Suite("process(event:state:)")
    struct ProcessEventStateTests {
        @Suite("Event processing")
        struct EventProcessingTests {
            @Suite("The push notification is received")
            struct PushNotificationReceivedTests {
                var helper = ProcessTestHelper.TestHelper()
                
                @Suite("_rem_push_received_external")
                struct PushReceivedExternalTests {
                    var helper = ProcessTestHelper.TestHelper()
                    
                    @Suite("request identifier is nil")
                    struct RequestIdentifierNilTests {
                        var helper = ProcessTestHelper.TestHelper()
                        
                        @Test("should process the _rem_push_received event with a tracking identifier")
                        mutating func testShouldProcessPushReceivedWithTrackingIdentifier() async throws {
                            helper.setUp()
                            defer { helper.tearDown() }
                            
                            let trackingIdentifier = "trackingIdentifier"
                            let event = RAnalyticsEvent(
                                name: RAnalyticsEvent.Name.pushNotificationReceivedExternal,
                                parameters: [CpParameterKeys.Push.pushNotifyValue: trackingIdentifier])
                            
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?
                            
                            try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationReceivedForRAT) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            try await TestingHelpers.eventually {
                                payload != nil && cpPayload != nil
                            }
                            #expect(cpPayload?[CpParameterKeys.Push.pushNotifyValue] as? String == trackingIdentifier)
                            #expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] == nil)
                        }
                        
                        @Test("should process the _rem_push_received event with rid")
                        mutating func testShouldProcessPushReceivedWithRid() async throws {
                            helper.setUp()
                            defer { helper.tearDown() }
                            
                            var parameters = [String: Any]()
                            parameters[CpParameterKeys.Push.pushNotifyValue] = "rid:123456"
                            
                            let event = RAnalyticsEvent(
                                name: RAnalyticsEvent.Name.pushNotificationReceivedExternal,
                                parameters: parameters)
                            
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?
                            
                            try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationReceivedForRAT) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            try await TestingHelpers.eventually {
                                payload != nil && cpPayload != nil
                            }
                            #expect(cpPayload?[CpParameterKeys.Push.pushNotifyValue] as? String == "rid:123456")
                            #expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] == nil)
                        }
                    }
                    
                    @Suite("request identifier is not nil")
                    struct RequestIdentifierNotNilTests {
                        var helper = ProcessTestHelper.TestHelper()
                        
                        @Test("should process the _rem_push_received event with a tracking identifier and a request identifier")
                        mutating func testShouldProcessPushReceivedWithTrackingAndRequestIdentifier() async throws {
                            helper.setUp()
                            defer { helper.tearDown() }
                            
                            let trackingIdentifier = "trackingIdentifier"
                            let requestIdentifier = "requestIdentifier"
                            let event = RAnalyticsEvent(
                                name: RAnalyticsEvent.Name.pushNotificationReceivedExternal,
                                parameters: [RAnalyticsEvent.Parameter.pushTrackingIdentifier: trackingIdentifier,
                                             RAnalyticsEvent.Parameter.pushRequestIdentifier: requestIdentifier,
                                             CpParameterKeys.Push.pushNotifyValue: trackingIdentifier])
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?
                            
                            try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationReceivedForRAT) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            try await TestingHelpers.eventually {
                                payload != nil && cpPayload != nil
                            }
                            #expect(cpPayload?[CpParameterKeys.Push.pushNotifyValue] as? String == trackingIdentifier)
                            #expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] as? String == requestIdentifier)
                        }
                        
                        @Test("should process the _rem_push_received event with rid and a request identifier")
                        mutating func testShouldProcessPushReceivedWithRidAndRequestIdentifier() async throws {
                            helper.setUp()
                            defer { helper.tearDown() }
                            
                            let requestIdentifier = "requestIdentifier"
                            
                            var parameters = [String: Any]()
                            parameters[CpParameterKeys.Push.pushNotifyValue] = "rid:123456"
                            parameters[AnalyticsManager.Event.Parameter.pushRequestIdentifier] = requestIdentifier
                            
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pushNotificationReceivedExternal, parameters: parameters)
                            
                            var payload: [String: Any]?
                            var cpPayload: [String: Any]?
                            
                            try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationReceivedForRAT) {
                                payload = $0.first
                                cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                            }
                            try await TestingHelpers.eventually {
                                payload != nil && cpPayload != nil
                            }
                            #expect(cpPayload?[CpParameterKeys.Push.pushNotifyValue] as? String == "rid:123456")
                            #expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] as? String == requestIdentifier)
                        }
                    }
                }
            }
            
            @Suite("The push notification is opened")
            struct PushNotificationOpenedTests {
                var helper = ProcessTestHelper.TestHelper()
                
                @Suite("_rem_push_notify_external")
                struct PushNotifyExternalTests {
                    var helper = ProcessTestHelper.TestHelper()
                    
                    @Test("should process the _rem_push_notify event with a tracking identifier")
                    mutating func testShouldProcessPushNotifyWithTrackingIdentifier() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        let trackingIdentifier = "trackingIdentifier"
                        let event = RAnalyticsEvent(
                            name: RAnalyticsEvent.Name.pushNotificationExternal,
                            parameters: [CpParameterKeys.Push.pushNotifyValue: trackingIdentifier])
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?
                        try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationOpenedForRAT) {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        try await TestingHelpers.eventually {
                            payload != nil && cpPayload != nil
                        }
                        #expect(cpPayload?[CpParameterKeys.Push.pushNotifyValue] as? String == trackingIdentifier)
                    }
                    
                    @Test("should process the _rem_push_notify event with rid")
                    mutating func testShouldProcessPushNotifyWithRid() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        var parameters = [String: Any]()
                        parameters[CpParameterKeys.Push.pushNotifyValue] = "rid:123456"
                        
                        let event = RAnalyticsEvent(
                            name: AnalyticsManager.Event.Name.pushNotificationExternal,
                            parameters: parameters)
                        
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?
                        try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationOpenedForRAT) {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        try await TestingHelpers.eventually {
                            payload != nil && cpPayload != nil
                        }
                        #expect(cpPayload?[CpParameterKeys.Push.pushNotifyValue] as? String == "rid:123456")
                    }
                }
            }
            
            @Suite("Push conversion event")
            struct PushConversionEventTests {
                var helper = ProcessTestHelper.TestHelper()
                
                @Test("should not process the _rem_push_cv event when request identifier and conversion action are empty")
                mutating func testShouldNotProcessPushCvWhenBothEmpty() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(
                        name: AnalyticsManager.Event.Name.pushNotificationConversion,
                        parameters: [AnalyticsManager.Event.Parameter.pushRequestIdentifier: "",
                                     AnalyticsManager.Event.Parameter.pushConversionAction: ""])
                    
                    var payload: [String: Any]?
                    var cpPayload: [String: Any]?
                    
                    try await helper.expecter.processEventAsync(event, state: Tracking.defaultState) {
                        payload = $0.first
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    
                    try await TestingHelpers.eventually {
                        payload != nil && cpPayload != nil
                    }
                    #expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] as? String == "")
                    #expect(cpPayload?[CpParameterKeys.Push.pushConversionAction] as? String == "")
                }
                
                @Test("should not process the _rem_push_cv event when request identifier is empty")
                mutating func testShouldNotProcessPushCvWhenRequestIdentifierEmpty() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(
                        name: AnalyticsManager.Event.Name.pushNotificationConversion,
                        parameters: [AnalyticsManager.Event.Parameter.pushRequestIdentifier: "",
                                     AnalyticsManager.Event.Parameter.pushConversionAction: "pushConversionAction"])
                    var payload: [String: Any]?
                    var cpPayload: [String: Any]?
                    
                    try await helper.expecter.processEventAsync(event, state: Tracking.defaultState) {
                        payload = $0.first
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    
                    try await TestingHelpers.eventually {
                        payload != nil && cpPayload != nil
                    }
                    #expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] as? String == "")
                    #expect(cpPayload?[CpParameterKeys.Push.pushConversionAction] as? String == "pushConversionAction")
                }
                
                @Test("should not process the _rem_push_cv event when conversion action is empty")
                mutating func testShouldNotProcessPushCvWhenConversionActionEmpty() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(
                        name: AnalyticsManager.Event.Name.pushNotificationConversion,
                        parameters: [AnalyticsManager.Event.Parameter.pushRequestIdentifier: "pushRequestIdentifier",
                                     AnalyticsManager.Event.Parameter.pushConversionAction: ""])
                    
                    var payload: [String: Any]?
                    var cpPayload: [String: Any]?
                    
                    try await helper.expecter.processEventAsync(event, state: Tracking.defaultState) {
                        payload = $0.first
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    
                    try await TestingHelpers.eventually {
                        payload != nil && cpPayload != nil
                    }
                    #expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] as? String == "pushRequestIdentifier")
                    #expect(cpPayload?[CpParameterKeys.Push.pushConversionAction] as? String == "")
                }
                
                @Test("should process the _rem_push_cv event when request identifier and conversion action are not empty")
                mutating func testShouldProcessPushCvWhenBothNotEmpty() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(
                        name: AnalyticsManager.Event.Name.pushNotificationConversion,
                        parameters: [AnalyticsManager.Event.Parameter.pushRequestIdentifier: "pushRequestIdentifier",
                                     AnalyticsManager.Event.Parameter.pushConversionAction: "pushConversionAction"])
                    var payload: [String: Any]?
                    var cpPayload: [String: Any]?
                    
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.pushNotificationConversion) {
                        payload = $0.first
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    try await TestingHelpers.eventually {
                        payload != nil && cpPayload != nil
                    }
                    #expect(cpPayload?[CpParameterKeys.Push.pushRequestIdentifier] as? String == "pushRequestIdentifier")
                    #expect(cpPayload?[CpParameterKeys.Push.pushConversionAction] as? String == "pushConversionAction")
                }
            }
            
            @Suite("PNP events")
            struct PNPEventsTests {
                var helper = ProcessTestHelper.TestHelper()
                
                @Suite("Push auto registration external event")
                struct PushAutoRegistrationExternalTests {
                    var helper = ProcessTestHelper.TestHelper()
                    
                    @Test("should process the pushAutoRegistrationExternal event when parameters is not nil")
                    mutating func testShouldProcessPushAutoRegistrationExternal() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        let event = RAnalyticsEvent(
                            name: RAnalyticsEvent.Name.pushAutoRegistrationExternal,
                            parameters: [CpParameterKeys.PNP.deviceId: Tracking.deviceToken,
                                         CpParameterKeys.PNP.pnpClientId: Tracking.pnpClientIdentifier])
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?
                        
                        try await helper.expecter.processEventAsync(event, state: Tracking.defaultState) {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        
                        try await TestingHelpers.eventually {
                            payload != nil && cpPayload != nil
                        }
                        #expect(cpPayload?[CpParameterKeys.PNP.deviceId] as? String == Tracking.deviceToken)
                        #expect(cpPayload?[CpParameterKeys.PNP.pnpClientId] as? String == Tracking.pnpClientIdentifier)
                    }
                }
                
                @Suite("Push auto unregistration external event")
                struct PushAutoUnregistrationExternalTests {
                    var helper = ProcessTestHelper.TestHelper()
                    
                    @Test("should process the pushAutoUnregistrationExternal event when parameters is not nil")
                    mutating func testShouldProcessPushAutoUnregistrationExternal() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        let event = RAnalyticsEvent(
                            name: RAnalyticsEvent.Name.pushAutoUnregistrationExternal,
                            parameters: [CpParameterKeys.PNP.deviceId: Tracking.deviceToken,
                                         CpParameterKeys.PNP.pnpClientId: Tracking.pnpClientIdentifier])
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?
                        
                        try await helper.expecter.processEventAsync(event, state: Tracking.defaultState) {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        
                        try await TestingHelpers.eventually {
                            payload != nil && cpPayload != nil
                        }
                        #expect(cpPayload?[CpParameterKeys.PNP.deviceId] as? String == Tracking.deviceToken)
                        #expect(cpPayload?[CpParameterKeys.PNP.pnpClientId] as? String == Tracking.pnpClientIdentifier)
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

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

// MARK: - RAnalyticsRATTrackerProcessOtherEventsTests

@Suite("RAnalyticsRATTracker")
struct RAnalyticsRATTrackerProcessOtherEventsTests {
    @Suite("process(event:state:)")
    struct ProcessEventStateTests {
        @Suite("Event processing")
        struct EventProcessingTests {
            @Suite("Other events")
            struct OtherEventsTests {
                var helper = ProcessTestHelper.TestHelper()
                
                @Test("should process the discover event with an app name and a store URL")
                mutating func testShouldProcessDiscoverEvent() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let discoverEvent = "_rem_discover_event"
                    let appName = "appName"
                    let storeURL = "storeUrl"
                    let event = RAnalyticsEvent(name: discoverEvent,
                                                parameters: ["prApp": appName, "prStoreUrl": storeURL])
                    var payload: [String: Any]?
                    var cpPayload: [String: Any]?
                    
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: discoverEvent) {
                        payload = $0.first
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    try await TestingHelpers.eventually {
                        payload != nil && cpPayload != nil
                    }
                    
                    let prApp = cpPayload?["prApp"] as? String
                    #expect(prApp == appName)
                    
                    let prStoreUrl = cpPayload?["prStoreUrl"] as? String
                    #expect(prStoreUrl == storeURL)
                }
                
                @Test("should process the SSOCredentialFound event")
                mutating func testShouldProcessSSOCredentialFound() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.ssoCredentialFound, parameters: ["source": "device"])
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.ssoCredentialFound) { _ in }
                }
                
                @Suite("LoginCredentialFound")
                struct LoginCredentialFoundTests {
                    var helper = ProcessTestHelper.TestHelper()
                    
                    @Test("should process the loginCredentialFound event with icloud source")
                    mutating func testShouldProcessLoginCredentialFoundWithIcloud() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginCredentialFound, parameters: ["source": "icloud"])
                        try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginCredentialFound) { _ in }
                    }
                    
                    @Test("should process the loginCredentialFound event with password-manager source")
                    mutating func testShouldProcessLoginCredentialFoundWithPasswordManager() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginCredentialFound, parameters: ["source": "password-manager"])
                        try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginCredentialFound) { _ in }
                    }
                }
                
                @Test("should process the credentialStrategies event")
                mutating func testShouldProcessCredentialStrategies() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.credentialStrategies,
                                                parameters: ["strategies": ["password-manager": "true"]])
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.credentialStrategies) { _ in }
                }
                
                @Suite("Custom")
                struct CustomEventTests {
                    var helper = ProcessTestHelper.TestHelper()
                    
                    @Test("should process the custom event with eventData parameters")
                    mutating func testShouldProcessCustomEventWithEventData() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["eventName": "etypeName", "eventData": ["foo": "bar"]])
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?
                        
                        try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "etypeName") {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        try await TestingHelpers.eventually {
                            payload != nil && cpPayload != nil
                        }
                        
                        let foo = cpPayload?["foo"] as? String
                        #expect(foo == "bar")
                    }
                    
                    @Test("should process the custom event without eventData parameters")
                    mutating func testShouldProcessCustomEventWithoutEventData() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["eventName": "etypeName"])
                        var payload: [String: Any]?
                        var cpPayload: [String: Any]?
                        
                        try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "etypeName") {
                            payload = $0.first
                            cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                        }
                        try await TestingHelpers.eventually {
                            payload != nil
                        }
                        #expect(cpPayload == nil)
                    }
                    
                    @Test("should not process the custom event without eventName")
                    mutating func testShouldNotProcessCustomEventWithoutEventName() {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["blah": "name", "eventData": ["foo": "bar"]])
                        #expect(helper.ratTracker.process(event: event, state: Tracking.defaultState) == false)
                    }
                    
                    @Test("should process the custom event with customAccNumber")
                    mutating func testShouldProcessCustomEventWithCustomAccNumber() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["eventName": "etypeName", "customAccNumber": 10])
                        var payload: [String: Any]?
                        
                        try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "etypeName") {
                            payload = $0.first
                        }
                        try await TestingHelpers.eventually {
                            payload != nil
                        }
                        #expect(payload?[PayloadParameterKeys.acc] as? NSNumber == NSNumber(value: 10))
                    }
                    
                    @Test("should process the custom event with default account number when customAccNumber is 0")
                    mutating func testShouldProcessCustomEventWithDefaultAccNumber0() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["eventName": "etypeName", "customAccNumber": 0])
                        var payload: [String: Any]?
                        
                        try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "etypeName") {
                            payload = $0.first
                        }
                        try await TestingHelpers.eventually {
                            payload != nil
                        }
                        #expect(payload?[PayloadParameterKeys.acc] as? NSNumber == NSNumber(value: 777))
                    }
                    
                    @Test("should process the custom event with default account number when customAccNumber is -2")
                    mutating func testShouldProcessCustomEventWithDefaultAccNumberNegative2() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["eventName": "etypeName", "customAccNumber": -2])
                        var payload: [String: Any]?
                        
                        try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "etypeName") {
                            payload = $0.first
                        }
                        try await TestingHelpers.eventually {
                            payload != nil
                        }
                        #expect(payload?[PayloadParameterKeys.acc] as? NSNumber == NSNumber(value: 777))
                    }
                    
                    @Test("should process the custom event with default account number when customAccNumber is 6.33")
                    mutating func testShouldProcessCustomEventWithDefaultAccNumber6_33() async throws {
                        helper.setUp()
                        defer { helper.tearDown() }
                        
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.custom,
                                                    parameters: ["eventName": "etypeName", "customAccNumber": 6.33])
                        var payload: [String: Any]?
                        
                        try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "etypeName") {
                            payload = $0.first
                        }
                        try await TestingHelpers.eventually {
                            payload != nil
                        }
                        #expect(payload?[PayloadParameterKeys.acc] as? NSNumber == NSNumber(value: 777))
                    }
                }
                
                @Test("should not process an unknown event")
                mutating func testShouldNotProcessUnknownEvent() {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(name: "unknown", parameters: nil)
                    #expect(helper.ratTracker.process(event: event, state: Tracking.defaultState) == false)
                }
            }
        }
    }
}

// swiftlint:enable line_length
// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
// swiftlint:enable control_statement

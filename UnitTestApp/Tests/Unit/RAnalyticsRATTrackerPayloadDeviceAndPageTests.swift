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

@Suite("RAnalyticsRATTracker")
struct RAnalyticsRATTrackerPayloadDeviceAndPageTests {
    @Suite("process(event:state:)")
    struct ProcessEventStateTests {
        @Suite("Device")
        struct DeviceTests {
            @Suite("Model")
            struct ModelTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should set a non-nil model")
                mutating func testShouldSetNonNilModel() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    var payload: [String: Any]?
                    
                    try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                        payload = $0.first
                    }
                    
                    let model = payload?["model"] as? String
                    #expect(model != nil)
                }
            }
            
            @Suite("Resolution")
            struct ResolutionTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should set a non-nil res")
                mutating func testShouldSetNonNilRes() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    var payload: [String: Any]?
                    
                    try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                        payload = $0.first
                    }
                    
                    let res = payload?["res"] as? String
                    #expect(res != nil)
                }
            }
            
            @Suite("Battery infos")
            struct BatteryInfosTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should process an event with battery infos")
                mutating func testShouldProcessEventWithBatteryInfos() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    var payload: [String: Any]?
                    
                    try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                        payload = $0.first
                    }
                    
                    let powerstatus = payload?["powerstatus"] as? NSNumber
                    let mbat = payload?["mbat"] as? String
                    #expect(powerstatus?.intValue == 0)
                    #expect(mbat == "50")
                }
            }
        }
        
        @Suite("mori")
        struct MoriTests {
            static func expectMori(helper: inout PayloadTestHelper.TestHelper, equal value: Int) async throws {
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                #expect((payload?["mori"] as? NSNumber)?.intValue == value)
            }
            
            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should set the mori value to 1")
            mutating func testShouldSetMoriValueToOne1() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let statusBarOrientationGetter = helper.dependenciesContainer.analyticsStatusBarOrientationGetter as? ApplicationMock
                statusBarOrientationGetter?.injectedValue = .portrait
                try await MoriTests.expectMori(helper: &helper, equal: 1)
            }
            
            @Test("should set the mori value to 1")
            mutating func testShouldSetMoriValueToOne2() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let statusBarOrientationGetter = helper.dependenciesContainer.analyticsStatusBarOrientationGetter as? ApplicationMock
                statusBarOrientationGetter?.injectedValue = .portraitUpsideDown
                try await MoriTests.expectMori(helper: &helper, equal: 1)
            }
            
            @Test("should set the mori value to 2")
            mutating func testShouldSetMoriValueToTwo1() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let statusBarOrientationGetter = helper.dependenciesContainer.analyticsStatusBarOrientationGetter as? ApplicationMock
                statusBarOrientationGetter?.injectedValue = .landscapeLeft
                try await MoriTests.expectMori(helper: &helper, equal: 2)
            }
            
            @Test("should set the mori value to 2")
            mutating func testShouldSetMoriValueToTwo2() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let statusBarOrientationGetter = helper.dependenciesContainer.analyticsStatusBarOrientationGetter as? ApplicationMock
                statusBarOrientationGetter?.injectedValue = .landscapeRight
                try await MoriTests.expectMori(helper: &helper, equal: 2)
            }
            
            @Test("should set the mori value to 1")
            mutating func testShouldSetMoriValueToOne3() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let statusBarOrientationGetter = helper.dependenciesContainer.analyticsStatusBarOrientationGetter as? ApplicationMock
                statusBarOrientationGetter?.injectedValue = .unknown
                try await MoriTests.expectMori(helper: &helper, equal: 1)
            }
            
            @Test("should set the mori value to 1")
            mutating func testShouldSetMoriValueToOne4() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                helper.dependenciesContainer.analyticsStatusBarOrientationGetter = nil
                helper.ratTracker = RAnalyticsRATTracker(dependenciesContainer: helper.dependenciesContainer)
                helper.ratTracker.set(batchingDelay: 0)
                
                helper.expecter.dependenciesContainer = helper.dependenciesContainer
                helper.expecter.ratTracker = helper.ratTracker
                try await MoriTests.expectMori(helper: &helper, equal: 1)
            }
        }
        
        @Suite("PageId")
        struct PageIdTests {
            @Suite("pgid validation and handling")
            struct PgidValidationAndHandlingTests {
                var helper = PayloadTestHelper.TestHelper()
                
                @Test("should include pgid in payload when valid pgid is provided as event parameter")
                mutating func testShouldIncludePgidInPayloadWhenValidPgidIsProvided() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    var payload: [String: Any]?
                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: helper.dependenciesContainer)
                    let deviceIdentifier = "deviceId"
                    let validPgid = "\(deviceIdentifier)_1234567890123"
                    let event = RAnalyticsEvent(name: "rat.test_event", parameters: ["pgid": validPgid])
                    let result = ratTracker.process(event: event, state: Tracking.defaultState)
                    #expect(result == true)
                    
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "test_event") {
                        payload = $0.first
                    }
                    
                    #expect(payload?.keys.contains("pgid") == true)
                }
                
                @Test("should not include pgid in payload when invalid format is provided")
                mutating func testShouldNotIncludePgidInPayloadWhenInvalidFormatIsProvided() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    var payload: [String: Any]?
                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: helper.dependenciesContainer)
                    let event = RAnalyticsEvent(name: "rat.test_event", parameters: ["pgid": "invalid_format"])
                    let result = ratTracker.process(event: event, state: Tracking.defaultState)
                    #expect(result == true)
                    
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "test_event") {
                        payload = $0.first
                    }
                    
                    #expect(payload?.keys.contains("pgid") == false)
                }
                
                @Test("should not include pgid in payload when ckp does not match")
                mutating func testShouldNotIncludePgidInPayloadWhenCkpDoesNotMatch() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    var payload: [String: Any]?
                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: helper.dependenciesContainer)
                    let wrongCkp = "wrong_device_id_1234567890123"
                    let event = RAnalyticsEvent(name: "rat.test_event", parameters: ["pgid": wrongCkp])
                    let result = ratTracker.process(event: event, state: Tracking.defaultState)
                    #expect(result == true)
                    
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "test_event") {
                        payload = $0.first
                    }
                    
                    #expect(payload?.keys.contains("pgid") == false)
                }
                
                @Test("should not include pgid in payload when timestamp is not numeric")
                mutating func testShouldNotIncludePgidInPayloadWhenTimestampIsNotNumeric() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    var payload: [String: Any]?
                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: helper.dependenciesContainer)
                    let deviceIdentifier = "deviceId"
                    let invalidPgid = "\(deviceIdentifier)_not_a_number"
                    let event = RAnalyticsEvent(name: "rat.test_event", parameters: ["pgid": invalidPgid])
                    let result = ratTracker.process(event: event, state: Tracking.defaultState)
                    #expect(result == true)
                    
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "test_event") {
                        payload = $0.first
                    }
                    
                    #expect(payload?.keys.contains("pgid") == false)
                }
            }
        }
        
        @Suite("Page Section")
        struct PageSectionTests {
            enum NonStringPageSection: CaseIterable, Sendable, CustomStringConvertible {
                case int
                case double
                case boolTrue
                case boolFalse
                case null

                var description: String {
                    switch self {
                    case .int: return "Int"
                    case .double: return "Double"
                    case .boolTrue: return "Bool(true)"
                    case .boolFalse: return "Bool(false)"
                    case .null: return "NSNull"
                    }
                }

                var parameter: Any {
                    switch self {
                    case .int: return 1
                    case .double: return 20.0
                    case .boolTrue: return true
                    case .boolFalse: return false
                    case .null: return NSNull()
                    }
                }
            }

            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should include pgs when a non-empty string is provided")
            mutating func testShouldIncludePgsWhenNonEmptyStringIsProvided() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                let validPageSection = "test-section"
                let ratTracker = RAnalyticsRATTracker(dependenciesContainer: helper.dependenciesContainer)
                let event = RAnalyticsEvent(name: "rat.test_event", parameters: ["pgs": validPageSection])
                let result = ratTracker.process(event: event, state: Tracking.defaultState)
                #expect(result == true)
                
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "test_event") {
                    payload = $0.first
                }
                
                #expect(payload?.keys.contains("pgs") == true)
                #expect(payload?["pgs"] as? String == validPageSection)
            }
            
            @Test("should not include when an empty string is provided")
            mutating func testShouldNotIncludeWhenEmptyStringIsProvided() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                let invalidPageSection = ""
                let ratTracker = RAnalyticsRATTracker(dependenciesContainer: helper.dependenciesContainer)
                let event = RAnalyticsEvent(name: "rat.test_event", parameters: ["pgs": invalidPageSection])
                let result = ratTracker.process(event: event, state: Tracking.defaultState)
                #expect(result == true)
                
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "test_event") {
                    payload = $0.first
                }
                
                #expect(payload?.keys.contains("pgs") == false)
            }
            
            @Test("should not include when a non-string value is provided", arguments: NonStringPageSection.allCases)
            mutating func testShouldNotIncludeWhenNonStringValueIsProvided(invalidPageSection: NonStringPageSection) async throws {
                helper.setUp()
                defer { helper.tearDown() }

                var payload: [String: Any]?
                let event = RAnalyticsEvent(name: "rat.test_event",
                                            parameters: ["pgs": invalidPageSection.parameter])

                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "test_event") {
                    payload = $0.first
                }

                #expect(payload?.keys.contains("pgs") == false)
            }
        }
        
        @Suite("Batching Delay")
        struct BatchingDelayTests {
            var helper = PayloadTestHelper.TestHelper()
            
            static func expectBatchingDelay(helper: inout PayloadTestHelper.TestHelper, equal value: TimeInterval) async throws {
                let processed = helper.ratTracker.process(event: Tracking.defaultEvent, state: Tracking.defaultState)
                #expect(processed == true)
                
                let sender = helper.ratTracker.perform(Selector((("sender"))))?.takeUnretainedValue() as? RAnalyticsSender
                
                // Wait for the sender to update uploadTimerInterval after processing the event
                // The sender updates this asynchronously on the main queue
                try await TestingHelpers.eventuallyAsync(timeout: 2.0) {
                    await Task.yield()
                    // Read the current value from the sender, not a captured value
                    let currentInterval = await MainActor.run {
                        sender?.uploadTimerInterval ?? -1
                    }
                    return currentInterval == value
                }
            }
            
            @Test("should set the expected batching delay to the sender when the RAT tracker batching delay is set")
            mutating func testShouldSetExpectedBatchingDelayWhenBatchingDelayIsSet() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let delay = 15.0
                helper.ratTracker.set(batchingDelay: delay)
                try await BatchingDelayTests.expectBatchingDelay(helper: &helper, equal: delay)
            }
            
            @Test("should set the expected batching delay to the sender when the RAT tracker batching delay block is set")
            mutating func testShouldSetExpectedBatchingDelayWhenBatchingDelayBlockIsSet() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let delay = 10.0
                helper.ratTracker.set(batchingDelayBlock: { delay })
                try await BatchingDelayTests.expectBatchingDelay(helper: &helper, equal: delay)
            }
        }
        
        @Suite("easyid")
        struct EasyidTests {
            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should set the easyid")
            mutating func testShouldSetTheEasyid() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                #expect(payload?["easyid"] as? String == "easyId")
            }
            
            @Test("should not set the easyid when the state's easyIdentifier is not set")
            mutating func testShouldNotSetTheEasyidWhenStatesEasyIdentifierIsNotSet() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                let state = RAnalyticsState(sessionIdentifier: "CA7A88AR-82FE-40C9-A836-B1B3455DECAF",
                                            deviceIdentifier: "deviceId")
                state.easyIdentifier = nil
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: state, equal: "defaultEvent") {
                    payload = $0.first
                }
                #expect(payload?["easyid"] as? String == nil)
            }
        }
    }
}

// swiftlint:enable line_length
// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
// swiftlint:enable control_statement

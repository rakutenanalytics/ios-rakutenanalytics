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

// MARK: - RAnalyticsRATTrackerProcessSdkSourceTests

@Suite("RAnalyticsRATTracker")
struct RAnalyticsRATTrackerProcessSdkSourceTests {
    @Suite("sdk_source parameter")
    struct SdkSourceParameterTests {
        var helper = ProcessTestHelper.TestHelper()
        
        @Suite("When sdk_source is not set in event parameters")
        struct SdkSourceNotSetTests {
            var helper = ProcessTestHelper.TestHelper()
            
            @Test("should add sdk_source with value 'main' to payload")
            mutating func testShouldAddSdkSourceMain() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.sessionStart) {
                    payload = $0.first
                }
                
                try await TestingHelpers.eventually {
                    payload != nil
                }
                #expect(payload?[PayloadParameterKeys.sdkSource] as? String == "main")
            }
            
            @Test("should add sdk_source to payload at top level (same level as acc and aid)")
            mutating func testShouldAddSdkSourceAtTopLevel() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(name: "rat.test_event", parameters: nil)
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "test_event") {
                    payload = $0.first
                }
                
                try await TestingHelpers.eventually {
                    payload != nil
                }
                #expect(payload?[PayloadParameterKeys.sdkSource] as? String == "main")
                #expect(payload?[PayloadParameterKeys.acc] != nil)
                #expect(payload?[PayloadParameterKeys.aid] != nil)
                #expect(payload?.keys.contains(PayloadParameterKeys.sdkSource) == true)
            }
        }
        
        @Suite("When sdk_source is set to 'ext' in event parameters for rat.* events")
        struct SdkSourceExtTests {
            var helper = ProcessTestHelper.TestHelper()
            
            @Test("should use 'ext' value and not overwrite it")
            mutating func testShouldUseExtValue() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(name: "rat.test_event", parameters: ["sdk_source": "ext"])
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "test_event") {
                    payload = $0.first
                }
                
                try await TestingHelpers.eventually {
                    payload != nil
                }
                #expect(payload?[PayloadParameterKeys.sdkSource] as? String == "ext")
            }
            
            @Test("should preserve 'ext' value for custom events")
            mutating func testShouldPreserveExtForCustomEvents() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(
                    name: RAnalyticsEvent.Name.custom,
                    parameters: [
                        "eventName": "testEvent",
                        "sdk_source": "ext"
                    ])
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "testEvent") {
                    payload = $0.first
                }
                
                try await TestingHelpers.eventually {
                    payload != nil
                }
                #expect(payload?[PayloadParameterKeys.sdkSource] as? String == "ext")
            }
        }
        
        @Suite("When sdk_source is set to 'wrapper' in event parameters")
        struct SdkSourceWrapperTests {
            var helper = ProcessTestHelper.TestHelper()
            
            @Test("should use 'wrapper' value and not overwrite it")
            mutating func testShouldUseWrapperValue() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(name: "rat.test_event", parameters: ["sdk_source": "wrapper"])
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "test_event") {
                    payload = $0.first
                }
                
                try await TestingHelpers.eventually {
                    payload != nil
                }
                #expect(payload?[PayloadParameterKeys.sdkSource] as? String == "wrapper")
            }
        }
        
        @Suite("When sdk_source is already set in payload")
        struct SdkSourceAlreadySetTests {
            var helper = ProcessTestHelper.TestHelper()
            
            @Test("should not overwrite existing sdk_source value")
            mutating func testShouldNotOverwriteExistingSdkSource() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(name: "rat.test_event", parameters: ["sdk_source": "ext"])
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "test_event") {
                    payload = $0.first
                }
                
                try await TestingHelpers.eventually {
                    payload != nil
                }
                #expect(payload?[PayloadParameterKeys.sdkSource] as? String == "ext")
            }
        }
        
        @Suite("When sdk_source is set with empty string in rat.* events")
        struct SdkSourceEmptyStringTests {
            var helper = ProcessTestHelper.TestHelper()
            
            @Test("should use 'main' as default value")
            mutating func testShouldUseMainAsDefault() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(name: "rat.test_event",
                                            parameters: ["sdk_source": ""])
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: "test_event") {
                    payload = $0.first
                }
                
                try await TestingHelpers.eventually {
                    payload != nil
                }
                // Empty string in parameters gets added to payload, but addSdkSourceIfNeeded will set it to "main" if empty
                #expect(payload?[PayloadParameterKeys.sdkSource] as? String == "main")
            }
        }
        
        @Suite("sdk_source for different event types")
        struct SdkSourceDifferentEventTypesTests {
            var helper = ProcessTestHelper.TestHelper()
            
            @Test("should add sdk_source to initialLaunch event")
            mutating func testShouldAddSdkSourceToInitialLaunch() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.initialLaunch, parameters: nil)
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.initialLaunch) {
                    payload = $0.first
                }
                
                try await TestingHelpers.eventually {
                    payload != nil
                }
                #expect(payload?[PayloadParameterKeys.sdkSource] as? String == "main")
            }
            
            @Test("should add sdk_source to install event")
            mutating func testShouldAddSdkSourceToInstall() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.install, parameters: nil)
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.install) {
                    payload = $0.first
                }
                
                try await TestingHelpers.eventually {
                    payload != nil
                }
                #expect(payload?[PayloadParameterKeys.sdkSource] as? String == "main")
            }
            
            @Test("should add sdk_source to pageVisit event")
            mutating func testShouldAddSdkSourceToPageVisit() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                var payload: [String: Any]?
                
                let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                state.referralTracking = .page(currentPage: Tracking.customPage)
                
                try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.pageVisitForRAT) {
                    payload = $0.first
                }
                
                try await TestingHelpers.eventually {
                    payload != nil
                }
                #expect(payload?[PayloadParameterKeys.sdkSource] as? String == "main")
            }
        }
    }
}

// swiftlint:enable line_length
// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
// swiftlint:enable control_statement

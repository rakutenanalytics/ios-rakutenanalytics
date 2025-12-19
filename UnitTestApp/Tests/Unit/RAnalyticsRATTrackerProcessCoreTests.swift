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

// MARK: - RAnalyticsRATTrackerProcessCoreTests

@Suite("RAnalyticsRATTracker")
struct RAnalyticsRATTrackerProcessCoreTests {
    @Suite("process(event:state:)")
    struct ProcessEventStateTests {
        @Suite("When the RAT identifiers are not set")
        struct RatIdentifiersNotSetTests {
            @Test("should return false")
            func testShouldReturnFalse() {
                let bundle = BundleMock()
                bundle.accountIdentifier = 0
                bundle.applicationIdentifier = 0
                bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
                
                let dependenciesContainerWithoutRatIdsConf = SimpleContainerMock()
                dependenciesContainerWithoutRatIdsConf.bundle = bundle
                
                let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainerWithoutRatIdsConf)
                let result = ratTracker.process(event: Tracking.defaultEvent, state: Tracking.defaultState)
                
                #expect(result == false)
            }
        }
        
        @Suite("When the RAT identifiers are set")
        struct RatIdentifiersSetTests {
            @Test("should return true")
            func testShouldReturnTrue() {
                let bundle = BundleMock()
                bundle.accountIdentifier = 477
                bundle.applicationIdentifier = 1
                bundle.endpointAddress = URL(string: "https://endpoint.co.jp")
                
                let dependenciesContainerWithRatIdsConf = SimpleContainerMock()
                dependenciesContainerWithRatIdsConf.bundle = bundle
                
                let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainerWithRatIdsConf)
                let result = ratTracker.process(event: Tracking.defaultEvent, state: Tracking.defaultState)
                
                #expect(result == true)
            }
        }
        
        @Suite("Event processing")
        struct EventProcessingTests {
            var helper = ProcessTestHelper.TestHelper()
            
            @Test("should not process the event if the event name is unknown")
            mutating func testShouldNotProcessUnknownEvent() {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(name: "", parameters: nil)
                let processed = helper.ratTracker.process(event: event, state: Tracking.defaultState)
                #expect(processed == false)
            }
            
            @Test("should process the event if the event name prefix is rat.")
            mutating func testShouldProcessRatPrefixEvent() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") { _ in }
            }
            
            @Test("should process the initialLaunch event")
            mutating func testShouldProcessInitialLaunchEvent() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.initialLaunch, parameters: nil)
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.initialLaunch) { _ in }
            }
            
            @Test("should process the install event with Core Infos")
            mutating func testShouldProcessInstallEventWithCoreInfos() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                try await helper.verifyCoreInfos(for: RAnalyticsEvent.Name.install)
            }
            
            @Test("should process the sessionStart event")
            mutating func testShouldProcessSessionStartEvent() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                var cpPayload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.sessionStart) {
                    cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                }
                
                try await TestingHelpers.eventually {
                    cpPayload != nil
                }
                
                let daysSinceLastUse: Int! = cpPayload?["days_since_last_use"] as? Int
                let daysSinceFirstUse: Int! = cpPayload?["days_since_first_use"] as? Int
                #expect(daysSinceLastUse >= 0)
                #expect(daysSinceLastUse == daysSinceFirstUse - 2)
            }
            
            @Test("should process the sessionEnd event")
            mutating func testShouldProcessSessionEndEvent() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionEnd, parameters: nil)
                try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.sessionEnd) { _ in }
            }
            
            @Suite("applicationUpdate event")
            struct ApplicationUpdateEventTests {
                var helper = ProcessTestHelper.TestHelper()
                
                @Test("should process the applicationUpdate event with Core Infos")
                mutating func testShouldProcessApplicationUpdateEventWithCoreInfos() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    try await helper.verifyCoreInfos(for: RAnalyticsEvent.Name.applicationUpdate)
                }
                
                @Test("should process the applicationUpdate event with launches_since_last_upgrade and days_since_last_upgrade")
                mutating func testShouldProcessApplicationUpdateEventWithUpgradeInfo() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.applicationUpdate, parameters: nil)
                    var cpPayload: [String: Any]?
                    
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.applicationUpdate) {
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    
                    try await TestingHelpers.eventually {
                        cpPayload != nil
                    }
                    #expect((cpPayload?["launches_since_last_upgrade"] as? Int) ?? 0 > 0)
                    #expect((cpPayload?["days_since_last_upgrade"] as? Int) ?? 0 > 0)
                }
            }
            
            @Suite("Login")
            struct LoginTests {
                var helper = ProcessTestHelper.TestHelper()
                
                @Test("should process the login event when the login method is oneTapLogin")
                mutating func testShouldProcessLoginEventWithOneTapLogin() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.login, parameters: nil)
                    var cpPayload: [String: Any]?
                    
                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                    state.loginMethod = .oneTapLogin
                    
                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.login) {
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    try await TestingHelpers.eventually {
                        cpPayload != nil
                    }
                    #expect(cpPayload?["login_method"] as? String == RAnalyticsLoginMethod.oneTapLogin.toString)
                }
                
                @Test("should process the login event when the login method is passwordInput")
                mutating func testShouldProcessLoginEventWithPasswordInput() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.login, parameters: nil)
                    var cpPayload: [String: Any]?
                    
                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                    state.loginMethod = .passwordInput
                    
                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.login) {
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    try await TestingHelpers.eventually {
                        cpPayload != nil
                    }
                    #expect(cpPayload?["login_method"] as? String == RAnalyticsLoginMethod.passwordInput.toString)
                }
                
                @Test("should process the login event with an empty cp when the login method is other")
                mutating func testShouldProcessLoginEventWithOtherMethod() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.login, parameters: nil)
                    var cpPayload: [String: Any]?
                    
                    let state: RAnalyticsState! = Tracking.defaultState.copy() as? RAnalyticsState
                    state.loginMethod = .other
                    
                    try await helper.expecter.expectEventAsync(event, state: state, equal: RAnalyticsEvent.Name.login) {
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    
                    try await TestingHelpers.performAsyncTest(timeForExecution: 1.0, timeout: 1.0) {
                        #expect(cpPayload == nil)
                    }
                }
            }
            
            @Suite("Logout")
            struct LogoutTests {
                var helper = ProcessTestHelper.TestHelper()
                
                @Test("should process the logout event when the login method is local")
                mutating func testShouldProcessLogoutEventWithLocal() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.logout,
                                                parameters: [RAnalyticsEvent.Parameter.logoutMethod: RAnalyticsEvent.LogoutMethod.local])
                    var cpPayload: [String: Any]?
                    
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.logout) {
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    try await TestingHelpers.eventually {
                        cpPayload != nil
                    }
                    #expect(cpPayload?["logout_method"] as? String == RAnalyticsEvent.LogoutMethod.local.toLogoutString)
                }
                
                @Test("should process the logout event when the login method is global")
                mutating func testShouldProcessLogoutEventWithGlobal() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.logout,
                                                parameters: [RAnalyticsEvent.Parameter.logoutMethod: RAnalyticsEvent.LogoutMethod.global])
                    var cpPayload: [String: Any]?
                    
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.logout) {
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    try await TestingHelpers.eventually {
                        cpPayload != nil
                    }
                    #expect(cpPayload?["logout_method"] as? String == RAnalyticsEvent.LogoutMethod.global.toLogoutString)
                }
                
                @Test("should process the logout event with an empty cp when the login method is empty")
                mutating func testShouldProcessLogoutEventWithEmptyMethod() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.logout, parameters: nil)
                    var cpPayload: [String: Any]?
                    
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.logout) {
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    try await TestingHelpers.eventually {
                        cpPayload == nil
                    }
                }
            }
            
            @Suite("Login Failure")
            struct LoginFailureTests {
                var helper = ProcessTestHelper.TestHelper()
                
                @Test("should process the loginFailure event when there is a password login error")
                mutating func testShouldProcessLoginFailureWithPasswordError() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginFailure,
                                                parameters: ["type": "password_login", "rae_error": "invalid_grant"])
                    var cpPayload: [String: Any]?
                    
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginFailure) {
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    try await TestingHelpers.eventually {
                        cpPayload != nil
                    }
                    #expect(cpPayload?["type"] as? String == "password_login")
                    #expect(cpPayload?["rae_error"] as? String == "invalid_grant")
                }
                
                @Test("should process the loginFailure event when there is a sso login error")
                mutating func testShouldProcessLoginFailureWithSSOError() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginFailure,
                                                parameters: ["type": "sso_login", "rae_error": "invalid_scope"])
                    var cpPayload: [String: Any]?
                    
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginFailure) {
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    try await TestingHelpers.eventually {
                        cpPayload != nil
                    }
                    #expect(cpPayload?["type"] as? String == "sso_login")
                    #expect(cpPayload?["rae_error"] as? String == "invalid_scope")
                }
                
                @Test("should process the loginFailure event when there is a IDSDK login error")
                mutating func testShouldProcessLoginFailureWithIDSDKError() async throws {
                    helper.setUp()
                    defer { helper.tearDown() }
                    
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.loginFailure,
                                                parameters: ["idsdk_error": "IDSDK Login Error", "idsdk_error_message": "Network Error"])
                    var cpPayload: [String: Any]?
                    
                    try await helper.expecter.expectEventAsync(event, state: Tracking.defaultState, equal: RAnalyticsEvent.Name.loginFailure) {
                        cpPayload = $0.first?[PayloadParameterKeys.cp] as? [String: Any]
                    }
                    try await TestingHelpers.eventually {
                        cpPayload != nil
                    }
                    #expect(cpPayload?["idsdk_error"] as? String == "IDSDK Login Error")
                    #expect(cpPayload?["idsdk_error_message"] as? String == "Network Error")
                }
            }
        }
    }
}

// swiftlint:enable line_length
// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
// swiftlint:enable control_statement

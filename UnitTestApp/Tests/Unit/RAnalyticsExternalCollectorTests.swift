// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import Testing
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsExternalCollectorTests

@Suite("RAnalyticsExternalCollector")
struct RAnalyticsExternalCollectorTests {
    static let notificationBaseName = "com.rakuten.esd.sdk.events"
    
    var dependenciesContainer: SimpleContainerMock!
    let raeErrorParams = ["rae_error": "login failure",
                          "rae_error_message": "login fails",
                          "type": "login.failure"]
    let idsdkError = NSError(domain: "com.analytics.error",
                             code: 0,
                             userInfo: [NSLocalizedDescriptionKey: "login failure", NSLocalizedFailureReasonErrorKey: "login fails"])
    let tracker = AnalyticsTrackerMock()
    var externalCollector: RAnalyticsExternalCollector!
    
    mutating func setUp() {
        dependenciesContainer = SimpleContainerMock()
        dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
        (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
        dependenciesContainer.keychainHandler = KeychainHandlerMock()
        
        externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
        externalCollector.trackerDelegate = tracker
    }
    
    mutating func tearDown() {
        tracker.reset()
    }
    
    @Suite("init")
    struct InitTests {
        var dependenciesContainer: SimpleContainerMock!
        var externalCollector: RAnalyticsExternalCollector!
        
        init() {
            dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
            dependenciesContainer.keychainHandler = KeychainHandlerMock()
            
            externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
        }
        
        @Test("should have the correct default values")
        func testShouldHaveTheCorrectDefaultValues() {
            #expect(externalCollector.isLoggedIn == false)
            #expect(externalCollector.trackingIdentifier == nil)
            #expect(externalCollector.userIdentifier == nil)
            #expect(externalCollector.loginMethod == .other)
        }
    }
    
    @Suite("userIdentifier")
    struct UserIdentifierTests {
        var dependenciesContainer: SimpleContainerMock!
        var externalCollector: RAnalyticsExternalCollector!
        
        init() {
            dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
            dependenciesContainer.keychainHandler = KeychainHandlerMock()
            
            externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
        }
        
        @Test("should set the expected value")
        func testShouldSetTheExpectedValue() {
            externalCollector.userIdentifier = "myUserID"
            #expect(externalCollector.userIdentifier == "myUserID")
        }
        
        @Test("should save the user identifier in the user defaults")
        func testShouldSaveTheUserIdentifierInTheUserDefaults() {
            externalCollector.userIdentifier = "myUserID"
            let value = dependenciesContainer.userStorageHandler.string(forKey: RAnalyticsExternalCollector.Constants.userIdentifierKey)
            #expect(value == "myUserID")
        }
        
        @Test("should delete the user identifier from the user defaults")
        func testShouldDeleteTheUserIdentifierFromTheUserDefaults() {
            externalCollector.userIdentifier = nil
            let value = dependenciesContainer.userStorageHandler.string(forKey: RAnalyticsExternalCollector.Constants.userIdentifierKey)
            #expect(value == nil)
        }
    }
    
    @Suite("easyIdentifier")
    struct EasyIdentifierTests {
        var dependenciesContainer: SimpleContainerMock!
        var externalCollector: RAnalyticsExternalCollector!
        
        init() {
            dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
            dependenciesContainer.keychainHandler = KeychainHandlerMock()
            
            externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
        }
        
        @Suite("When the easy identifier is set to a non-nil value")
        struct WhenEasyIdentifierIsSetToNonNilValueTests {
            var dependenciesContainer: SimpleContainerMock!
            var externalCollector: RAnalyticsExternalCollector!
            
            init() {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
                (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                dependenciesContainer.keychainHandler = KeychainHandlerMock()
                
                externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
            }
            
            @Test("should have the expected value")
            func testShouldHaveTheExpectedValue() {
                externalCollector.easyIdentifier = "myEasyID"
                #expect(externalCollector.easyIdentifier == "myEasyID")
            }
            
            @Test("should save the easy identifier in the keychain")
            func testShouldSaveTheEasyIdentifierInTheKeychain() throws {
                externalCollector.easyIdentifier = "myEasyID"
                let value = try? dependenciesContainer.keychainHandler.string(for: RAnalyticsExternalCollector.Constants.easyIdentifierKey)
                #expect(value == "myEasyID")
            }
        }
        
        @Suite("When the easy identifier is set to nil")
        struct WhenEasyIdentifierIsSetToNilTests {
            var dependenciesContainer: SimpleContainerMock!
            var externalCollector: RAnalyticsExternalCollector!
            
            init() {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
                (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                dependenciesContainer.keychainHandler = KeychainHandlerMock()
                
                externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
            }
            
            @Test("should return nil")
            func testShouldReturnNil() {
                externalCollector.easyIdentifier = nil
                #expect(externalCollector.easyIdentifier == nil)
            }
            
            @Test("should delete the easy identifier from the keychain")
            func testShouldDeleteTheEasyIdentifierFromTheKeychain() throws {
                externalCollector.easyIdentifier = nil
                let value = try? dependenciesContainer.keychainHandler.string(for: RAnalyticsExternalCollector.Constants.easyIdentifierKey)
                #expect(value == nil)
            }
        }
        
        @Suite("When an easy identifier is already stored in the user defaults")
        struct WhenEasyIdentifierIsAlreadyStoredInUserDefaultsTests {
            var dependenciesContainer: SimpleContainerMock!
            
            init() {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
                (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                dependenciesContainer.keychainHandler = KeychainHandlerMock()
            }
            
            @Test("should return an expected easy identifier value")
            func testShouldReturnAnExpectedEasyIdentifierValue() {
                dependenciesContainer.userStorageHandler.set(value: "myEasyID", forKey: RAnalyticsExternalCollector.Constants.easyIdentifierKey)
                
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                #expect(externalCollector.easyIdentifier == "myEasyID")
            }
            
            @Test("should save the easy identifier to the keychain")
            func testShouldSaveTheEasyIdentifierToTheKeychain() throws {
                dependenciesContainer.userStorageHandler.set(value: "myEasyID", forKey: RAnalyticsExternalCollector.Constants.easyIdentifierKey)
                
                _ = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                
                let value = try? dependenciesContainer.keychainHandler.string(for: RAnalyticsExternalCollector.Constants.easyIdentifierKey)
                #expect(value == "myEasyID")
            }
        }
        
        @Suite("When an easy identifier is not stored in the user defaults")
        struct WhenEasyIdentifierIsNotStoredInUserDefaultsTests {
            var dependenciesContainer: SimpleContainerMock!
            
            init() {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
                (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                dependenciesContainer.keychainHandler = KeychainHandlerMock()
            }
            
            @Test("should return a nil value")
            func testShouldReturnANilValue() {
                dependenciesContainer.userStorageHandler.set(value: nil, forKey: RAnalyticsExternalCollector.Constants.easyIdentifierKey)
                
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                #expect(externalCollector.easyIdentifier == nil)
            }
            
            @Test("should not save the easy identifier to the keychain")
            func testShouldNotSaveTheEasyIdentifierToTheKeychain() throws {
                dependenciesContainer.userStorageHandler.set(value: nil, forKey: RAnalyticsExternalCollector.Constants.easyIdentifierKey)
                
                _ = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                
                let value = try? dependenciesContainer.keychainHandler.string(for: RAnalyticsExternalCollector.Constants.easyIdentifierKey)
                #expect(value == nil)
            }
        }
    }
    
    @Suite("trackLogin()")
    struct TrackLoginTests {
        var dependenciesContainer: SimpleContainerMock!
        let tracker = AnalyticsTrackerMock()
        var externalCollector: RAnalyticsExternalCollector!
        
        init() {
            dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
            dependenciesContainer.keychainHandler = KeychainHandlerMock()
            
            externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
            externalCollector.trackerDelegate = tracker
        }
        
        mutating func tearDown() {
            tracker.reset()
        }
        
        @Suite("RAE Login succeeds")
        struct RAELoginSucceedsTests {
            var dependenciesContainer: SimpleContainerMock!
            let tracker = AnalyticsTrackerMock()
            var externalCollector: RAnalyticsExternalCollector!
            
            init() {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
                (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                dependenciesContainer.keychainHandler = KeychainHandlerMock()
                
                externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
            }
            
            mutating func tearDown() {
                tracker.reset()
            }
            
            @Test("should set trackingIdentifier to userIdentifier")
            func testShouldSetTrackingIdentifierToUserIdentifier() {
                externalCollector.trackLogin(.userIdentifier("userIdentifier"))
                #expect(externalCollector.trackingIdentifier == "userIdentifier")
            }
            
            @Test("should set isLoggedIn to true")
            func testShouldSetIsLoggedInToTrue() {
                externalCollector.trackLogin(.userIdentifier("userIdentifier"))
                #expect(externalCollector.isLoggedIn == true)
            }
            
            @Test("should track AnalyticsManager.Event.Name.login with no parameters")
            func testShouldTrackLoginEventWithNoParameters() {
                externalCollector.trackLogin(.userIdentifier("userIdentifier"))
                #expect(tracker.eventName == AnalyticsManager.Event.Name.login)
                #expect(tracker.params == nil)
            }
        }
        
        @Suite("IDSDK Login succeeds")
        struct IDSDKLoginSucceedsTests {
            var dependenciesContainer: SimpleContainerMock!
            let tracker = AnalyticsTrackerMock()
            var externalCollector: RAnalyticsExternalCollector!
            
            init() {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
                (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                dependenciesContainer.keychainHandler = KeychainHandlerMock()
                
                externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
            }
            
            mutating func tearDown() {
                tracker.reset()
            }
            
            @Test("should set easyIdentifier to idsdkIdentifier")
            func testShouldSetEasyIdentifierToIdsdkIdentifier() {
                externalCollector.trackLogin(.easyIdentifier("idsdkIdentifier"))
                #expect(externalCollector.easyIdentifier == "idsdkIdentifier")
            }
            
            @Test("should set isLoggedIn to true")
            func testShouldSetIsLoggedInToTrue() {
                externalCollector.trackLogin(.easyIdentifier("idsdkIdentifier"))
                #expect(externalCollector.isLoggedIn == true)
            }
            
            @Test("should track AnalyticsManager.Event.Name.login with no parameters")
            func testShouldTrackLoginEventWithNoParameters() {
                externalCollector.trackLogin(.easyIdentifier("idsdkIdentifier"))
                #expect(tracker.eventName == AnalyticsManager.Event.Name.login)
                #expect(tracker.params == nil)
            }
        }
    }
    
    @Suite("trackLoginFailure()")
    struct TrackLoginFailureTests {
        let raeErrorParams = ["rae_error": "login failure",
                              "rae_error_message": "login fails",
                              "type": "login.failure"]
        let idsdkError = NSError(domain: "com.analytics.error",
                                 code: 0,
                                 userInfo: [NSLocalizedDescriptionKey: "login failure", NSLocalizedFailureReasonErrorKey: "login fails"])
        var dependenciesContainer: SimpleContainerMock!
        let tracker = AnalyticsTrackerMock()
        var externalCollector: RAnalyticsExternalCollector!
        
        init() {
            dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
            dependenciesContainer.keychainHandler = KeychainHandlerMock()
            
            externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
            externalCollector.trackerDelegate = tracker
        }
        
        mutating func tearDown() {
            tracker.reset()
        }
        
        @Suite("RAE Login fails")
        struct RAELoginFailsTests {
            let raeErrorParams = ["rae_error": "login failure",
                                  "rae_error_message": "login fails",
                                  "type": "login.failure"]
            var dependenciesContainer: SimpleContainerMock!
            let tracker = AnalyticsTrackerMock()
            var externalCollector: RAnalyticsExternalCollector!
            
            init() {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
                (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                dependenciesContainer.keychainHandler = KeychainHandlerMock()
                
                externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
            }
            
            mutating func tearDown() {
                tracker.reset()
            }
            
            @Test("should set trackingIdentifier to nil")
            func testShouldSetTrackingIdentifierToNil() {
                externalCollector.trackLoginFailure(.userIdentifier(dictionary: raeErrorParams))
                #expect(externalCollector.trackingIdentifier == nil)
            }
            
            @Test("should set isLoggedIn to false")
            func testShouldSetIsLoggedInToFalse() {
                externalCollector.trackLoginFailure(.userIdentifier(dictionary: raeErrorParams))
                #expect(externalCollector.isLoggedIn == false)
            }
            
            @Test("should track AnalyticsManager.Event.Name.loginFailure with parameters")
            func testShouldTrackLoginFailureEventWithParameters() {
                externalCollector.trackLoginFailure(.userIdentifier(dictionary: raeErrorParams))
                
                #expect(tracker.eventName == AnalyticsManager.Event.Name.loginFailure)
                #expect(tracker.params?["rae_error"] as? String == raeErrorParams["rae_error"])
                #expect(tracker.params?["rae_error_message"] as? String == raeErrorParams["rae_error_message"])
                #expect(tracker.params?["type"] as? String == raeErrorParams["type"])
            }
        }
        
        @Suite("IDSDK Login fails")
        struct IDSDKLoginFailsTests {
            let idsdkError = NSError(domain: "com.analytics.error",
                                     code: 0,
                                     userInfo: [NSLocalizedDescriptionKey: "login failure", NSLocalizedFailureReasonErrorKey: "login fails"])
            var dependenciesContainer: SimpleContainerMock!
            let tracker = AnalyticsTrackerMock()
            var externalCollector: RAnalyticsExternalCollector!
            
            init() {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
                (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                dependenciesContainer.keychainHandler = KeychainHandlerMock()
                
                externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
            }
            
            mutating func tearDown() {
                tracker.reset()
            }
            
            @Test("should set easyIdentifier to nil")
            func testShouldSetEasyIdentifierToNil() {
                externalCollector.trackLoginFailure(.easyIdentifier(error: idsdkError))
                #expect(externalCollector.easyIdentifier == nil)
            }
            
            @Test("should set isLoggedIn to false")
            func testShouldSetIsLoggedInToFalse() {
                externalCollector.trackLoginFailure(.easyIdentifier(error: idsdkError))
                #expect(externalCollector.isLoggedIn == false)
            }
            
            @Test("should track AnalyticsManager.Event.Name.loginFailure with parameters")
            func testShouldTrackLoginFailureEventWithParameters() {
                externalCollector.trackLoginFailure(.easyIdentifier(error: idsdkError))
                
                #expect(tracker.eventName == AnalyticsManager.Event.Name.loginFailure)
                #expect(tracker.params?["idsdk_error"] as? String == idsdkError.localizedDescription)
                #expect(tracker.params?["idsdk_error_message"] as? String == idsdkError.localizedFailureReason)
            }
        }
    }
    
    @Suite("trackLogout()")
    struct TrackLogoutTests {
        var dependenciesContainer: SimpleContainerMock!
        let tracker = AnalyticsTrackerMock()
        var externalCollector: RAnalyticsExternalCollector!
        
        init() {
            dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
            dependenciesContainer.keychainHandler = KeychainHandlerMock()
            
            externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
            externalCollector.trackerDelegate = tracker
        }
        
        mutating func tearDown() {
            tracker.reset()
        }
        
        @Suite("RAE Logout")
        struct RAELogoutTests {
            var dependenciesContainer: SimpleContainerMock!
            let tracker = AnalyticsTrackerMock()
            var externalCollector: RAnalyticsExternalCollector!
            
            init() {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
                (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                dependenciesContainer.keychainHandler = KeychainHandlerMock()
                
                externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
            }
            
            mutating func tearDown() {
                tracker.reset()
            }
            
            @Test("should set trackingIdentifier to nil")
            func testShouldSetTrackingIdentifierToNil() {
                externalCollector.trackLogout()
                #expect(externalCollector.trackingIdentifier == nil)
            }
            
            @Test("should set isLoggedIn to false")
            func testShouldSetIsLoggedInToFalse() {
                externalCollector.trackLogout()
                #expect(externalCollector.isLoggedIn == false)
            }
            
            @Test("should track AnalyticsManager.Event.Name.logout with no parameters")
            func testShouldTrackLogoutEventWithNoParameters() {
                externalCollector.trackLogout()
                
                #expect(tracker.eventName == AnalyticsManager.Event.Name.logout)
                #expect(tracker.params as? [String: AnyHashable] == [:])
            }
        }
        
        @Suite("IDSDK Logout")
        struct IDSDKLogoutTests {
            var dependenciesContainer: SimpleContainerMock!
            let tracker = AnalyticsTrackerMock()
            var externalCollector: RAnalyticsExternalCollector!
            
            init() {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
                (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                dependenciesContainer.keychainHandler = KeychainHandlerMock()
                
                externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
            }
            
            mutating func tearDown() {
                tracker.reset()
            }
            
            @Test("should set easyIdentifier to nil")
            func testShouldSetEasyIdentifierToNil() {
                externalCollector.trackLogout()
                #expect(externalCollector.easyIdentifier == nil)
            }
            
            @Test("should set isLoggedIn to false")
            func testShouldSetIsLoggedInToFalse() {
                externalCollector.trackLogout()
                #expect(externalCollector.isLoggedIn == false)
            }
            
            @Test("should track AnalyticsManager.Event.Name.logout with no parameters")
            func testShouldTrackLogoutEventWithNoParameters() {
                externalCollector.trackLogout()
                #expect(tracker.eventName == AnalyticsManager.Event.Name.logout)
                #expect(tracker.params as? [String: AnyHashable] == [:])
            }
        }
    }
    
    @Suite("receiveLoginNotification")
    struct ReceiveLoginNotificationTests {
        static let notificationBaseName = RAnalyticsExternalCollectorTests.notificationBaseName
        
        var dependenciesContainer: SimpleContainerMock!
        let tracker = AnalyticsTrackerMock()
        
        init() {
            dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
            dependenciesContainer.keychainHandler = KeychainHandlerMock()
        }
        
        mutating func tearDown() {
            tracker.reset()
        }
        
        @Suite("login methods are password and one_tap")
        struct LoginMethodsArePasswordAndOneTapTests {
            static let notificationBaseName = RAnalyticsExternalCollectorTests.notificationBaseName
            
            var dependenciesContainer: SimpleContainerMock!
            let tracker = AnalyticsTrackerMock()
            
            init() {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
                (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                dependenciesContainer.keychainHandler = KeychainHandlerMock()
            }
            
            mutating func tearDown() {
                tracker.reset()
            }
            
            @Test("should track AnalyticsManager.Event.Name.login when a login notification is received with a trackingIdentifier")
            @MainActor
            func testShouldTrackLoginWhenLoginNotificationIsReceivedWithTrackingIdentifier() async throws {
                let trackingIdentifier = "trackingIdentifier"
                let loginMethods = ["password", "one_tap"]
                
                for loginMethod in loginMethods {
                    (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                    
                    let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                    externalCollector.trackerDelegate = tracker
                    let notificationName = Notification.Name(rawValue: "\(Self.notificationBaseName).login.\(loginMethod)")
                    #expect(externalCollector.trackingIdentifier == nil)
                    #expect(externalCollector.loginMethod == .other)
                    #expect(externalCollector.isLoggedIn == false)
                    #expect(tracker.eventName == nil)
                    #expect(tracker.params == nil)
                    
                    NotificationCenter.default.post(name: notificationName, object: trackingIdentifier)
                    
                    try await TestingHelpers.eventuallyOnMain { externalCollector.trackingIdentifier == trackingIdentifier }
                    
                    switch loginMethod {
                    case "password":
                        try await TestingHelpers.eventuallyOnMain { externalCollector.loginMethod == .passwordInput }
                    case "one_tap":
                        try await TestingHelpers.eventuallyOnMain { externalCollector.loginMethod == .oneTapLogin }
                    default:
                        break
                    }
                    
                    try await TestingHelpers.eventuallyOnMain { externalCollector.isLoggedIn == true }
                    try await TestingHelpers.eventuallyOnMain { tracker.eventName == AnalyticsManager.Event.Name.login }
                    #expect(tracker.params == nil)
                    tracker.reset()
                }
            }
        }
        
        @Suite("login method is other")
        struct LoginMethodIsOtherTests {
            static let notificationBaseName = RAnalyticsExternalCollectorTests.notificationBaseName
            
            var dependenciesContainer: SimpleContainerMock!
            let tracker = AnalyticsTrackerMock()
            var externalCollector: RAnalyticsExternalCollector!
            
            init() {
                dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
                (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                dependenciesContainer.keychainHandler = KeychainHandlerMock()
                
                externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
            }
            
            mutating func tearDown() {
                tracker.reset()
            }
            
            @Test("should track AnalyticsManager.Event.Name.login when a login notification is received")
            @MainActor
            func testShouldTrackLoginWhenLoginNotificationIsReceived() async throws {
                let trackingIdentifier = "trackingIdentifier"
                let notificationName = Notification.Name(rawValue: "\(Self.notificationBaseName).login.other")
                
                #expect(externalCollector.trackingIdentifier == nil)
                #expect(externalCollector.loginMethod == .other)
                #expect(externalCollector.isLoggedIn == false)
                #expect(tracker.eventName == nil)
                #expect(tracker.params == nil)
                
                let passwordNotificationName = Notification.Name(rawValue: "\(Self.notificationBaseName).login.password")
                NotificationCenter.default.post(name: passwordNotificationName, object: trackingIdentifier)
                
                try await TestingHelpers.eventuallyOnMain { externalCollector.loginMethod == .passwordInput }
                tracker.reset()
                
                NotificationCenter.default.post(name: notificationName, object: trackingIdentifier)
                
                try await TestingHelpers.eventuallyOnMain { externalCollector.trackingIdentifier == trackingIdentifier }
                #expect(externalCollector.loginMethod == .other)
                #expect(externalCollector.isLoggedIn == true)
                try await TestingHelpers.eventuallyOnMain { tracker.eventName == AnalyticsManager.Event.Name.login }
                #expect(tracker.params == nil)
                tracker.reset()
            }
            
            @Test("should track AnalyticsManager.Event.Name.login when an IDSDK login notification is received")
            @MainActor
            func testShouldTrackLoginWhenIDSDKLoginNotificationIsReceived() async throws {
                let easyIdentifier = "easyIdentifier"
                let notificationName = Notification.Name(rawValue: "\(Self.notificationBaseName).login.idtoken_memberid")
                
                #expect(externalCollector.easyIdentifier == nil)
                #expect(externalCollector.loginMethod == .other)
                #expect(externalCollector.isLoggedIn == false)
                #expect(tracker.eventName == nil)
                #expect(tracker.params == nil)
                
                let passwordNotificationName = Notification.Name(rawValue: "\(Self.notificationBaseName).login.password")
                NotificationCenter.default.post(name: passwordNotificationName, object: easyIdentifier)
                
                try await TestingHelpers.eventuallyOnMain { externalCollector.loginMethod == .passwordInput }
                tracker.reset()
                
                NotificationCenter.default.post(name: notificationName, object: easyIdentifier)
                
                try await TestingHelpers.eventuallyOnMain { externalCollector.easyIdentifier == easyIdentifier }
                #expect(externalCollector.loginMethod == .other)
                #expect(externalCollector.isLoggedIn == true)
                try await TestingHelpers.eventuallyOnMain { tracker.eventName == AnalyticsManager.Event.Name.login }
                #expect(tracker.params == nil)
                tracker.reset()
            }
        }
    }
    
    @Suite("receiveLoginFailureNotification")
    struct ReceiveLoginFailureNotificationTests {
        static let notificationBaseName = RAnalyticsExternalCollectorTests.notificationBaseName
        let raeErrorParams = ["rae_error": "login failure",
                              "rae_error_message": "login fails",
                              "type": "login.failure"]
        let idsdkError = NSError(domain: "com.analytics.error",
                                 code: 0,
                                 userInfo: [NSLocalizedDescriptionKey: "login failure", NSLocalizedFailureReasonErrorKey: "login fails"])
        var dependenciesContainer: SimpleContainerMock!
        let tracker = AnalyticsTrackerMock()
        var externalCollector: RAnalyticsExternalCollector!
        
        init() {
            dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
            dependenciesContainer.keychainHandler = KeychainHandlerMock()
            
            externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
            externalCollector.trackerDelegate = tracker
        }
        
        mutating func tearDown() {
            tracker.reset()
        }
        
        @Test("should track AnalyticsManager.Event.Name.loginFailure when a login failure notification is received")
        @MainActor
        func testShouldTrackLoginFailureWhenLoginFailureNotificationIsReceived() async throws {
            let notificationNames = ["\(Self.notificationBaseName).login.failure",
                                     "\(Self.notificationBaseName).login.failure.idtoken_memberid"]
            
            for notificationName in notificationNames {
                #expect(externalCollector.isLoggedIn == false)
                #expect(tracker.eventName == nil)
                #expect(tracker.params == nil)
                
                switch notificationName {
                case "\(Self.notificationBaseName).login.failure":
                    NotificationCenter.default.post(name: Notification.Name(rawValue: notificationName), object: raeErrorParams)
                    
                case "\(Self.notificationBaseName).login.failure.idtoken_memberid":
                    NotificationCenter.default.post(name: Notification.Name(rawValue: notificationName), object: idsdkError)
                    
                default:
                    assertionFailure("Unexpected login failure case.")
                }
                
                try await TestingHelpers.performAsyncTestOnMain(timeForExecution: 1.0, timeout: 1.0) {
                    #expect(externalCollector.isLoggedIn == false)
                }
                try await TestingHelpers.eventuallyOnMain { tracker.eventName == AnalyticsManager.Event.Name.loginFailure }
                
                switch notificationName {
                case "\(Self.notificationBaseName).login.failure":
                    try await TestingHelpers.eventuallyOnMain { tracker.params?["rae_error"] as? String == raeErrorParams["rae_error"] }
                    try await TestingHelpers.eventuallyOnMain { tracker.params?["rae_error_message"] as? String == raeErrorParams["rae_error_message"] }
                    try await TestingHelpers.eventuallyOnMain { tracker.params?["type"] as? String == raeErrorParams["type"] }
                    
                case "\(Self.notificationBaseName).login.failure.idtoken_memberid":
                    try await TestingHelpers.eventuallyOnMain { tracker.params?["idsdk_error"] as? String == idsdkError.localizedDescription }
                    try await TestingHelpers.eventuallyOnMain { tracker.params?["idsdk_error_message"] as? String == idsdkError.localizedFailureReason }
                    
                default:
                    assertionFailure("Unexpected login failure case.")
                }
                
                tracker.reset()
            }
        }
    }
    
    @Suite("receiveLogoutNotification")
    struct ReceiveLogoutNotificationTests {
        static let notificationBaseName = RAnalyticsExternalCollectorTests.notificationBaseName
        
        var dependenciesContainer: SimpleContainerMock!
        let tracker = AnalyticsTrackerMock()
        
        init() {
            dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
            dependenciesContainer.keychainHandler = KeychainHandlerMock()
        }
        
        mutating func tearDown() {
            tracker.reset()
        }
        
        @Test("should track AnalyticsManager.Event.Name.logout when a logout notification is received")
        @MainActor
        func testShouldTrackLogoutWhenLogoutNotificationIsReceived() async throws {
            let trackingIdentifier = "trackingIdentifier"
            let logoutMethods = ["local", "global", "idtoken_memberid"]
            
            for logoutMethod in logoutMethods {
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
                let notificationName = Notification.Name(rawValue: "\(Self.notificationBaseName).logout.\(logoutMethod)")
                
                #expect(externalCollector.trackingIdentifier == nil)
                #expect(externalCollector.easyIdentifier == nil)
                #expect(externalCollector.isLoggedIn == false)
                #expect(tracker.eventName == nil)
                #expect(tracker.params == nil)
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "\(Self.notificationBaseName).login.other"), object: trackingIdentifier)
                
                try await TestingHelpers.eventuallyOnMain { externalCollector.isLoggedIn == true }
                try await TestingHelpers.eventuallyOnMain { externalCollector.trackingIdentifier == trackingIdentifier }
                tracker.reset()
                
                NotificationCenter.default.post(name: notificationName, object: nil)
                
                try await TestingHelpers.performAsyncTestOnMain(timeForExecution: 1.0, timeout: 1.0) {
                    #expect(externalCollector.trackingIdentifier == nil)
                }
                #expect(externalCollector.easyIdentifier == nil)
                #expect(externalCollector.isLoggedIn == false)
                try await TestingHelpers.eventuallyOnMain { tracker.eventName == AnalyticsManager.Event.Name.logout }
                
                if logoutMethod == "local" || logoutMethod == "global" {
                    try await TestingHelpers.eventuallyOnMain { tracker.params?[AnalyticsManager.Event.Parameter.logoutMethod] as? String == logoutMethod }
                    
                } else {
                    try await TestingHelpers.performAsyncTestOnMain(timeForExecution: 1.0, timeout: 1.0) {
                        #expect(tracker.params?[AnalyticsManager.Event.Parameter.logoutMethod] as? String == nil)
                    }
                }
                
                tracker.reset()
            }
        }
    }
    
    @Suite("receiveDiscoverNotification")
    struct ReceiveDiscoverNotificationTests {
        static let notificationBaseName = RAnalyticsExternalCollectorTests.notificationBaseName
        
        var dependenciesContainer: SimpleContainerMock!
        let tracker = AnalyticsTrackerMock()
        
        init() {
            dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
            dependenciesContainer.keychainHandler = KeychainHandlerMock()
        }
        
        mutating func tearDown() {
            tracker.reset()
        }
        
        @Test("should track a discover event when a discover notification is received")
        @MainActor
        func testShouldTrackDiscoverEventWhenDiscoverNotificationIsReceived() async throws {
            let mapping = ["visitPreview": NSNotification.discoverPreviewVisit,
                           "tapShowMore": NSNotification.discoverPreviewShowMore,
                           "visitPage": NSNotification.discoverPageVisit]
            
            for (key, value) in mapping {
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
                #expect(externalCollector.isLoggedIn == false)
                
                let notificationName = Notification.Name(rawValue: "\(Self.notificationBaseName).discover.\(key)")
                
                #expect(tracker.eventName == nil)
                #expect(tracker.params == nil)
                
                NotificationCenter.default.post(name: notificationName, object: nil)
                
                try await TestingHelpers.eventuallyOnMain { tracker.eventName == value.rawValue }
                try await TestingHelpers.eventuallyOnMain { tracker.params == nil }
                tracker.reset()
            }
        }
        
        @Test("should track a discover event with the correct identifier when a discover notification is received with an identifier")
        @MainActor
        func testShouldTrackDiscoverEventWithCorrectIdentifierWhenDiscoverNotificationIsReceivedWithIdentifier() async throws {
            let identifier = "12345"
            let mapping = ["tapPreview": NSNotification.discoverPreviewTap, "tapPage": NSNotification.discoverPageTap]
            
            for (key, value) in mapping {
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
                #expect(externalCollector.isLoggedIn == false)
                
                let notificationName = Notification.Name(rawValue: "\(Self.notificationBaseName).discover.\(key)")
                
                #expect(tracker.eventName == nil)
                #expect(tracker.params == nil)
                
                NotificationCenter.default.post(name: notificationName, object: identifier)
                
                try await TestingHelpers.eventuallyOnMain { tracker.eventName == value.rawValue }
                try await TestingHelpers.eventuallyOnMain { tracker.params?["prApp"] as? String == identifier }
                tracker.reset()
            }
        }
        
        @Test("should track a discover event with correct parameters when a discover notification is received with an identifier and url")
        @MainActor
        func testShouldTrackDiscoverEventWithCorrectParametersWhenDiscoverNotificationIsReceivedWithIdentifierAndUrl() async throws {
            let identifier = "12345"
            let urlString = "http://www.rakuten.co.jp"
            let mapping = ["redirectPreview": NSNotification.discoverPreviewRedirect, "redirectPage": NSNotification.discoverPageRedirect]
            
            for (key, value) in mapping {
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
                #expect(externalCollector.isLoggedIn == false)
                
                let notificationName = Notification.Name(rawValue: "\(Self.notificationBaseName).discover.\(key)")
                
                #expect(tracker.eventName == nil)
                #expect(tracker.params == nil)
                
                NotificationCenter.default.post(name: notificationName, object: ["identifier": identifier, "url": urlString])
                
                try await TestingHelpers.eventuallyOnMain { tracker.eventName == value.rawValue }
                try await TestingHelpers.eventuallyOnMain { tracker.params?["prApp"] as? String == identifier }
                try await TestingHelpers.eventuallyOnMain { tracker.params?["prStoreUrl"] as? String == urlString }
                tracker.reset()
            }
        }
    }
    
    @Suite("receiveSSODialogNotification")
    struct ReceiveSSODialogNotificationTests {
        static let notificationBaseName = RAnalyticsExternalCollectorTests.notificationBaseName
        
        var dependenciesContainer: SimpleContainerMock!
        let tracker = AnalyticsTrackerMock()
        
        init() {
            dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
            dependenciesContainer.keychainHandler = KeychainHandlerMock()
        }
        
        mutating func tearDown() {
            tracker.reset()
        }
        
        @Test("should track AnalyticsManager.Event.Name.pageVisit when a ssodialog notification is received")
        @MainActor
        func testShouldTrackPageVisitWhenSSODialogNotificationIsReceived() async throws {
            let uiViewControllerType = UIViewController.self
            let ssodialogParams = ["help", "privacypolicy", "forgotpassword", "register"]
            
            for param in ssodialogParams {
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
                #expect(externalCollector.isLoggedIn == false)
                
                let notificationName = Notification.Name(rawValue: "\(Self.notificationBaseName).ssodialog")
                
                #expect(tracker.eventName == nil)
                #expect(tracker.params == nil)
                
                NotificationCenter.default.post(name: notificationName, object: "\(uiViewControllerType)\(param)")
                
                try await TestingHelpers.eventuallyOnMain { tracker.eventName == AnalyticsManager.Event.Name.pageVisit }
                try await TestingHelpers.eventuallyOnMain { tracker.params?["page_id"] as? String == "\(uiViewControllerType)\(param)" }
                tracker.reset()
            }
        }
    }
    
    @Suite("receiveCredentialsNotification")
    struct ReceiveCredentialsNotificationTests {
        static let notificationBaseName = RAnalyticsExternalCollectorTests.notificationBaseName
        
        var dependenciesContainer: SimpleContainerMock!
        let tracker = AnalyticsTrackerMock()
        
        init() {
            dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
            dependenciesContainer.keychainHandler = KeychainHandlerMock()
        }
        
        mutating func tearDown() {
            tracker.reset()
        }
        
        @Test("should track a credential event when a credential notification is received")
        @MainActor
        func testShouldTrackCredentialEventWhenCredentialNotificationIsReceived() async throws {
            let mapping = ["ssocredentialfound": AnalyticsManager.Event.Name.ssoCredentialFound, "logincredentialfound": AnalyticsManager.Event.Name.loginCredentialFound]
            
            for (key, value) in mapping {
                let externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
                externalCollector.trackerDelegate = tracker
                #expect(externalCollector.isLoggedIn == false)
                
                let notificationName = Notification.Name(rawValue: "\(Self.notificationBaseName).\(key)")
                
                #expect(tracker.eventName == nil)
                #expect(tracker.params == nil)
                
                NotificationCenter.default.post(name: notificationName, object: nil)
                
                try await TestingHelpers.eventuallyOnMain { tracker.eventName == value }
                try await TestingHelpers.eventuallyOnMain { tracker.params?.isEmpty == true }
                tracker.reset()
            }
        }
    }
    
    @Suite("receiveCustomEventNotification")
    struct ReceiveCustomEventNotificationTests {
        var dependenciesContainer: SimpleContainerMock!
        let tracker = AnalyticsTrackerMock()
        var externalCollector: RAnalyticsExternalCollector!
        static let notificationBaseName = RAnalyticsExternalCollectorTests.notificationBaseName
        
        init() {
            dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.userStorageHandler = UserDefaultsMock([:])
            (dependenciesContainer.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
            dependenciesContainer.keychainHandler = KeychainHandlerMock()
            
            externalCollector = RAnalyticsExternalCollector(dependenciesContainer: dependenciesContainer)
            externalCollector.trackerDelegate = tracker
        }
        
        @Test("should track AnalyticsManager.Event.Name.custom when a custom notification is received")
        @MainActor
        func testShouldTrackCustomEventWhenCustomNotificationIsReceived() async throws {
            let params: [String: Any] = ["eventName": "blah", "eventData": ["foo": "bar"]]
            #expect(externalCollector.isLoggedIn == false)
            
            let notificationName = Notification.Name(rawValue: "\(Self.notificationBaseName).custom")
            
            #expect(tracker.eventName == nil)
            #expect(tracker.params == nil)
            
            NotificationCenter.default.post(name: notificationName, object: params)
            
            try await TestingHelpers.eventuallyOnMain { tracker.eventName == AnalyticsManager.Event.Name.custom }
            try await TestingHelpers.eventuallyOnMain { tracker.params?["eventName"] as? String == params["eventName"] as? String }
            try await TestingHelpers.eventuallyOnMain { tracker.params?["eventData"] as? [String: String] == params["eventData"] as? [String: String] }
        }
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable function_body_length

// swiftlint:disable line_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable control_statement

import Foundation
import Testing
import UIKit.UIDevice
@preconcurrency @testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("RAnalyticsRATTracker")
struct RAnalyticsRATTrackerPayloadCoreTests {
    @Suite("process(event:state:)")
    struct ProcessEventStateTests {
        @Suite("Core parameters")
        struct CoreParametersTests {
            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should set a non-nil app_ver")
            mutating func testShouldSetNonNilAppVer() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let ts1 = payload?["app_ver"] as? String
                #expect(ts1 == PayloadTestHelper.bundle.shortVersion)
            }
            
            @Test("should set app_name to the app's bundle identifier")
            mutating func testShouldSetAppNameToBundleIdentifier() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let appName = payload?["app_name"] as? String
                #if SWIFT_PACKAGE
                #expect(appName == "com.apple.dt.xctest.tool")
                #else
                #expect(appName == "jp.co.rakuten.Host")
                #endif
            }
            
            @Test("should set mos to iOS {version_number}")
            mutating func testShouldSetMosToIOSVersion() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let mos = payload?["mos"] as? String
                let expectedMos = await MainActor.run { UIDevice.current.systemName + " " + UIDevice.current.systemVersion }
                #expect(mos == expectedMos)
            }
            
            @Test("should set ver to the SDK version")
            mutating func testShouldSetVerToSDKVersion() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let ver = payload?["ver"] as? String
                #expect(ver == CoreHelpers.Constants.sdkVersion)
            }
            
            @Test("should set a non-nil ts1")
            mutating func testShouldSetNonNilTs1() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let ts1 = payload?["ts1"] as? TimeInterval
                #expect(ts1 != nil)
            }
        }
        
        @Suite("Device Language Code")
        struct DeviceLanguageCodeTests {
            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should set a non-nil dln for jp")
            mutating func testShouldSetNonNilDlnForJP() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                PayloadTestHelper.bundle.languageCode = "jp"
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let dln = payload?["dln"] as? String
                #expect(dln == "jp")
            }
            
            @Test("should set a non-nil dln for en")
            mutating func testShouldSetNonNilDlnForEN() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                PayloadTestHelper.bundle.languageCode = "en"
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let dln = payload?["dln"] as? String
                #expect(dln == "en")
            }
            
            @Test("should set a non-nil dln for de")
            mutating func testShouldSetNonNilDlnForDE() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                PayloadTestHelper.bundle.languageCode = "de"
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let dln = payload?["dln"] as? String
                #expect(dln == "de")
            }
            
            @Test("should set a non-nil dln for fr")
            mutating func testShouldSetNonNilDlnForFR() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                PayloadTestHelper.bundle.languageCode = "fr"
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let dln = payload?["dln"] as? String
                #expect(dln == "fr")
            }
            
            @Test("should set a non-nil dln for hi")
            mutating func testShouldSetNonNilDlnForHI() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                PayloadTestHelper.bundle.languageCode = "hi"
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let dln = payload?["dln"] as? String
                #expect(dln == "hi")
            }
        }
        
        @Suite("Session Identifier")
        struct SessionIdentifierTests {
            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should set cks to CA7A88AR-82FE-40C9-A836-B1B3455DECAF")
            mutating func testShouldSetCks() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let cks = payload?["cks"] as? String
                #expect(cks == "CA7A88AR-82FE-40C9-A836-B1B3455DECAF")
            }
        }
        
        @Suite("Device Identifier")
        struct DeviceIdentifierTests {
            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should set ckp to deviceId")
            mutating func testShouldSetCkpToDeviceId() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let ckp = payload?["ckp"] as? String
                #expect(ckp == "deviceId")
            }
        }
        
        @Suite("IDFA")
        struct IDFATests {
            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should set cka to adId")
            mutating func testShouldSetCkaToAdId() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let cka = payload?["cka"] as? String
                #expect(cka == "adId")
            }
        }
        
        @Suite("Start time")
        struct StartTimeTests {
            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should set a non-nil ltm")
            mutating func testShouldSetNonNilLtm() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let ltm = payload?["ltm"] as? String
                #expect(ltm != nil)
            }
        }
        
        @Suite("Time zone")
        struct TimeZoneTests {
            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should set a non-nil tzo")
            mutating func testShouldSetNonNilTzo() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let tzo = payload?["tzo"] as? NSNumber
                #expect(tzo != nil)
            }
        }
        
        @Suite("User Agent")
        struct UserAgentTests {
            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should set ua to jp.co.rakuten.Host/1.0")
            mutating func testShouldSetUa() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let ua = payload?["ua"] as? String
                #if SWIFT_PACKAGE
                #expect(ua == "com.apple.dt.xctest.tool/\(Tracking.defaultState.currentVersion)")
                #else
                #expect(ua == "jp.co.rakuten.Host/\(Tracking.defaultState.currentVersion)")
                #endif
            }
        }
        
        @Suite("Enriched User Agent")
        struct EnrichedUserAgentTests {
            var helper = PayloadTestHelper.TestHelper()
            
            @Test("should set ua_enriched with the expected format")
            mutating func testShouldSetUaEnrichedWithExpectedFormat() async throws {
                helper.setUp()
                defer { helper.tearDown() }
                
                var payload: [String: Any]?
                
                try await helper.expecter.expectEventAsync(Tracking.defaultEvent, state: Tracking.defaultState, equal: "defaultEvent") {
                    payload = $0.first
                }
                
                let uaEnriched = payload?["ua_enriched"] as? String
                
                #if SWIFT_PACKAGE
                let appName = "com.apple.dt.xctest.tool"
                #else
                let appName = "jp.co.rakuten.Host"
                #endif
                let appVersion = Tracking.defaultState.currentVersion
                let osInfo = await MainActor.run { "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)" }
                let deviceModel = await MainActor.run { UIDevice.current.modelIdentifier }
                let deviceType = "phone"
                let localeCode = PayloadTestHelper.bundle.preferredLocalization?.prefix(2)
                let language = String(localeCode ?? "")
                
                let analyticsVersion = CoreHelpers.Constants.sdkVersion
                
                let expectedUA = "\(appName)/\(appVersion) (\(osInfo); \(deviceModel); \(deviceType); \(language); Analytics/\(analyticsVersion))"
                
                #expect(uaEnriched == expectedUA)
            }
        }
    }
}

// swiftlint:enable line_length
// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
// swiftlint:enable control_statement

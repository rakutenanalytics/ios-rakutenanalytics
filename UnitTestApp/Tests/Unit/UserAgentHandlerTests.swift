import Testing
import UIKit
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - Mock Providers

struct MockDeviceInfoProvider: DeviceInfoProvidable {
    let systemName: String
    let systemVersion: String
    let modelIdentifier: String
    let userInterfaceIdiom: UIUserInterfaceIdiom
}

struct MockLocaleProvider: LocaleProvidable {
    let preferredLanguages: [String]
}

// MARK: - UserAgentHandlerTests

@Suite("UserAgentHandler")
struct UserAgentHandlerTests {
    @Suite("value(for:)")
    struct ValueForTests {
        @Suite("When bundle identifier and short version are provided")
        struct WhenBundleIdentifierAndShortVersionAreProvidedTests {
            @Test("should return the expected user agent format")
            func testShouldReturnExpectedUserAgentFormat() {
                let bundle = BundleMock.create()
                bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                bundle.shortVersion = "1.2.3"
                
                let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                let userAgentHandler = UserAgentHandler(bundle: bundle)
                let result = userAgentHandler.value(for: state)
                
                #expect(result == "jp.co.rakuten.TestApp/1.2.3")
            }
        }
        
        @Suite("When bundle identifier and version are provided")
        struct WhenBundleIdentifierAndVersionAreProvidedTests {
            @Test("should return the expected user agent format")
            func testShouldReturnExpectedUserAgentFormat() {
                let bundle = BundleMock.create()
                bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                bundle.version = "4.5.6"
                
                let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                let userAgentHandler = UserAgentHandler(bundle: bundle)
                let result = userAgentHandler.value(for: state)
                
                #expect(result == "jp.co.rakuten.TestApp/4.5.6")
            }
        }
        
        @Suite("When bundle identifier is nil")
        struct WhenBundleIdentifierIsNilTests {
            @Test("should return nil")
            func testShouldReturnNil() {
                let bundle = BundleMock.create()
                bundle.bundleIdentifier = nil
                bundle.shortVersion = "1.2.3"
                
                let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                let mockBundle = BundleMock.create()
                mockBundle.bundleIdentifier = nil
                
                let userAgentHandler = UserAgentHandler(bundle: mockBundle)
                let result = userAgentHandler.value(for: state)
                
                #expect(result == nil)
            }
        }
        
        @Suite("When current version is nil")
        struct WhenCurrentVersionIsNilTests {
            @Test("should return only bundle identifier")
            func testShouldReturnOnlyBundleIdentifier() {
                let bundle = BundleMock.create()
                bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                bundle.shortVersion = nil
                bundle.version = nil
                
                let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                let userAgentHandler = UserAgentHandler(bundle: bundle)
                let result = userAgentHandler.value(for: state)
                
                #expect(result == "jp.co.rakuten.TestApp/")
            }
        }
    }
    
    @Suite("enrichedValue(for:)")
    struct EnrichedValueForTests {
        @Suite("When all parameters are provided")
        struct WhenAllParametersAreProvidedTests {
            @Test("should return the enriched user agent with correct format")
            func testShouldReturnEnrichedUserAgentWithCorrectFormat() {
                let bundle = BundleMock.create()
                bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                bundle.shortVersion = "1.2.3"
                bundle.preferredLocalization = "japanese"
                
                let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                
                let mockDevice = MockDeviceInfoProvider(
                    systemName: "iOS",
                    systemVersion: "15.0",
                    modelIdentifier: "iPhone14,2",
                    userInterfaceIdiom: .phone
                )
                
                let userAgentHandler = UserAgentHandler(bundle: bundle, deviceInfoProvider: mockDevice, localeProvider: DefaultLocaleProvider())
                let result = userAgentHandler.enrichedValue(for: state)
                
                #expect(result == "jp.co.rakuten.TestApp/1.2.3 (iOS 15.0; iPhone14,2; phone; ja; Analytics/\(CoreHelpers.Constants.sdkVersion))")
            }
        }
        
        @Suite("When bundle identifier is nil")
        struct WhenBundleIdentifierIsNilTests {
            @Test("should return nil")
            func testShouldReturnNil() {
                let bundle = BundleMock.create()
                bundle.bundleIdentifier = nil
                bundle.shortVersion = "1.2.3"
                
                let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                
                let mockDevice = MockDeviceInfoProvider(
                    systemName: "iOS",
                    systemVersion: "15.0",
                    modelIdentifier: "iPhone14,2",
                    userInterfaceIdiom: .phone
                )
                
                let userAgentHandler = UserAgentHandler(bundle: bundle, deviceInfoProvider: mockDevice, localeProvider: DefaultLocaleProvider())
                let result = userAgentHandler.enrichedValue(for: state)
                
                #expect(result == nil)
            }
        }
        
        @Suite("When current version is nil")
        struct WhenCurrentVersionIsNilTests {
            @Test("should return bundle identifier only")
            func testShouldReturnBundleIdentifierOnly() {
                let bundle = BundleMock.create()
                bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                bundle.shortVersion = nil
                bundle.version = nil
                bundle.preferredLocalization = "japanese"
                
                let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                
                let mockDevice = MockDeviceInfoProvider(
                    systemName: "iOS",
                    systemVersion: "15.0",
                    modelIdentifier: "iPhone14,2",
                    userInterfaceIdiom: .phone
                )
                
                let userAgentHandler = UserAgentHandler(bundle: bundle, deviceInfoProvider: mockDevice, localeProvider: DefaultLocaleProvider())
                let result = userAgentHandler.enrichedValue(for: state)
                
                #expect(result == "jp.co.rakuten.TestApp/ (iOS 15.0; iPhone14,2; phone; ja; Analytics/\(CoreHelpers.Constants.sdkVersion))")
            }
        }
        
        @Suite("Device Types")
        struct DeviceTypesTests {
            static let bundle: BundleMock = {
                let bundle = BundleMock.create()
                bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                bundle.shortVersion = "1.2.3"
                return bundle
            }()
            
            static func createState() -> RAnalyticsState {
                return RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
            }
            
            @Test("should include 'phone' for iOS iPhone14,2")
            func testShouldIncludePhoneForIOSiPhone() {
                let state = Self.createState()
                let mockDevice = MockDeviceInfoProvider(
                    systemName: "iOS",
                    systemVersion: "15.0",
                    modelIdentifier: "iPhone14,2",
                    userInterfaceIdiom: .phone
                )
                
                let userAgentHandler = UserAgentHandler(bundle: Self.bundle, deviceInfoProvider: mockDevice, localeProvider: DefaultLocaleProvider())
                let result = userAgentHandler.enrichedValue(for: state)
                
                #expect(result != nil)
                #expect(result?.contains("; phone;") == true)
            }
            
            @Test("should include 'pad' for iPadOS iPad13,1")
            func testShouldIncludePadForIPadOSiPad() {
                let state = Self.createState()
                let mockDevice = MockDeviceInfoProvider(
                    systemName: "iPadOS",
                    systemVersion: "15.0",
                    modelIdentifier: "iPad13,1",
                    userInterfaceIdiom: .pad
                )
                
                let userAgentHandler = UserAgentHandler(bundle: Self.bundle, deviceInfoProvider: mockDevice, localeProvider: DefaultLocaleProvider())
                let result = userAgentHandler.enrichedValue(for: state)
                
                #expect(result != nil)
                #expect(result?.contains("; pad;") == true)
            }
            
            @Test("should include 'tv' for tvOS AppleTV11,1")
            func testShouldIncludeTVForTVOSAppleTV() {
                let state = Self.createState()
                let mockDevice = MockDeviceInfoProvider(
                    systemName: "tvOS",
                    systemVersion: "15.0",
                    modelIdentifier: "AppleTV11,1",
                    userInterfaceIdiom: .tv
                )
                
                let userAgentHandler = UserAgentHandler(bundle: Self.bundle, deviceInfoProvider: mockDevice, localeProvider: DefaultLocaleProvider())
                let result = userAgentHandler.enrichedValue(for: state)
                
                #expect(result != nil)
                #expect(result?.contains("; tv;") == true)
            }
            
            @Test("should include 'mac' for macOS Mac14,2")
            func testShouldIncludeMacForMacOSMac() {
                let state = Self.createState()
                let mockDevice = MockDeviceInfoProvider(
                    systemName: "macOS",
                    systemVersion: "15.0",
                    modelIdentifier: "Mac14,2",
                    userInterfaceIdiom: .mac
                )
                
                let userAgentHandler = UserAgentHandler(bundle: Self.bundle, deviceInfoProvider: mockDevice, localeProvider: DefaultLocaleProvider())
                let result = userAgentHandler.enrichedValue(for: state)
                
                #expect(result != nil)
                #expect(result?.contains("; mac;") == true)
            }
            
            @Test("should include 'carPlay' for iOS CarPlay1,1")
            func testShouldIncludeCarPlayForIOSCarPlay() {
                let state = Self.createState()
                let mockDevice = MockDeviceInfoProvider(
                    systemName: "iOS",
                    systemVersion: "15.0",
                    modelIdentifier: "CarPlay1,1",
                    userInterfaceIdiom: .carPlay
                )
                
                let userAgentHandler = UserAgentHandler(bundle: Self.bundle, deviceInfoProvider: mockDevice, localeProvider: DefaultLocaleProvider())
                let result = userAgentHandler.enrichedValue(for: state)
                
                #expect(result != nil)
                #expect(result?.contains("; carPlay;") == true)
            }
            
            @Test("should include 'unspecified' for iOS UnknownDevice1,1")
            func testShouldIncludeUnspecifiedForIOSUnknownDevice() {
                let state = Self.createState()
                let mockDevice = MockDeviceInfoProvider(
                    systemName: "iOS",
                    systemVersion: "15.0",
                    modelIdentifier: "UnknownDevice1,1",
                    userInterfaceIdiom: .unspecified
                )
                
                let userAgentHandler = UserAgentHandler(bundle: Self.bundle, deviceInfoProvider: mockDevice, localeProvider: DefaultLocaleProvider())
                let result = userAgentHandler.enrichedValue(for: state)
                
                #expect(result != nil)
                #expect(result?.contains("; unspecified;") == true)
            }
        }
        
        @Suite("Language Handling")
        struct LanguageHandlingTests {
            @Suite("When app language is available")
            struct WhenAppLanguageIsAvailableTests {
                @Test("should use the app's preferred localization")
                func testShouldUseAppsPreferredLocalization() {
                    let bundle = BundleMock.create()
                    bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                    bundle.shortVersion = "1.2.3"
                    bundle.preferredLocalization = "japanese"
                    
                    let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                    
                    let mockDevice = MockDeviceInfoProvider(
                        systemName: "iOS",
                        systemVersion: "15.0",
                        modelIdentifier: "iPhone14,2",
                        userInterfaceIdiom: .phone
                    )
                    
                    let userAgentHandler = UserAgentHandler(bundle: bundle, deviceInfoProvider: mockDevice, localeProvider: DefaultLocaleProvider())
                    let result = userAgentHandler.enrichedValue(for: state)
                    
                    #expect(result == "jp.co.rakuten.TestApp/1.2.3 (iOS 15.0; iPhone14,2; phone; ja; Analytics/\(CoreHelpers.Constants.sdkVersion))")
                }
            }
            
            @Suite("When system language is available but app language is not")
            struct WhenSystemLanguageIsAvailableButAppLanguageIsNotTests {
                @Test("should use the system language")
                func testShouldUseSystemLanguage() {
                    let bundle = BundleMock.create()
                    bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                    bundle.shortVersion = "1.2.3"
                    bundle.preferredLocalization = nil
                    
                    let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                    
                    let mockDevice = MockDeviceInfoProvider(
                        systemName: "iOS",
                        systemVersion: "15.0",
                        modelIdentifier: "iPhone14,2",
                        userInterfaceIdiom: .phone
                    )
                    
                    let mockLocaleProvider = MockLocaleProvider(preferredLanguages: ["en_US", "fr_FR"])
                    
                    let userAgentHandler = UserAgentHandler(bundle: bundle, deviceInfoProvider: mockDevice, localeProvider: mockLocaleProvider)
                    let result = userAgentHandler.enrichedValue(for: state)
                    
                    #expect(result != nil)
                    #expect(result == "jp.co.rakuten.TestApp/1.2.3 (iOS 15.0; iPhone14,2; phone; en_US; Analytics/\(CoreHelpers.Constants.sdkVersion))")
                }
            }
            
            @Suite("When no languages are available")
            struct WhenNoLanguagesAreAvailableTests {
                @Test("should use the default language 'ja_JP'")
                func testShouldUseDefaultLanguageJaJP() {
                    let bundle = BundleMock.create()
                    bundle.bundleIdentifier = "jp.co.rakuten.TestApp"
                    bundle.shortVersion = "1.2.3"
                    bundle.preferredLocalization = nil
                    
                    let state = RAnalyticsState(sessionIdentifier: "test-session", deviceIdentifier: "test-device", for: bundle)
                    
                    let mockDevice = MockDeviceInfoProvider(
                        systemName: "iOS",
                        systemVersion: "15.0",
                        modelIdentifier: "iPhone14,2",
                        userInterfaceIdiom: .phone
                    )
                    
                    let mockLocaleProvider = MockLocaleProvider(preferredLanguages: [])
                    
                    let userAgentHandler = UserAgentHandler(bundle: bundle, deviceInfoProvider: mockDevice, localeProvider: mockLocaleProvider)
                    let result = userAgentHandler.enrichedValue(for: state)
                    
                    #expect(result == "jp.co.rakuten.TestApp/1.2.3 (iOS 15.0; iPhone14,2; phone; ja_JP; Analytics/\(CoreHelpers.Constants.sdkVersion))")
                }
            }
        }
    }
}

import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - EnvironmentBundleMock

private final class EnvironmentBundleMock: Bundle, @unchecked Sendable {
    
    var injectedDictionary: [String: Any]?

    override var infoDictionary: [String: Any]? {
        injectedDictionary
    }

    override func object(forInfoDictionaryKey key: String) -> Any? {
        injectedDictionary?[key]
    }
}

// MARK: - EnvironmentBundleTests

@Suite("EnvironmentBundle")
struct EnvironmentBundleTests {
    @Suite("accountIdentifier")
    struct AccountIdentifierTests {
        @Suite("When the account identifier is not configured")
        struct WhenAccountIdentifierNotConfiguredTests {
            @Test("should return 0")
            func testReturnsZero() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = nil
                #expect(bundleMock.accountIdentifier == 0)
            }
        }

        @Suite("When the account identifier is Number and set to -1 in the Bundle")
        struct WhenAccountIdentifierIsNumberMinusOneTests {
            @Test("should return 0")
            func testReturnsZero() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: NSNumber(value: -1)]
                #expect(bundleMock.accountIdentifier == 0)
            }
        }

        @Suite("When the account identifier is String and set to -1 in the Bundle")
        struct WhenAccountIdentifierIsStringMinusOneTests {
            @Test("should return 0")
            func testReturnsZero() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: "-1"]
                #expect(bundleMock.accountIdentifier == 0)
            }
        }

        @Suite("When the account identifier is Number and set to 12345 in the Bundle")
        struct WhenAccountIdentifierIsNumber12345Tests {
            @Test("should return 12345")
            func testReturns12345() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: NSNumber(value: 12345)]
                #expect(bundleMock.accountIdentifier == 12345)
            }
        }

        @Suite(#"When the account identifier is String and set to "6789" in the Bundle"#)
        struct WhenAccountIdentifierIsString6789Tests {
            @Test("should return 6789")
            func testReturns6789() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: "6789"]
                #expect(bundleMock.accountIdentifier == 6789)
            }
        }

        @Suite(#"When the account identifier is String and set to "0789" in the Bundle"#)
        struct WhenAccountIdentifierIsString0789Tests {
            @Test("should return 789")
            func testReturns789() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: "0789"]
                #expect(bundleMock.accountIdentifier == 789)
            }
        }

        @Suite(#"When the account identifier is String and set to "hello world" in the Bundle"#)
        struct WhenAccountIdentifierIsStringHelloWorldTests {
            @Test("should return 0")
            func testReturnsZero() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: "hello world"]
                #expect(bundleMock.accountIdentifier == 0)
            }
        }

        @Suite("When the account identifier is Boolean and set to false")
        struct WhenAccountIdentifierIsBooleanFalseTests {
            @Test("should return 0")
            func testReturnsZero() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: false]
                #expect(bundleMock.accountIdentifier == 0)
            }
        }

        @Suite("When the account identifier is Boolean and set to true")
        struct WhenAccountIdentifierIsBooleanTrueTests {
            @Test("should return 0")
            func testReturnsZero() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: true]
                #expect(bundleMock.accountIdentifier == 0)
            }
        }

        @Suite("When the account identifier is Array")
        struct WhenAccountIdentifierIsArrayTests {
            @Test("should return 0")
            func testReturnsZero() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: [45, 76, 89]]
                #expect(bundleMock.accountIdentifier == 0)
            }
        }

        @Suite("When the account identifier is Dictionary")
        struct WhenAccountIdentifierIsDictionaryTests {
            @Test("should return 0")
            func testReturnsZero() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: ["key1": "value1", "key2": "value2"]]
                #expect(bundleMock.accountIdentifier == 0)
            }
        }

        @Suite("When the account identifier is Data")
        struct WhenAccountIdentifierIsDataTests {
            @Test("should return 0")
            func testReturnsZero() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: Data()]
                #expect(bundleMock.accountIdentifier == 0)
            }
        }

        @Suite("When the account identifier is Date")
        struct WhenAccountIdentifierIsDateTests {
            @Test("should return 0")
            func testReturnsZero() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: Date()]
                #expect(bundleMock.accountIdentifier == 0)
            }
        }
    }

    @Suite("applicationIdentifier")
    struct ApplicationIdentifierTests {
        @Suite("When the application identifier is not configured")
        struct WhenApplicationIdentifierNotConfiguredTests {
            @Test("should return 1")
            func testReturnsOne() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = nil
                #expect(bundleMock.applicationIdentifier == 1)
            }
        }

        @Suite("When the application identifier is Number and set to -1 in the Bundle")
        struct WhenApplicationIdentifierIsNumberMinusOneTests {
            @Test("should return 0")
            func testReturnsZero() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: NSNumber(value: -1)]
                #expect(bundleMock.applicationIdentifier == 0)
            }
        }

        @Suite("When the application identifier is String and set to -1 in the Bundle")
        struct WhenApplicationIdentifierIsStringMinusOneTests {
            @Test("should return 0")
            func testReturnsZero() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: "-1"]
                #expect(bundleMock.applicationIdentifier == 0)
            }
        }

        @Suite("When the application identifier is Number and set to 7593 in the Bundle")
        struct WhenApplicationIdentifierIsNumber7593Tests {
            @Test("should return 7593")
            func testReturns7593() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: NSNumber(value: 7593)]
                #expect(bundleMock.applicationIdentifier == 7593)
            }
        }

        @Suite(#"When the application identifier is String and set to "4938" in the Bundle"#)
        struct WhenApplicationIdentifierIsString4938Tests {
            @Test("should return 4938")
            func testReturns4938() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: "4938"]
                #expect(bundleMock.applicationIdentifier == 4938)
            }
        }

        @Suite(#"When the application identifier is String and set to "0938" in the Bundle"#)
        struct WhenApplicationIdentifierIsString0938Tests {
            @Test("should return 938")
            func testReturns938() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: "0938"]
                #expect(bundleMock.applicationIdentifier == 938)
            }
        }

        @Suite(#"When the application identifier is String and set to "hello world" in the Bundle"#)
        struct WhenApplicationIdentifierIsStringHelloWorldTests {
            @Test("should return 1")
            func testReturnsOne() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: "hello world"]
                #expect(bundleMock.applicationIdentifier == 1)
            }
        }

        @Suite("When the application identifier is Boolean and set to false")
        struct WhenApplicationIdentifierIsBooleanFalseTests {
            @Test("should return 1")
            func testReturnsOne() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: false]
                #expect(bundleMock.applicationIdentifier == 1)
            }
        }

        @Suite("When the application identifier is Boolean and set to true")
        struct WhenApplicationIdentifierIsBooleanTrueTests {
            @Test("should return 1")
            func testReturnsOne() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: true]
                #expect(bundleMock.applicationIdentifier == 1)
            }
        }

        @Suite("When the application identifier is Array")
        struct WhenApplicationIdentifierIsArrayTests {
            @Test("should return 1")
            func testReturnsOne() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: [45, 76, 89]]
                #expect(bundleMock.applicationIdentifier == 1)
            }
        }

        @Suite("When the application identifier is Dictionary")
        struct WhenApplicationIdentifierIsDictionaryTests {
            @Test("should return 1")
            func testReturnsOne() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: ["key1": "value1", "key2": "value2"]]
                #expect(bundleMock.applicationIdentifier == 1)
            }
        }

        @Suite("When the application identifier is Data")
        struct WhenApplicationIdentifierIsDataTests {
            @Test("should return 1")
            func testReturnsOne() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: Data()]
                #expect(bundleMock.applicationIdentifier == 1)
            }
        }

        @Suite("When the application identifier is Date")
        struct WhenApplicationIdentifierIsDateTests {
            @Test("should return 1")
            func testReturnsOne() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: Date()]
                #expect(bundleMock.applicationIdentifier == 1)
            }
        }
    }

    @Suite("endpointAddress")
    struct EndpointAddressTests {
        @Test("should return user-defined RAT url if user set RAT url in app info.plist")
        func testReturnsUserDefinedRATURL() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = ["RATEndpoint": "https://example.com"]
            #expect(bundleMock.endpointAddress?.absoluteString == "https://example.com")
        }

        @Test("should return production RAT url if user set an empty RAT url in app info.plist")
        func testReturnsProductionRATURLWhenEmpty() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = ["RATEndpoint": ""]
            #expect(bundleMock.endpointAddress?.absoluteString == "https://rat.rakuten.co.jp/")
        }

        @Test("should return production RAT url if user did not set RAT url in app info.plist")
        func testReturnsProductionRATURLWhenNotSet() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = [:]
            #expect(bundleMock.endpointAddress?.absoluteString == "https://rat.rakuten.co.jp/")
        }

        @Test("should return production RAT url if the info dictionary is nil")
        func testReturnsProductionRATURLWhenInfoDictionaryIsNil() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = nil
            #expect(bundleMock.endpointAddress?.absoluteString == "https://rat.rakuten.co.jp/")
        }
    }

    @Suite("useDefaultSharedCookieStorage")
    struct UseDefaultSharedCookieStorageTests {
        @Test("should return false if user set 'disable shared cookie storage' key to true in app info.plist")
        func testReturnsFalseWhenDisabled() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = ["RATDisableSharedCookieStorage": true]
            #expect(bundleMock.useDefaultSharedCookieStorage == false)
        }

        @Test("should return true if user set 'disable shared cookie storage' key to false in app info.plist")
        func testReturnsTrueWhenEnabled() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = ["RATDisableSharedCookieStorage": false]
            #expect(bundleMock.useDefaultSharedCookieStorage == true)
        }

        @Test("should return true if user did not set 'disable shared cookie storage' key")
        func testReturnsTrueWhenNotSet() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = [:]
            #expect(bundleMock.useDefaultSharedCookieStorage == true)
        }

        @Test("should return true if the info dictionary is nil")
        func testReturnsTrueWhenInfoDictionaryIsNil() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = nil
            #expect(bundleMock.useDefaultSharedCookieStorage == true)
        }
    }

    @Suite("databaseParentDirectory")
    struct DatabaseParentDirectoryTests {
        @Test("should return the default value when RATStoreDatabaseInApplicationSupportDirectory is not set")
        func testReturnsDefaultValueWhenNotSet() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = [:]
            #expect(bundleMock.databaseParentDirectory == .documentDirectory)
        }

        @Test("should return the expected value when RATStoreDatabaseInApplicationSupportDirectory is set")
        func testReturnsExpectedValueWhenSet() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = ["RATStoreDatabaseInApplicationSupportDirectory": false]
            #expect(bundleMock.databaseParentDirectory == .documentDirectory)

            bundleMock.injectedDictionary = ["RATStoreDatabaseInApplicationSupportDirectory": true]
            #expect(bundleMock.databaseParentDirectory == .applicationSupportDirectory)
        }
    }

    @Suite("backgroundLocationUpdates")
    struct BackgroundLocationUpdatesTests {
        @Test("should return false when value is not set")
        func testReturnsFalseWhenNotSet() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = [:]
            #expect(bundleMock.backgroundLocationUpdates == false)
        }

        @Test("should return true when value is set")
        func testReturnsTrueWhenSet() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = ["UIBackgroundModes": ["location"]]
            #expect(bundleMock.backgroundLocationUpdates == true)
        }
    }

    @Suite("sdkComponentMap")
    struct SDKComponentMapTests {
        @Test("should not return nil")
        func testDoesNotReturnNil() {
            let sdkComponentMap = Bundle.sdkComponentMap
            #expect(sdkComponentMap != nil)
            #expect(sdkComponentMap?["org.cocoapods.RPushPNP"] as? String == "pushpnp")
            #expect(sdkComponentMap?["org.cocoapods.RInAppMessaging"] as? String == "inappmessaging")
        }
    }
    
    @Suite("RATEnableManualInitialization")
    struct RATEnableManualInitializationTests {
        @Test("should return false if not configured")
        func testReturnsFalseWhenNotConfigured() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = nil
            #expect(bundleMock.isManualInitializationEnabled == false)
        }
        
        @Test("should return true if configured as true")
        func testReturnsTrueWhenConfiguredAsTrue() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = ["RATEnableManualInitialization": true]
            #expect(bundleMock.isManualInitializationEnabled == true)
        }
        
        @Test("should return true if configured as false")
        func testReturnsTrueWhenConfiguredAsFalse() {
            let bundleMock = EnvironmentBundleMock()
            bundleMock.injectedDictionary = ["RATEnableManualInitialization": false]
            #expect(bundleMock.isManualInitializationEnabled == false)
        }
    }

    @Suite("applicationSceneManifest")
    struct ApplicationSceneManifestTests {
        @Suite("When the bundle dictionary is nil")
        struct WhenBundleDictionaryIsNilTests {
            @Test("should return nil")
            func testReturnsNil() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = nil
                #expect(bundleMock.applicationSceneManifest == nil)
            }
        }

        @Suite("When the bundle dictionary is empty")
        struct WhenBundleDictionaryIsEmptyTests {
            @Test("should return nil")
            func testReturnsNil() {
                let bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = [:]
                #expect(bundleMock.applicationSceneManifest == nil)
            }
        }

        @Suite("When the bundle dictionary contains a nil SceneDelegate class name")
        struct WhenBundleDictionaryContainsNilSceneDelegateClassNameTests {
            static let dictionary = ["UIApplicationSceneManifest":
                                        ["UIApplicationSupportsMultipleScenes": false,
                                         "UISceneConfigurations":
                                            ["UIWindowSceneSessionRoleApplication":
                                                [["UISceneDelegateClassName": nil]]]]]

            fileprivate var bundleMock: EnvironmentBundleMock

            init() {
                bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = Self.dictionary
            }

            @Test("should not return nil")
            func testDoesNotReturnNil() {
                #expect(bundleMock.applicationSceneManifest != nil)
            }

            @Test("should return a nil SceneDelegate class name")
            func testReturnsNilSceneDelegateClassName() {
                #expect(bundleMock.applicationSceneManifest?.firstSceneDelegateClassName == nil)
            }
        }

        @Suite("When the bundle dictionary contains an empty SceneDelegate class name")
        struct WhenBundleDictionaryContainsEmptySceneDelegateClassNameTests {
            static let dictionary = ["UIApplicationSceneManifest":
                                        ["UIApplicationSupportsMultipleScenes": false,
                                         "UISceneConfigurations":
                                            ["UIWindowSceneSessionRoleApplication":
                                                [["UISceneDelegateClassName": ""]]]]]

            fileprivate var bundleMock: EnvironmentBundleMock

            init() {
                bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = Self.dictionary
            }

            @Test("should not return nil")
            func testDoesNotReturnNil() {
                #expect(bundleMock.applicationSceneManifest != nil)
            }

            @Test("should return an empty SceneDelegate class name")
            func testReturnsEmptySceneDelegateClassName() {
                #expect(bundleMock.applicationSceneManifest?.firstSceneDelegateClassName?.isEmpty == true)
            }
        }

        @Suite("When the bundle dictionary contains a non-nil SceneDelegate class name")
        struct WhenBundleDictionaryContainsNonNilSceneDelegateClassNameTests {
            static let dictionary = ["UIApplicationSceneManifest":
                                        ["UIApplicationSupportsMultipleScenes": false,
                                         "UISceneConfigurations":
                                            ["UIWindowSceneSessionRoleApplication":
                                                [["UISceneDelegateClassName": "SceneDelegate"]]]]]

            fileprivate var bundleMock: EnvironmentBundleMock

            init() {
                bundleMock = EnvironmentBundleMock()
                bundleMock.injectedDictionary = Self.dictionary
            }

            @Test("should not return nil")
            func testDoesNotReturnNil() {
                #expect(bundleMock.applicationSceneManifest != nil)
            }

            @Test("should return a non-nil SceneDelegate class name")
            func testReturnsNonNilSceneDelegateClassName() {
                #expect(bundleMock.applicationSceneManifest?.firstSceneDelegateClassName == "SceneDelegate")
            }
        }
    }
}

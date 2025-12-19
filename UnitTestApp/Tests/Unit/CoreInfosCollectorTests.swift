import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - CoreInfosCollectorTests

@Suite("CoreInfosCollector")
struct CoreInfosCollectorTests {
    @Suite("getCollectedInfos()")
    struct GetCollectedInfosTests {
        let collector = CoreInfosCollector()

        @Suite("sdkComponentMap is not nil")
        struct SDKComponentMapIsNotNilTests {
            let collector = CoreInfosCollector()

            @Test("should return a non-nil dictionary")
            func testReturnsNonNilDictionary() {
                let dictionary = collector.getCollectedInfos()
                #expect(dictionary != nil)
            }

            @Test("should return a dictionary with app info entry")
            func testReturnsDictionaryWithAppInfoEntry() {
                let dictionary = collector.getCollectedInfos()
                #expect(dictionary?[RAnalyticsConstants.rAnalyticsAppInfoKey] != nil)
            }

            @Test("should return a dictionary with app info's parameters entries")
            func testReturnsDictionaryWithAppInfoParametersEntries() {
                let dictionary = collector.getCollectedInfos()
                let appInfo = dictionary?[RAnalyticsConstants.rAnalyticsAppInfoKey] as? [String: Any]

                #expect(appInfo?["xcode"] != nil)

                #if SWIFT_PACKAGE
                // non-apple frameworks array is empty with SPM
                #else
                #expect(appInfo?["frameworks"] != nil)
                #endif

                #expect(appInfo?["sdk"] != nil)
                #expect(appInfo?["deployment_target"] != nil)
            }

            @Suite("sdkComponentMap contains analytics entries")
            struct SDKComponentMapContainsAnalyticsEntriesTests {
                let collector = CoreInfosCollector()
                let sdkComponentMap: NSDictionary = ["org.cocoapods.RAnalytics": "analytics"]

                // Note: this case should not happen as CoreHelpers is called from RAnalytics framework.
                @Suite("The app is built without SDKs")
                struct AppBuiltWithoutSDKsTests {
                    let collector = CoreInfosCollector()
                    let sdkComponentMap: NSDictionary = ["org.cocoapods.RAnalytics": "analytics"]
                    let allFrameworks: [EnvironmentBundle] = []

                    @Test("should return a dictionary with an empty sdk info")
                    func testReturnsDictionaryWithEmptySDKInfo() {
                        let dictionary = collector.getCollectedInfos(sdkComponentMap: sdkComponentMap, allFrameworks: allFrameworks)
                        let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]
                        #expect((sdks as? [String: String])?.isEmpty == true)
                    }
                }

                @Suite("The app is built with RAnalytics")
                struct AppBuiltWithRAnalyticsTests {
                    let collector = CoreInfosCollector()
                    let sdkComponentMap: NSDictionary = ["org.cocoapods.RAnalytics": "analytics"]
                    let allFrameworks: [EnvironmentBundle] = [BundleMock(bundleIdentifier: "org.cocoapods.RAnalytics",
                                                                         shortVersion: "9.8.0")]

                    @Test("should return a dictionary with empty sdk info")
                    func testReturnsDictionaryWithEmptySDKInfo() {
                        let dictionary = collector.getCollectedInfos(sdkComponentMap: sdkComponentMap, allFrameworks: allFrameworks)
                        let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]
                        #expect((sdks as? [String: String])?.isEmpty == true)
                    }
                }
            }

            @Suite("sdkComponentMap contains inappmessaging and pushpnp entries")
            struct SDKComponentMapContainsInAppMessagingAndPushPNPEntriesTests {
                let collector = CoreInfosCollector()
                let sdkComponentMap: NSDictionary = ["org.cocoapods.RInAppMessaging": "inappmessaging",
                                                     "org.cocoapods.RPushPNP": "pushpnp",
                                                     "org.cocoapods.GeoSDK": "geo",
                                                     "org.cocoapods.Pitari": "pitari"]

                // Note: this case should not happen as CoreHelpers is called from RAnalytics framework.
                @Suite("The app is built without SDKs")
                struct AppBuiltWithoutSDKsTests {
                    let collector = CoreInfosCollector()
                    let sdkComponentMap: NSDictionary = ["org.cocoapods.RInAppMessaging": "inappmessaging",
                                                         "org.cocoapods.RPushPNP": "pushpnp",
                                                         "org.cocoapods.GeoSDK": "geo",
                                                         "org.cocoapods.Pitari": "pitari"]
                    let allFrameworks: [EnvironmentBundle] = []

                    @Test("should return a dictionary with an empty sdk info")
                    func testReturnsDictionaryWithEmptySDKInfo() {
                        let dictionary = collector.getCollectedInfos(sdkComponentMap: sdkComponentMap, allFrameworks: allFrameworks)
                        let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]
                        #expect((sdks as? [String: String])?.isEmpty == true)
                    }
                }

                @Suite("The app is built with RInAppMessaging")
                struct AppBuiltWithRInAppMessagingTests {
                    let collector = CoreInfosCollector()
                    let sdkComponentMap: NSDictionary = ["org.cocoapods.RInAppMessaging": "inappmessaging",
                                                         "org.cocoapods.RPushPNP": "pushpnp",
                                                         "org.cocoapods.GeoSDK": "geo",
                                                         "org.cocoapods.Pitari": "pitari"]
                    let allFrameworks: [EnvironmentBundle] = [BundleMock(bundleIdentifier: "org.cocoapods.RInAppMessaging", shortVersion: "7.2.0")]

                    @Test("should return a dictionary with sdk info containing rsdks_inappmessaging entry")
                    func testReturnsDictionaryWithSDKInfoContainingRInAppMessagingEntry() {
                        let dictionary = collector.getCollectedInfos(sdkComponentMap: sdkComponentMap, allFrameworks: allFrameworks)
                        let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]
                        #expect(sdks as? [String: String] == ["rsdks_inappmessaging": "7.2.0"])
                    }
                }

                @Suite("The app is built with RPushPNP")
                struct AppBuiltWithRPushPNPTests {
                    let collector = CoreInfosCollector()
                    let sdkComponentMap: NSDictionary = ["org.cocoapods.RInAppMessaging": "inappmessaging",
                                                         "org.cocoapods.RPushPNP": "pushpnp",
                                                         "org.cocoapods.GeoSDK": "geo",
                                                         "org.cocoapods.Pitari": "pitari"]
                    let allFrameworks: [EnvironmentBundle] = [BundleMock(bundleIdentifier: "org.cocoapods.RPushPNP", shortVersion: "10.0.0")]

                    @Test("should return a dictionary with sdk info containing rsdks_pushpnp entry")
                    func testReturnsDictionaryWithSDKInfoContainingRPushPNPEntry() {
                        let dictionary = collector.getCollectedInfos(sdkComponentMap: sdkComponentMap, allFrameworks: allFrameworks)
                        let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]
                        #expect(sdks as? [String: String] == ["rsdks_pushpnp": "10.0.0"])
                    }
                }

                @Suite("The app is built with GeoSDK")
                struct AppBuiltWithGeoSDKTests {
                    let collector = CoreInfosCollector()
                    let sdkComponentMap: NSDictionary = ["org.cocoapods.RInAppMessaging": "inappmessaging",
                                                         "org.cocoapods.RPushPNP": "pushpnp",
                                                         "org.cocoapods.GeoSDK": "geo",
                                                         "org.cocoapods.Pitari": "pitari"]
                    let allFrameworks: [EnvironmentBundle] = [BundleMock(bundleIdentifier: "org.cocoapods.GeoSDK", shortVersion: "2.2.0")]

                    @Test("should return a dictionary with sdk info containing rsdks_geo entry")
                    func testReturnsDictionaryWithSDKInfoContainingGeoSDKEntry() {
                        let dictionary = collector.getCollectedInfos(sdkComponentMap: sdkComponentMap, allFrameworks: allFrameworks)
                        let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]
                        #expect(sdks as? [String: String] == ["rsdks_geo": "2.2.0"])
                    }
                }

                @Suite("The app is built with Pitari")
                struct AppBuiltWithPitariTests {
                    let collector = CoreInfosCollector()
                    let sdkComponentMap: NSDictionary = ["org.cocoapods.RInAppMessaging": "inappmessaging",
                                                         "org.cocoapods.RPushPNP": "pushpnp",
                                                         "org.cocoapods.GeoSDK": "geo",
                                                         "org.cocoapods.Pitari": "pitari"]
                    let allFrameworks: [EnvironmentBundle] = [BundleMock(bundleIdentifier: "org.cocoapods.Pitari", shortVersion: "3.0.0")]

                    @Test("should return a dictionary with sdk info containing rsdks_pitari entry")
                    func testReturnsDictionaryWithSDKInfoContainingPitariEntry() {
                        let dictionary = collector.getCollectedInfos(sdkComponentMap: sdkComponentMap, allFrameworks: allFrameworks)
                        let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]
                        #expect(sdks as? [String: String] == ["rsdks_pitari": "3.0.0"])
                    }
                }

                @Suite("The app is built with RInAppMessaging RPushPNP, GeoSDK and Pitari")
                struct AppBuiltWithRInAppMessagingRPushPNPGeoSDKAndPitariTests {
                    let collector = CoreInfosCollector()
                    let sdkComponentMap: NSDictionary = ["org.cocoapods.RInAppMessaging": "inappmessaging",
                                                         "org.cocoapods.RPushPNP": "pushpnp",
                                                         "org.cocoapods.GeoSDK": "geo",
                                                         "org.cocoapods.Pitari": "pitari"]
                    let allFrameworks: [EnvironmentBundle] = [BundleMock(bundleIdentifier: "org.cocoapods.RInAppMessaging", shortVersion: "7.2.0"),
                                                              BundleMock(bundleIdentifier: "org.cocoapods.RPushPNP", shortVersion: "10.0.0"),
                                                              BundleMock(bundleIdentifier: "org.cocoapods.GeoSDK", shortVersion: "2.2.0"),
                                                              BundleMock(bundleIdentifier: "org.cocoapods.Pitari", shortVersion: "3.0.0")]
                    
                    // swiftlint:disable:next line_length
                    @Test("should return a dictionary with sdk info containing rsdks_inappmessaging rsdks_pushpnp, rsdks_geo and rsdks_pitari entries")
                    func testReturnsDictionaryWithSDKInfoContainingAllEntries() {
                        let dictionary = collector.getCollectedInfos(sdkComponentMap: sdkComponentMap, allFrameworks: allFrameworks)
                        let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]
                        
                        #expect(sdks as? [String: String] == ["rsdks_inappmessaging": "7.2.0",
                                                              "rsdks_pushpnp": "10.0.0",
                                                              "rsdks_geo": "2.2.0",
                                                              "rsdks_pitari": "3.0.0"])
                    }
                }
            }

            @Suite("sdkComponentMap is empty")
            struct SDKComponentMapIsEmptyTests {
                let collector = CoreInfosCollector()
                let sdkComponentMap: NSDictionary = [:]

                @Test("should return a dictionary not containing RAnalyticsFrameworkIdentifiers")
                func testReturnsDictionaryNotContainingRAnalyticsFrameworkIdentifiers() {
                    let dictionary = collector.getCollectedInfos(sdkComponentMap: sdkComponentMap)
                    let appInfo = dictionary?[RAnalyticsConstants.rAnalyticsAppInfoKey] as? [String: Any]

                    #expect((appInfo?["frameworks"] as? [String: Any])?[RAnalyticsFrameworkIdentifiers.appleIdentifier] == nil)
                    #expect((appInfo?["frameworks"] as? [String: Any])?[RAnalyticsFrameworkIdentifiers.analyticsIdentifier] == nil)
                    #expect((appInfo?["frameworks"] as? [String: Any])?[RAnalyticsFrameworkIdentifiers.analyticsPublicFrameworkIdentifier] == nil)
                    #expect((appInfo?["frameworks"] as? [String: Any])?[RAnalyticsFrameworkIdentifiers.sdkUtilsIdentifier] == nil)
                }

                @Test("should return a dictionary with an empty sdk info entry")
                func testReturnsDictionaryWithEmptySDKInfoEntry() {
                    let dictionary = collector.getCollectedInfos(sdkComponentMap: sdkComponentMap)
                    let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey] as? [String: String]
                    #expect(sdks?.isEmpty == true)
                }

                @Test("should return a dictionary with sdk info's not containing analytics entry")
                func testReturnsDictionaryWithSDKInfoNotContainingAnalyticsEntry() {
                    let dictionary = collector.getCollectedInfos(sdkComponentMap: sdkComponentMap)
                    #expect((dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey] as? [String: Any])?[RModulesListKeys.analyticsValue] == nil)
                }
            }
        }

        @Suite("sdkComponentMap is nil")
        struct SDKComponentMapIsNilTests {
            let collector = CoreInfosCollector()

            @Test("should return a non-nil dictionary")
            func testReturnsNonNilDictionary() {
                let dictionary = collector.getCollectedInfos(sdkComponentMap: nil)
                #expect(dictionary != nil)
            }

            @Test("should return a dictionary with app info entry")
            func testReturnsDictionaryWithAppInfoEntry() {
                let dictionary = collector.getCollectedInfos(sdkComponentMap: nil)
                #expect(dictionary?[RAnalyticsConstants.rAnalyticsAppInfoKey] != nil)
            }

            @Test("should return a dictionary with app info's parameters entries")
            func testReturnsDictionaryWithAppInfoParametersEntries() {
                let dictionary = collector.getCollectedInfos(sdkComponentMap: nil)
                let appInfo = dictionary?[RAnalyticsConstants.rAnalyticsAppInfoKey] as? [String: Any]

                #expect(appInfo?["xcode"] != nil)

                #if SWIFT_PACKAGE
                // non-apple frameworks array is empty with SPM
                #else
                #expect(appInfo?["frameworks"] != nil)
                #endif
                #expect(appInfo?["sdk"] != nil)
                #expect(appInfo?["deployment_target"] != nil)
            }

            @Test("should return a dictionary with sdk info entry")
            func testReturnsDictionaryWithSDKInfoEntry() {
                let dictionary = collector.getCollectedInfos(sdkComponentMap: nil)
                #expect(dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey] != nil)
            }

            @Test("should return a dictionary with sdk info's not containing analytics entry")
            func testReturnsDictionaryWithSDKInfoNotContainingAnalyticsEntry() {
                let dictionary = collector.getCollectedInfos(sdkComponentMap: nil)
                #expect((dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey] as? [String: Any])?[RModulesListKeys.analyticsValue] == nil)
            }
        }
    }
}

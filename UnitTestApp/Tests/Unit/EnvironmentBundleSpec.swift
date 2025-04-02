import Quick
import Nimble
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

// MARK: - EnvironmentBundleSpec

final class EnvironmentBundleSpec: QuickSpec {

    override class func spec() {
        describe("EnvironmentBundle") {
            let bundleMock = EnvironmentBundleMock()

            describe("accountIdentifier") {
                context("When the account identifier is not configured") {
                    it("should return 0") {
                        bundleMock.injectedDictionary = nil
                        expect(bundleMock.accountIdentifier).to(equal(0))
                    }
                }

                context("When the account identifier is Number and set to -1 in the Bundle") {
                    it("should return 0") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: NSNumber(value: -1)]
                        expect(bundleMock.accountIdentifier).to(equal(0))
                    }
                }

                context("When the account identifier is String and set to -1 in the Bundle") {
                    it("should return 0") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: "-1"]
                        expect(bundleMock.accountIdentifier).to(equal(0))
                    }
                }

                context("When the account identifier is Number and set to 12345 in the Bundle") {
                    it("should return 12345") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: NSNumber(value: 12345)]
                        expect(bundleMock.accountIdentifier).to(equal(12345))
                    }
                }

                context(#"When the account identifier is String and set to "6789" in the Bundle"#) {
                    it("should return 6789") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: "6789"]
                        expect(bundleMock.accountIdentifier).to(equal(6789))
                    }
                }

                context(#"When the account identifier is String and set to "0789" in the Bundle"#) {
                    it("should return 789") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: "0789"]
                        expect(bundleMock.accountIdentifier).to(equal(789))
                    }
                }

                context(#"When the account identifier is String and set to "hello world" in the Bundle"#) {
                    it("should return 0") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: "hello world"]
                        expect(bundleMock.accountIdentifier).to(equal(0))
                    }
                }

                context("When the account identifier is Boolean and set to false") {
                    it("should return 0") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: false]
                        expect(bundleMock.accountIdentifier).to(equal(0))
                    }
                }

                context("When the account identifier is Boolean and set to true") {
                    it("should return 0") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: true]
                        expect(bundleMock.accountIdentifier).to(equal(0))
                    }
                }

                context("When the account identifier is Array") {
                    it("should return 0") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: [45, 76, 89]]
                        expect(bundleMock.accountIdentifier).to(equal(0))
                    }
                }

                context("When the account identifier is Dictionary") {
                    it("should return 0") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: ["key1": "value1", "key2": "value2"]]
                        expect(bundleMock.accountIdentifier).to(equal(0))
                    }
                }

                context("When the account identifier is Data") {
                    it("should return 0") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: Data()]
                        expect(bundleMock.accountIdentifier).to(equal(0))
                    }
                }

                context("When the account identifier is Date") {
                    it("should return 0") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.accountId.rawValue: Date()]
                        expect(bundleMock.accountIdentifier).to(equal(0))
                    }
                }
            }

            describe("applicationIdentifier") {
                context("When the application identifier is not configured") {
                    it("should return 1") {
                        bundleMock.injectedDictionary = nil
                        expect(bundleMock.applicationIdentifier).to(equal(1))
                    }
                }

                context("When the application identifier is Number and set to -1 in the Bundle") {
                    it("should return 0") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: NSNumber(value: -1)]
                        expect(bundleMock.applicationIdentifier).to(equal(0))
                    }
                }

                context("When the application identifier is String and set to -1 in the Bundle") {
                    it("should return 0") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: "-1"]
                        expect(bundleMock.applicationIdentifier).to(equal(0))
                    }
                }

                context("When the application identifier is Number and set to 7593 in the Bundle") {
                    it("should return 7593") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: NSNumber(value: 7593)]
                        expect(bundleMock.applicationIdentifier).to(equal(7593))
                    }
                }

                context(#"When the application identifier is String and set to "4938" in the Bundle"#) {
                    it("should return 4938") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: "4938"]
                        expect(bundleMock.applicationIdentifier).to(equal(4938))
                    }
                }

                context(#"When the application identifier is String and set to "0938" in the Bundle"#) {
                    it("should return 938") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: "0938"]
                        expect(bundleMock.applicationIdentifier).to(equal(938))
                    }
                }

                context(#"When the application identifier is String and set to "hello world" in the Bundle"#) {
                    it("should return 1") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: "hello world"]
                        expect(bundleMock.applicationIdentifier).to(equal(1))
                    }
                }

                context("When the application identifier is Boolean and set to false") {
                    it("should return 1") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: false]
                        expect(bundleMock.applicationIdentifier).to(equal(1))
                    }
                }

                context("When the application identifier is Boolean and set to true") {
                    it("should return 1") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: true]
                        expect(bundleMock.applicationIdentifier).to(equal(1))
                    }
                }

                context("When the application identifier is Array") {
                    it("should return 1") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: [45, 76, 89]]
                        expect(bundleMock.applicationIdentifier).to(equal(1))
                    }
                }

                context("When the application identifier is Dictionary") {
                    it("should return 1") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: ["key1": "value1", "key2": "value2"]]
                        expect(bundleMock.applicationIdentifier).to(equal(1))
                    }
                }

                context("When the application identifier is Data") {
                    it("should return 1") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: Data()]
                        expect(bundleMock.applicationIdentifier).to(equal(1))
                    }
                }

                context("When the application identifier is Date") {
                    it("should return 1") {
                        bundleMock.injectedDictionary = [RATAccount.CodingKeys.applicationId.rawValue: Date()]
                        expect(bundleMock.applicationIdentifier).to(equal(1))
                    }
                }
            }

            describe("endpointAddress") {
                it("should return user-defined RAT url if user set RAT url in app info.plist") {
                    bundleMock.injectedDictionary = ["RATEndpoint": "https://example.com"]
                    expect(bundleMock.endpointAddress?.absoluteString).to(equal("https://example.com"))
                }

                it("should return production RAT url if user set an empty RAT url in app info.plist") {
                    bundleMock.injectedDictionary = ["RATEndpoint": ""]
                    expect(bundleMock.endpointAddress?.absoluteString).to(equal("https://rat.rakuten.co.jp/"))
                }

                it("should return production RAT url if user did not set RAT url in app info.plist") {
                    bundleMock.injectedDictionary = [:]
                    expect(bundleMock.endpointAddress?.absoluteString).to(equal("https://rat.rakuten.co.jp/"))
                }

                it("should return production RAT url if the info dictionary is nil") {
                    bundleMock.injectedDictionary = nil
                    expect(bundleMock.endpointAddress?.absoluteString).to(equal("https://rat.rakuten.co.jp/"))
                }
            }

            describe("useDefaultSharedCookieStorage") {
                it("should return false if user set 'disable shared cookie storage' key to true in app info.plist") {
                    bundleMock.injectedDictionary = ["RATDisableSharedCookieStorage": true]
                    expect(bundleMock.useDefaultSharedCookieStorage).to(beFalse())
                }

                it("should return true if user set 'disable shared cookie storage' key to false in app info.plist") {
                    bundleMock.injectedDictionary = ["RATDisableSharedCookieStorage": false]
                    expect(bundleMock.useDefaultSharedCookieStorage).to(beTrue())
                }

                it("should return true if user did not set 'disable shared cookie storage' key") {
                    bundleMock.injectedDictionary = [:]
                    expect(bundleMock.useDefaultSharedCookieStorage).to(beTrue())
                }

                it("should return true if the info dictionary is nil") {
                    bundleMock.injectedDictionary = nil
                    expect(bundleMock.useDefaultSharedCookieStorage).to(beTrue())
                }
            }

            describe("databaseParentDirectory") {
                it("should return the default value when RATStoreDatabaseInApplicationSupportDirectory is not set") {
                    bundleMock.injectedDictionary = [:]
                    expect(bundleMock.databaseParentDirectory).to(equal(.documentDirectory))
                }

                it("should return the expected value when RATStoreDatabaseInApplicationSupportDirectory is set") {
                    bundleMock.injectedDictionary = ["RATStoreDatabaseInApplicationSupportDirectory": false]
                    expect(bundleMock.databaseParentDirectory).to(equal(.documentDirectory))

                    bundleMock.injectedDictionary = ["RATStoreDatabaseInApplicationSupportDirectory": true]
                    expect(bundleMock.databaseParentDirectory).to(equal(.applicationSupportDirectory))
                }
            }

            describe("backgroundLocationUpdates") {
                it("should return false when value is not set") {
                    bundleMock.injectedDictionary = [:]
                    expect(bundleMock.backgroundLocationUpdates).to(beFalse())
                }

                it("should return true when value is set") {
                    bundleMock.injectedDictionary = ["UIBackgroundModes": ["location"]]
                    expect(bundleMock.backgroundLocationUpdates).to(beTrue())
                }
            }

            describe("sdkComponentMap") {
                it("should not return nil") {
                    let sdkComponentMap = Bundle.sdkComponentMap
                    expect(sdkComponentMap).toNot(beNil())
                    expect(sdkComponentMap?["org.cocoapods.RPushPNP"] as? String).to(equal("pushpnp"))
                    expect(sdkComponentMap?["org.cocoapods.RInAppMessaging"] as? String).to(equal("inappmessaging"))
                }
            }

            describe("applicationSceneManifest") {
                context("When the bundle dictionary is nil") {
                    it("should return nil") {
                        bundleMock.injectedDictionary = nil

                        expect(bundleMock.applicationSceneManifest).to(beNil())
                    }
                }

                context("When the bundle dictionary is empty") {
                    it("should return nil") {
                        bundleMock.injectedDictionary = [:]

                        expect(bundleMock.applicationSceneManifest).to(beNil())
                    }
                }

                context("When the bundle dictionary contains a nil SceneDelegate class name") {
                    let dictionary = ["UIApplicationSceneManifest":
                                        ["UIApplicationSupportsMultipleScenes": false,
                                         "UISceneConfigurations":
                                            ["UIWindowSceneSessionRoleApplication":
                                                [["UISceneDelegateClassName": nil]]]]]

                    beforeEach {
                        bundleMock.injectedDictionary = dictionary
                    }

                    it("should not return nil") {
                        expect(bundleMock.applicationSceneManifest).toNot(beNil())
                    }

                    it("should return a nil SceneDelegate class name") {
                        expect(bundleMock.applicationSceneManifest?.firstSceneDelegateClassName).to(beNil())
                    }
                }

                context("When the bundle dictionary contains an empty SceneDelegate class name") {
                    let dictionary = ["UIApplicationSceneManifest":
                                        ["UIApplicationSupportsMultipleScenes": false,
                                         "UISceneConfigurations":
                                            ["UIWindowSceneSessionRoleApplication":
                                                [["UISceneDelegateClassName": ""]]]]]

                    beforeEach {
                        bundleMock.injectedDictionary = dictionary
                    }

                    it("should not return nil") {
                        expect(bundleMock.applicationSceneManifest).toNot(beNil())
                    }

                    it("should return an empty SceneDelegate class name") {
                        expect(bundleMock.applicationSceneManifest?.firstSceneDelegateClassName).to(beEmpty())
                    }
                }

                context("When the bundle dictionary contains a non-nil SceneDelegate class name") {
                    let dictionary = ["UIApplicationSceneManifest":
                                        ["UIApplicationSupportsMultipleScenes": false,
                                         "UISceneConfigurations":
                                            ["UIWindowSceneSessionRoleApplication":
                                                [["UISceneDelegateClassName": "SceneDelegate"]]]]]

                    beforeEach {
                        bundleMock.injectedDictionary = dictionary
                    }

                    it("should not return nil") {
                        expect(bundleMock.applicationSceneManifest).toNot(beNil())
                    }

                    it("should return a non-nil SceneDelegate class name") {
                        expect(bundleMock.applicationSceneManifest?.firstSceneDelegateClassName).to(equal("SceneDelegate"))
                    }
                }
            }
        }
    }
}

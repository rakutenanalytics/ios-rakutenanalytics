import Quick
import Nimble
import Foundation
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - EnvironmentBundleMock

private final class EnvironmentBundleMock: Bundle {
    var injectedDictionary: [String: Any]?

    override var infoDictionary: [String: Any]? {
        injectedDictionary
    }
}

// MARK: - EnvironmentBundleSpec

final class EnvironmentBundleSpec: QuickSpec {

    override func spec() {
        describe("EnvironmentBundle") {
            let bundleMock = EnvironmentBundleMock()

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

            describe("sdkComponentMap") {
                it("should not return nil") {
                    let sdkComponentMap = Bundle.sdkComponentMap
                    expect(sdkComponentMap).toNot(beNil())
                    expect(sdkComponentMap?["org.cocoapods.RPing"] as? String).to(equal("ping"))
                    expect(sdkComponentMap?["org.cocoapods.RAnalytics"] as? String).to(equal("analytics"))
                    expect(sdkComponentMap?["org.cocoapods.RDiscover"] as? String).to(equal("discover"))
                    expect(sdkComponentMap?["org.cocoapods.RFeedback"] as? String).to(equal("feedback"))
                    expect(sdkComponentMap?["org.cocoapods.RPushPNP"] as? String).to(equal("pushpnp"))
                    expect(sdkComponentMap?["org.cocoapods.RInAppMessaging"] as? String).to(equal("inappmessaging"))
                }
            }
        }
    }
}

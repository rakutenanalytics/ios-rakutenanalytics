import Quick
import Nimble
@testable import RAnalytics

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
        }
    }
}

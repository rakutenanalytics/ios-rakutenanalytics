import Quick
import Nimble
import Foundation
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - CoreHelpersSpec

final class CoreHelpersSpec: QuickSpec {
    override func spec() {
        describe("CoreHelpers") {
            describe("getCollectedInfos()") {
                context("sdkComponentMap is not nil") {
                    it("should return a non-nil dictionary") {
                        let dictionary = CoreHelpers.getCollectedInfos()

                        expect(dictionary).toNot(beNil())
                    }

                    it("should return a dictionary with app info entry") {
                        let dictionary = CoreHelpers.getCollectedInfos()

                        expect(dictionary?[RAnalyticsConstants.rAnalyticsAppInfoKey]).toNot(beNil())
                    }

                    it("should return a dictionary with app info's parameters entries") {
                        let dictionary = CoreHelpers.getCollectedInfos()
                        let appInfo = dictionary?[RAnalyticsConstants.rAnalyticsAppInfoKey] as? [String: Any]

                        expect(appInfo?["xcode"]).toNot(beNil())

                        #if SWIFT_PACKAGE
                        // non-apple frameworks array is empty with SPM
                        #else
                        expect(appInfo?["frameworks"]).toNot(beNil())
                        #endif

                        expect(appInfo?["sdk"]).toNot(beNil())
                        expect(appInfo?["deployment_target"]).toNot(beNil())
                    }

                    context("sdkComponentMap contains analytics entries") {
                        let sdkComponentMap: NSDictionary = ["org.cocoapods.RAnalytics": "analytics"]

                        // Note: this case should not happen as CoreHelpers is called from RAnalytics framework.
                        context("The app is built without SDKs") {
                            let allFrameworks: [EnvironmentBundle] = []

                            it("should return a dictionary with an empty sdk info") {
                                let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap,
                                                                               allFrameworks: allFrameworks)

                                let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]

                                expect(sdks as? [String: String]).to(beEmpty())
                            }
                        }

                        context("The app is built with RAnalytics") {
                            let allFrameworks: [EnvironmentBundle] = [BundleMock(bundleIdentifier: "org.cocoapods.RAnalytics",
                                                                                 shortVersion: "9.8.0")]

                            it("should return a dictionary with empty sdk info") {
                                let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap,
                                                                               allFrameworks: allFrameworks)

                                let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]

                                expect(sdks as? [String: String]).to(beEmpty())
                            }
                        }
                    }

                    context("sdkComponentMap contains inappmessaging and pushpnp entries") {
                        let sdkComponentMap: NSDictionary = ["org.cocoapods.RInAppMessaging": "inappmessaging",
                                                             "org.cocoapods.RPushPNP": "pushpnp"]

                        // Note: this case should not happen as CoreHelpers is called from RAnalytics framework.
                        context("The app is built without SDKs") {
                            let allFrameworks: [EnvironmentBundle] = []

                            it("should return a dictionary with an empty sdk info") {
                                let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap,
                                                                               allFrameworks: allFrameworks)

                                let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]

                                expect(sdks as? [String: String]).to(beEmpty())
                            }
                        }

                        context("The app is built with RInAppMessaging") {
                            let allFrameworks: [EnvironmentBundle] = [BundleMock(bundleIdentifier: "org.cocoapods.RInAppMessaging",
                                                                                 shortVersion: "7.2.0")]

                            it("should return a dictionary with sdk info containing rsdks_inappmessaging entry") {
                                let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap,
                                                                               allFrameworks: allFrameworks)

                                let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]

                                expect(sdks as? [String: String]).to(equal(["rsdks_inappmessaging": "7.2.0"]))
                            }
                        }

                        context("The app is built with RPushPNP") {
                            let allFrameworks: [EnvironmentBundle] = [BundleMock(bundleIdentifier: "org.cocoapods.RPushPNP", shortVersion: "10.0.0")]

                            it("should return a dictionary with sdk info containing rsdks_pushpnp entry") {
                                let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap,
                                                                               allFrameworks: allFrameworks)

                                let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]

                                expect(sdks as? [String: String]).to(equal(["rsdks_pushpnp": "10.0.0"]))
                            }
                        }

                        context("The app is built with RInAppMessaging and RPushPNP") {
                            let allFrameworks: [EnvironmentBundle] = [BundleMock(bundleIdentifier: "org.cocoapods.RInAppMessaging",
                                                                                 shortVersion: "7.2.0"),
                                                                      BundleMock(bundleIdentifier: "org.cocoapods.RPushPNP",
                                                                                 shortVersion: "10.0.0")]

                            it("should return a dictionary with sdk info containing rsdks_inappmessaging and rsdks_pushpnp entries") {
                                let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap,
                                                                               allFrameworks: allFrameworks)

                                let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]

                                expect(sdks as? [String: String]).to(equal(["rsdks_inappmessaging": "7.2.0",
                                                                            "rsdks_pushpnp": "10.0.0"]))
                            }
                        }
                    }

                    context("sdkComponentMap is empty") {
                        let sdkComponentMap: NSDictionary = [:]

                        it("should return a dictionary not containing RAnalyticsFrameworkIdentifiers") {
                            let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap)
                            let appInfo = dictionary?[RAnalyticsConstants.rAnalyticsAppInfoKey] as? [String: Any]

                            expect((appInfo?["frameworks"] as? [String: Any])?[RAnalyticsFrameworkIdentifiers.appleIdentifier])
                                .to(beNil())
                            expect((appInfo?["frameworks"] as? [String: Any])?[RAnalyticsFrameworkIdentifiers.analyticsIdentifier])
                                .to(beNil())
                            expect((appInfo?["frameworks"] as? [String: Any])?[RAnalyticsFrameworkIdentifiers.analyticsPublicFrameworkIdentifier])
                                .to(beNil())
                            expect((appInfo?["frameworks"] as? [String: Any])?[RAnalyticsFrameworkIdentifiers.sdkUtilsIdentifier])
                                .to(beNil())
                        }

                        it("should return a dictionary with an empty sdk info entry") {
                            let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap)
                            let sdks = dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey] as? [String: String]

                            expect(sdks).to(beEmpty())
                        }

                        it("should return a dictionary with sdk info's not containing analytics entry") {
                            let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap)

                            expect((dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey] as? [String: Any])?[RModulesListKeys.analyticsValue])
                                .to(beNil())
                        }
                    }
                }

                context("sdkComponentMap is nil") {
                    it("should return a non-nil dictionary") {
                        let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: nil)

                        expect(dictionary).toNot(beNil())
                    }

                    it("should return a dictionary with app info entry") {
                        let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: nil)

                        expect(dictionary?[RAnalyticsConstants.rAnalyticsAppInfoKey]).toNot(beNil())
                    }

                    it("should return a dictionary with app info's parameters entries") {
                        let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: nil)
                        let appInfo = dictionary?[RAnalyticsConstants.rAnalyticsAppInfoKey] as? [String: Any]

                        expect(appInfo?["xcode"]).toNot(beNil())

                        #if SWIFT_PACKAGE
                        // non-apple frameworks array is empty with SPM
                        #else
                        expect(appInfo?["frameworks"]).toNot(beNil())
                        #endif
                        expect(appInfo?["sdk"]).toNot(beNil())
                        expect(appInfo?["deployment_target"]).toNot(beNil())
                    }

                    it("should return a dictionary with sdk info entry") {
                        let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: nil)

                        expect(dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]).toNot(beNil())
                    }

                    it("should return a dictionary with sdk info's not containing analytics entry") {
                        let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: nil)

                        expect((dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey] as? [String: Any])?[RModulesListKeys.analyticsValue])
                            .to(beNil())
                    }
                }
            }
        }
    }
}

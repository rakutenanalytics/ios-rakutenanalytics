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

                    context("sdkComponentMap having app info with parameter frameworks") {
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
                    }

                    context("sdkComponentMap does not contain analytics entry") {
                        let sdkComponentMap: NSDictionary = [:]

                        it("should return a dictionary with sdk info entry") {
                            let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap)

                            expect(dictionary?[RAnalyticsConstants.rAnalyticsSDKInfoKey]).toNot(beNil())
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

import Quick
import Nimble
@testable import RAnalytics

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

                        expect(dictionary?[RAnalyticsConstants.RAnalyticsAppInfoKey]).toNot(beNil())
                    }

                    it("should return a dictionary with app info's parameters entries") {
                        let dictionary = CoreHelpers.getCollectedInfos()
                        let appInfo = dictionary?[RAnalyticsConstants.RAnalyticsAppInfoKey] as? [String: Any]

                        expect(appInfo?["xcode"]).toNot(beNil())
                        expect(appInfo?["frameworks"]).toNot(beNil())
                        expect(appInfo?["sdk"]).toNot(beNil())
                        expect(appInfo?["deployment_target"]).toNot(beNil())
                    }

                    context("sdkComponentMap contains analytics entry") {
                        let sdkComponentMap: NSDictionary = ["org.cocoapods.RAnalytics": RModulesListKeys.analyticsValue]

                        it("should return a dictionary with sdk info entry") {
                            let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap)

                            expect(dictionary?[RAnalyticsConstants.RAnalyticsSDKInfoKey]).toNot(beNil())
                        }

                        it("should return a dictionary with sdk info's analytics entry") {
                            let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap)

                            expect((dictionary?[RAnalyticsConstants.RAnalyticsSDKInfoKey] as? [String: Any])?[RModulesListKeys.analyticsValue])
                                .toNot(beNil())
                        }
                    }

                    context("sdkComponentMap does not contain analytics entry") {
                        let sdkComponentMap: NSDictionary = [:]

                        it("should return a dictionary with sdk info entry") {
                            let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap)

                            expect(dictionary?[RAnalyticsConstants.RAnalyticsSDKInfoKey]).toNot(beNil())
                        }

                        it("should return a dictionary with sdk info's analytics entry") {
                            let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: sdkComponentMap)

                            expect((dictionary?[RAnalyticsConstants.RAnalyticsSDKInfoKey] as? [String: Any])?[RModulesListKeys.analyticsValue])
                                .toNot(beNil())
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

                        expect(dictionary?[RAnalyticsConstants.RAnalyticsAppInfoKey]).toNot(beNil())
                    }

                    it("should return a dictionary with app info's parameters entries") {
                        let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: nil)
                        let appInfo = dictionary?[RAnalyticsConstants.RAnalyticsAppInfoKey] as? [String: Any]

                        expect(appInfo?["xcode"]).toNot(beNil())
                        expect(appInfo?["frameworks"]).toNot(beNil())
                        expect(appInfo?["sdk"]).toNot(beNil())
                        expect(appInfo?["deployment_target"]).toNot(beNil())
                    }

                    it("should return a dictionary with sdk info entry") {
                        let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: nil)

                        expect(dictionary?[RAnalyticsConstants.RAnalyticsSDKInfoKey]).toNot(beNil())
                    }

                    it("should return a dictionary with sdk info's analytics entry") {
                        let dictionary = CoreHelpers.getCollectedInfos(sdkComponentMap: nil)

                        expect((dictionary?[RAnalyticsConstants.RAnalyticsSDKInfoKey] as? [String: Any])?[RModulesListKeys.analyticsValue])
                            .toNot(beNil())
                    }
                }
            }
        }
    }
}

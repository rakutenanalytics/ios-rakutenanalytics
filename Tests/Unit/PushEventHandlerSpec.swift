import Quick
import Nimble
@testable import RAnalytics

final class PushEventHandlerSpec: QuickSpec {

    override func spec() {
        describe("PushEventHandler") {
            let sentTrackingId = "a_good_tracking_id"
            let appGroupDictionary = [RPushTrackingKeys.AppGroupIdentifierPlistKey: "appGroupId"]
            let openCountDictionary = [RPushTrackingKeys.OpenCountSentUserDefaultKey: [sentTrackingId: true]]

            describe("isEventAlreadySent") {
                context("RRPushAppGroupIdentifierPlistKey is not set in the main bundle") {
                    let pushEventHandler = PushEventHandler(sharedUserStorageHandler: UserDefaultsMock(suiteName: BundleMock().appGroupId))

                    it("should return false when trackingIdentifier is not nil") {
                        expect(pushEventHandler.isEventAlreadySent(with: sentTrackingId)).to(beFalse())
                    }

                    it("should return false when trackingIdentifier is nil") {
                        expect(pushEventHandler.isEventAlreadySent(with: nil)).to(beFalse())
                    }
                }

                context("RRPushAppGroupIdentifierPlistKey is set in the main bundle") {
                    let bundleMock: BundleMock = {
                        let bundleMock = BundleMock()
                        bundleMock.dictionary = appGroupDictionary
                        return bundleMock
                    }()

                    context("valid open count dictionary") {
                        let pushEventHandler: PushEventHandler = {
                            let pushEventHandler = PushEventHandler(sharedUserStorageHandler: UserDefaultsMock(suiteName: bundleMock.appGroupId))
                            (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = openCountDictionary
                            return pushEventHandler
                        }()

                        it("should return true when trackingIdentifier is not nil") {
                            expect(pushEventHandler.isEventAlreadySent(with: sentTrackingId)).to(beTrue())
                        }

                        it("should return false when trackingIdentifier is nil") {
                            expect(pushEventHandler.isEventAlreadySent(with: nil)).to(beFalse())
                        }
                    }

                    context("invalid open count dictionary") {
                        let pushEventHandler = PushEventHandler(sharedUserStorageHandler: UserDefaultsMock(suiteName: bundleMock.appGroupId))

                        it("should return false when trackingIdentifier is not nil and open count dictionary is empty") {
                            (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                            expect(pushEventHandler.isEventAlreadySent(with: sentTrackingId)).to(beFalse())
                        }

                        it("should return false when trackingIdentifier is not nil and open count dictionary is nil") {
                            (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = nil
                            expect(pushEventHandler.isEventAlreadySent(with: sentTrackingId)).to(beFalse())
                        }

                        it("should return false when trackingIdentifier is nil and open count dictionary is empty") {
                            (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                            expect(pushEventHandler.isEventAlreadySent(with: nil)).to(beFalse())
                        }

                        it("should return false when trackingIdentifier is nil and open count dictionary is nil") {
                            (pushEventHandler.sharedUserStorageHandler as? UserDefaultsMock)?.dictionary = nil
                            expect(pushEventHandler.isEventAlreadySent(with: nil)).to(beFalse())
                        }
                    }
                }
            }

            describe("cacheEvent(for:)") {
                context("The shared app group user defaults is nil") {
                    let pushEventHandler = PushEventHandler(sharedUserStorageHandler: nil)

                    it("should not cache the event tracking identifier") {
                        expect(pushEventHandler.cacheEvent(for: sentTrackingId)).to(beFalse())
                    }
                }

                context("The shared app group user defaults is not nil") {
                    let sharedUserDefaults = UserDefaultsMock(suiteName: "group.app")
                    sharedUserDefaults?.dictionary = [:]
                    let pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults)

                    it("should cache the event tracking identifier") {
                        expect(pushEventHandler.cacheEvent(for: sentTrackingId)).to(beTrue())
                    }

                    it("should set the tracking identifier caching status to true") {
                        let openSentMap = sharedUserDefaults?.object(forKey: RPushTrackingKeys.OpenCountSentUserDefaultKey) as? [String: Bool]
                        expect(openSentMap?[sentTrackingId]).to(beTrue())
                    }
                }
            }

            describe("clearCache()") {
                context("The shared app group user defaults is nil") {
                    let pushEventHandler = PushEventHandler(sharedUserStorageHandler: nil)

                    it("should return false") {
                        expect(pushEventHandler.clearCache()).to(beFalse())
                    }
                }

                context("The shared app group user defaults is not nil") {
                    let sharedUserDefaults = UserDefaultsMock(suiteName: "group.app")
                    sharedUserDefaults?.dictionary = [:]
                    let pushEventHandler = PushEventHandler(sharedUserStorageHandler: sharedUserDefaults)

                    it("should set the cache to nil") {
                        pushEventHandler.cacheEvent(for: sentTrackingId)
                        pushEventHandler.clearCache()

                        expect(sharedUserDefaults?.object(forKey: RPushTrackingKeys.OpenCountSentUserDefaultKey)).to(beNil())
                    }

                    it("should return true") {
                        expect(pushEventHandler.clearCache()).to(beTrue())
                    }
                }
            }
        }
    }
}

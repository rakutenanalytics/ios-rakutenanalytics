import Quick
import Nimble
@testable import RAnalytics

final class RAnalyticsPushTrackingUtilitySpec: QuickSpec {
    override func spec() {
        describe("RAnalyticsPushTrackingUtility") {
            describe("trackingIdentifier") {
                let rid = "123456"
                let nid = "654321"
                let nidKey = "notification_id"
                let ridAsTrackingId = "rid:\(rid)"
                let nidAsTrackingId = "nid:\(nid)"
                let alertString = "hello world"
                let alertMsgAsTrackingId = "msg:\(alertString.ratEncrypt!)"

                context("returns a valid tracking id") {
                    context("using the rid in the payload") {
                        it("has only a valid rid") {
                            let payload: [String: Any] = ["rid": rid]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(ridAsTrackingId))
                        }
                        it("is a background push") {
                            let payload: [String: Any] = ["rid": rid, "aps": ["content-available": true, "alert": alertString]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(ridAsTrackingId))
                        }
                        it("is a background push with body and title payload") {
                            let payload: [String: Any] = ["rid": rid, "aps": ["content-available": true, "alert": ["body": alertString]]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(ridAsTrackingId))
                        }
                        it("content-available is false") {
                            let payload: [String: Any] = ["rid": rid, "aps": ["content-available": false, "alert": ["body": alertString]]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(ridAsTrackingId))
                        }
                        it("has notification_id in payload") {
                            let payload: [String: Any] = ["rid": rid, nidKey: nid]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(ridAsTrackingId))
                        }
                        it("has notification_id in payload and is background push") {
                            let payload: [String: Any] = ["rid": rid, nidKey: nid, "aps": ["content-available": true, "alert": alertString]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(ridAsTrackingId))
                        }
                    }
                    context("using notification_id in payload") {
                        it("has only a valid notification_id") {
                            let payload: [String: Any] = [nidKey: nid]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(nidAsTrackingId))
                        }
                        it("is a background push") {
                            let payload: [String: Any] = [nidKey: nid, "aps": ["content-available": true, "alert": alertString]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(nidAsTrackingId))
                        }
                        it("is a background push with body and title payload") {
                            let payload: [String: Any] = [nidKey: nid, "aps": ["content-available": true, "alert": ["body": alertString]]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(nidAsTrackingId))
                        }
                        it("content-available is false") {
                            let payload: [String: Any] = [nidKey: nid, "aps": ["content-available": false, "alert": ["body": alertString]]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(nidAsTrackingId))
                        }
                        it("has an empty rid in payload") {
                            let payload: [String: Any] = ["rid": "", nidKey: nid]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(nidAsTrackingId))
                        }
                        it("has an invalid rid in payload") {
                            let payload: [String: Any] = ["rid": 1111, nidKey: nid]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(nidAsTrackingId))
                        }
                    }
                    context("using encrypted alert message in payload") {
                        it("has only a valid alert as String") {
                            let payload: [String: Any] = ["aps": ["alert": alertString]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(alertMsgAsTrackingId))
                        }
                        it("has a body in the alert") {
                            let payload: [String: Any] = ["aps": ["alert": ["body": alertString]]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(alertMsgAsTrackingId))
                        }
                        it("has a title in the alert ") {
                            let payload: [String: Any] = ["aps": ["alert": ["title": alertString]]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(alertMsgAsTrackingId))
                        }
                        it("has a body and title in the alert should use body") {
                            let titleString = "titleString"
                            let payload: [String: Any] = ["aps": ["alert": ["title": titleString, "body": alertString]]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(alertMsgAsTrackingId))
                        }
                        it("is a background push with body and title payload") {
                            let payload: [String: Any] = ["aps": ["content-available": true, "alert": ["body": alertString]]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(alertMsgAsTrackingId))
                        }
                        it("content-available is false") {
                            let payload: [String: Any] = ["aps": ["content-available": false, "alert": ["body": alertString]]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(alertMsgAsTrackingId))
                        }
                        it("has an empty rid and empty nid in payload") {
                            let payload: [String: Any] = ["rid": "", nidKey: "", "aps": ["alert": ["body": alertString]]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(alertMsgAsTrackingId))
                        }
                        it("has an invalid rid and invalid nid in payload") {
                            let payload: [String: Any] = ["rid": 12312, nidKey: 2322, "aps": ["alert": ["body": alertString]]]
                            expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(equal(alertMsgAsTrackingId))
                        }
                    }
                }
                context("returns null") {
                    it("is a silent push notification with valid rid and nid") {
                        let payload: [String: Any] = ["aps": ["content-available": true], "rid": "654321", nidKey: "123456"]
                        expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(beNil())
                    }
                    it("alert with empty string") {
                        let payload: [String: Any] = ["aps": ["alert": ""]]
                        expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(beNil())
                    }
                    it("has invalid notification_id, rid, and aps in the payload") {
                        let payload: [String: Any] = ["aps": [:], "rid": "", nidKey: ""]
                        expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(beNil())
                    }
                    it("does not have an alert in the aps") {
                        let payload: [String: Any] = ["aps": [:]]
                        expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(beNil())
                    }
                    it("alert dictionary has an empty body") {
                        let payload: [String: Any] = ["aps": ["alert": ["body": ""]]]
                        expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(beNil())
                    }
                    it("alert dictionary has an empty title") {
                        let payload: [String: Any] = ["aps": ["alert": ["title": ""]]]
                        expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(beNil())
                    }
                    it("alert dictionary has an empty body and title") {
                        let payload: [String: Any] = ["aps": ["alert": ["title": "", "body": ""]]]
                        expect(RAnalyticsPushTrackingUtility.trackingIdentifier(fromPayload: payload)).to(beNil())
                    }
                }
            }
            describe("analyticsEventHasBeenSentWith") {
                let sentTrackingId = "a_good_tracking_id"
                let appGroupDictionary = [RPushTrackingKeys.AppGroupIdentifierPlistKey: "appGroupId"]
                let openCountDictionary = [RPushTrackingKeys.OpenCountSentUserDefaultKey: [sentTrackingId: true]]

                context("RRPushAppGroupIdentifierPlistKey is not set in the main bundle") {
                    let pushEventHandler = PushEventHandler(bundle: BundleMock(), userDefaultsType: UserDefaultsMock.self)

                    it("should return false when trackingIdentifier is not nil") {
                        expect(pushEventHandler.userStorageHandler as? UserDefaultsMock).to(beNil())
                        expect(pushEventHandler.eventHasBeenSent(with: sentTrackingId)).to(beFalse())
                    }
                    it("should return false when trackingIdentifier is nil") {
                        expect(pushEventHandler.userStorageHandler as? UserDefaultsMock).to(beNil())
                        expect(pushEventHandler.eventHasBeenSent(with: nil)).to(beFalse())
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
                            let pushEventHandler = PushEventHandler(bundle: bundleMock, userDefaultsType: UserDefaultsMock.self)
                            (pushEventHandler.userStorageHandler as? UserDefaultsMock)?.dictionary = openCountDictionary
                            return pushEventHandler
                        }()

                        it("should return true when trackingIdentifier is not nil") {
                            expect(pushEventHandler.userStorageHandler as? UserDefaultsMock).toNot(beNil())
                            expect(pushEventHandler.eventHasBeenSent(with: sentTrackingId)).to(beTrue())
                        }
                        it("should return false when trackingIdentifier is nil") {
                            expect(pushEventHandler.userStorageHandler as? UserDefaultsMock).toNot(beNil())
                            expect(pushEventHandler.eventHasBeenSent(with: nil)).to(beFalse())
                        }
                    }
                    context("invalid open count dictionary") {
                        let pushEventHandler: PushEventHandler = PushEventHandler(bundle: bundleMock, userDefaultsType: UserDefaultsMock.self)

                        it("should return false when trackingIdentifier is not nil and open count dictionary is empty") {
                            (pushEventHandler.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                            expect(pushEventHandler.userStorageHandler as? UserDefaultsMock).toNot(beNil())
                            expect(pushEventHandler.eventHasBeenSent(with: sentTrackingId)).to(beFalse())
                        }
                        it("should return false when trackingIdentifier is not nil and open count dictionary is nil") {
                            (pushEventHandler.userStorageHandler as? UserDefaultsMock)?.dictionary = nil
                            expect(pushEventHandler.userStorageHandler as? UserDefaultsMock).toNot(beNil())
                            expect(pushEventHandler.eventHasBeenSent(with: sentTrackingId)).to(beFalse())
                        }
                        it("should return false when trackingIdentifier is nil and open count dictionary is empty") {
                            (pushEventHandler.userStorageHandler as? UserDefaultsMock)?.dictionary = [:]
                            expect(pushEventHandler.userStorageHandler as? UserDefaultsMock).toNot(beNil())
                            expect(pushEventHandler.eventHasBeenSent(with: nil)).to(beFalse())
                        }
                        it("should return false when trackingIdentifier is nil and open count dictionary is nil") {
                            (pushEventHandler.userStorageHandler as? UserDefaultsMock)?.dictionary = nil
                            expect(pushEventHandler.userStorageHandler as? UserDefaultsMock).toNot(beNil())
                            expect(pushEventHandler.eventHasBeenSent(with: nil)).to(beFalse())
                        }
                    }
                }
            }
        }
    }
}

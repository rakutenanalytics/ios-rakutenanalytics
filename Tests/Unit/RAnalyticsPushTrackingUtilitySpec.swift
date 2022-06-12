import Quick
import Nimble
import Foundation
@testable import RAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class RAnalyticsPushTrackingUtilitySpec: QuickSpec {
    override func spec() {
        describe("RAnalyticsPushTrackingUtility") {
            describe("pushRequestIdentifier(from:)") {
                context("The APNS payload is empty") {
                    it("should return a nil request id") {
                        let payload: [AnyHashable: Any] = [:]
                        let result = RAnalyticsPushTrackingUtility.pushRequestIdentifier(from: payload)

                        expect(result).to(beNil())
                    }
                }

                context("_pnp_reserved is nil") {
                    it("should return a nil request id") {
                        let payload: [AnyHashable: Any?] = ["_pnp_reserved": nil]
                        let result = RAnalyticsPushTrackingUtility.pushRequestIdentifier(from: payload as [AnyHashable: Any])

                        expect(result).to(beNil())
                    }
                }

                context("_pnp_reserved is empty") {
                    it("should return a nil request id") {
                        let payload: [AnyHashable: Any?] = ["_pnp_reserved": [:]]
                        let result = RAnalyticsPushTrackingUtility.pushRequestIdentifier(from: payload as [AnyHashable: Any])

                        expect(result).to(beNil())
                    }
                }

                context("request_id is nil") {
                    it("should return a nil request id") {
                        let payload: [AnyHashable: Any] = ["_pnp_reserved":
                                                            ["request_id": nil]]
                        let result = RAnalyticsPushTrackingUtility.pushRequestIdentifier(from: payload)

                        expect(result).to(beNil())
                    }
                }

                context("request_id is empty") {
                    it("should return a nil request id") {
                        let payload: [AnyHashable: Any] = ["_pnp_reserved": ["request_id": ""]]
                        let result = RAnalyticsPushTrackingUtility.pushRequestIdentifier(from: payload)

                        expect(result).to(beNil())
                    }
                }

                context("request_id is not empty") {
                    it("should return the expected request id") {
                        let expectedRequestId = "ichiba_iphone_long,2517554993982709815,f1f358ce-5ffb-4c01-8b59-994e72b8915b"
                        let payload: [AnyHashable: Any] = ["_pnp_reserved":
                                                            ["request_id": expectedRequestId]]
                        let result = RAnalyticsPushTrackingUtility.pushRequestIdentifier(from: payload)

                        expect(result).to(equal(expectedRequestId))
                    }
                }
            }

            describe("trackPushConversionEvent(pushRequestIdentifier:pushConversionAction:) ") {
                it("should throw an error if pushRequestIdentifier and pushConversionAction are empty") {
                    expect {
                        try RAnalyticsPushTrackingUtility.trackPushConversionEvent(pushRequestIdentifier: "",
                                                                                   pushConversionAction: "")

                    }.to(throwError())
                }

                it("should throw an error if pushRequestIdentifier is empty") {
                    expect {
                        try RAnalyticsPushTrackingUtility.trackPushConversionEvent(pushRequestIdentifier: "",
                                                                                   pushConversionAction: "pushConversionAction")

                    }.to(throwError())
                }

                it("should throw an error if pushConversionAction is empty") {
                    expect {
                        try RAnalyticsPushTrackingUtility.trackPushConversionEvent(pushRequestIdentifier: "pushRequestIdentifier",
                                                                                   pushConversionAction: "")

                    }.to(throwError())
                }

                it("should not throw an error if pushRequestIdentifier and pushConversionAction are not empty") {
                    expect {
                        try RAnalyticsPushTrackingUtility.trackPushConversionEvent(pushRequestIdentifier: "pushRequestIdentifier",
                                                                                   pushConversionAction: "pushConversionAction")

                    }.toNot(throwError())
                }
            }

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
                let appGroupDictionary = [AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey: "appGroupId"]
                let openCountDictionary = [PushEventHandlerKeys.openCountSentUserDefaultKey: [sentTrackingId: true]]
                let bundleMock = BundleMock()
                let userStorageHandler = UserDefaultsMock(suiteName: bundleMock.appGroupId)

                context("RRPushAppGroupIdentifierPlistKey is not set in the main bundle") {
                    it("should return false when trackingIdentifier is not nil") {
                        expect(RAnalyticsPushTrackingUtility.analyticsEventHasBeenSent(with: sentTrackingId,
                                                                                       sharedUserStorageHandler: userStorageHandler,
                                                                                       appGroupId: bundleMock.appGroupId,
                                                                                       fileManager: FileManager.default,
                                                                                       serializerType: JSONSerialization.self))
                            .to(beFalse())
                    }

                    it("should return false when trackingIdentifier is nil") {
                        expect(RAnalyticsPushTrackingUtility.analyticsEventHasBeenSent(with: nil,
                                                                                       sharedUserStorageHandler: userStorageHandler,
                                                                                       appGroupId: bundleMock.appGroupId,
                                                                                       fileManager: FileManager.default,
                                                                                       serializerType: JSONSerialization.self))
                            .to(beFalse())
                    }
                }

                context("RRPushAppGroupIdentifierPlistKey is set in the main bundle") {
                    let bundleMock: BundleMock = {
                        let bundleMock = BundleMock()
                        bundleMock.dictionary = appGroupDictionary
                        return bundleMock
                    }()

                    context("valid open count dictionary") {
                        let userStorageHandler = UserDefaultsMock(suiteName: bundleMock.appGroupId)
                        userStorageHandler?.dictionary = openCountDictionary

                        it("should return true when trackingIdentifier is not nil") {
                            expect(RAnalyticsPushTrackingUtility.analyticsEventHasBeenSent(with: sentTrackingId,
                                                                                           sharedUserStorageHandler: userStorageHandler,
                                                                                           appGroupId: bundleMock.appGroupId,
                                                                                           fileManager: FileManager.default,
                                                                                           serializerType: JSONSerialization.self))
                                .to(beTrue())
                        }

                        it("should return false when trackingIdentifier is nil") {
                            expect(RAnalyticsPushTrackingUtility.analyticsEventHasBeenSent(with: nil,
                                                                                           sharedUserStorageHandler: userStorageHandler,
                                                                                           appGroupId: bundleMock.appGroupId,
                                                                                           fileManager: FileManager.default,
                                                                                           serializerType: JSONSerialization.self))
                                .to(beFalse())
                        }
                    }

                    context("invalid open count dictionary") {
                        it("should return false when trackingIdentifier is not nil and open count dictionary is empty") {
                            let userStorageHandler = UserDefaultsMock(suiteName: bundleMock.appGroupId)
                            userStorageHandler?.dictionary = [:]

                            expect(RAnalyticsPushTrackingUtility.analyticsEventHasBeenSent(with: sentTrackingId,
                                                                                           sharedUserStorageHandler: userStorageHandler,
                                                                                           appGroupId: bundleMock.appGroupId,
                                                                                           fileManager: FileManager.default,
                                                                                           serializerType: JSONSerialization.self))
                                .to(beFalse())
                        }

                        it("should return false when trackingIdentifier is not nil and open count dictionary is nil") {
                            let userStorageHandler = UserDefaultsMock(suiteName: bundleMock.appGroupId)
                            userStorageHandler?.dictionary = nil

                            expect(RAnalyticsPushTrackingUtility.analyticsEventHasBeenSent(with: sentTrackingId,
                                                                                           sharedUserStorageHandler: userStorageHandler,
                                                                                           appGroupId: bundleMock.appGroupId,
                                                                                           fileManager: FileManager.default,
                                                                                           serializerType: JSONSerialization.self))
                                .to(beFalse())
                        }

                        it("should return false when trackingIdentifier is nil and open count dictionary is empty") {
                            let userStorageHandler = UserDefaultsMock(suiteName: bundleMock.appGroupId)
                            userStorageHandler?.dictionary = [:]

                            expect(RAnalyticsPushTrackingUtility.analyticsEventHasBeenSent(with: nil,
                                                                                           sharedUserStorageHandler: userStorageHandler,
                                                                                           appGroupId: bundleMock.appGroupId,
                                                                                           fileManager: FileManager.default,
                                                                                           serializerType: JSONSerialization.self))
                                .to(beFalse())
                        }

                        it("should return false when trackingIdentifier is nil and open count dictionary is nil") {
                            let userStorageHandler = UserDefaultsMock(suiteName: bundleMock.appGroupId)
                            userStorageHandler?.dictionary = nil

                            expect(RAnalyticsPushTrackingUtility.analyticsEventHasBeenSent(with: nil,
                                                                                           sharedUserStorageHandler: userStorageHandler,
                                                                                           appGroupId: bundleMock.appGroupId,
                                                                                           fileManager: FileManager.default,
                                                                                           serializerType: JSONSerialization.self))
                                .to(beFalse())
                        }
                    }
                }
            }
        }
    }
}

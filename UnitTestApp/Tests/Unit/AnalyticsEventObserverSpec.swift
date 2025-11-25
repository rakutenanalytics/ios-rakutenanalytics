import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class AnalyticsEventObserverSpec: QuickSpec {

    override class func spec() {
        describe("AnalyticsEventObserver") {
            let eventsToCache = [[PushEventPayloadKeys.eventNameKey: RAnalyticsEvent.Name.pushNotificationExternal,
                                  PushEventPayloadKeys.eventParametersKey: ["rid": "abcd1234"]]]
            let pushEventHandler: PushEventHandler = {
                let bundleMock = BundleMock()
                bundleMock.dictionary = [:]
                bundleMock.dictionary?[AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey] = "group.test"
                let sharedUserDefaults = UserDefaultsMock(suiteName: "group.test")
                sharedUserDefaults?.dictionary = [:]

                return PushEventHandler(sharedUserStorageHandler: sharedUserDefaults,
                                        appGroupId: bundleMock.appGroupId)
            }()
            let delegate = AnalyticsManagerMock()

            afterEach {
                delegate.processedEvents = [RAnalyticsEvent]()
            }

            context("When the observation has started") {
                let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)

                beforeEach {
                    observer.startObservation(delegate: delegate)
                }

                afterEach {
                    observer.stopObservation()
                }

                it("should process a cached event when a Darwin Notification is sent") {
                    pushEventHandler.save(darwinEvents: eventsToCache)
                    DarwinNotificationHelper.send(notificationName: AnalyticsDarwinNotification.eventsTrackingRequest)

                    expect(delegate.processedEvents).toEventuallyNot(beEmpty())
                    expect(delegate.processedEvents.count).to(equal(1))
                    expect(delegate.processedEvents.first?.name).to(equal(RAnalyticsEvent.Name.pushNotificationExternal))
                    expect(delegate.processedEvents.first?.parameters as? [String: AnyHashable]).to(equal(["rid": "abcd1234"]))
                }
            }

            context("When the observation has not started") {
                let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                observer.stopObservation()

                it("should not process a cached event when a Darwin Notification is sent") {
                    pushEventHandler.save(darwinEvents: eventsToCache)
                    DarwinNotificationHelper.send(notificationName: AnalyticsDarwinNotification.eventsTrackingRequest)

                    QuickSpec.performAsyncTest(timeForExecution: 1.0, timeout: 1.0) {
                        expect(delegate.processedEvents).to(beEmpty())
                    }
                }
            }

            describe("init") {
                it("should set delegate to nil") {
                    let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)

                    expect(observer.delegate).to(beNil())
                }
            }

            describe("startObservation") {
                it("should return true at first call") {
                    let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                    let result = observer.startObservation(delegate: delegate)

                    expect(result).to(beTrue())
                }

                it("should return false when the observation has already started") {
                    let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                    observer.startObservation(delegate: delegate)
                    let result = observer.startObservation(delegate: delegate)

                    expect(result).to(beFalse())
                }

                it("should set a non-nil delegate") {
                    let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                    observer.startObservation(delegate: delegate)

                    expect(observer.delegate).toNot(beNil())
                }

                context("The observation has stopped") {
                    it("should set a non-nil expected delegate") {
                        let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                        observer.startObservation(delegate: delegate)
                        observer.stopObservation()
                        observer.startObservation(delegate: delegate)

                        expect(observer.delegate).toNot(beNil())
                    }
                }
            }

            describe("stopObservation") {
                context("The observation has started") {
                    it("should return true") {
                        let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                        observer.startObservation(delegate: delegate)
                        let result = observer.stopObservation()

                        expect(result).to(beTrue())
                    }

                    it("should return false when the observation has already stopped") {
                        let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                        observer.startObservation(delegate: delegate)
                        observer.stopObservation()
                        let result = observer.stopObservation()

                        expect(result).to(beFalse())
                    }

                    it("should set delegate to nil") {
                        let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                        observer.startObservation(delegate: delegate)
                        observer.stopObservation()

                        expect(observer.delegate).to(beNil())
                    }
                }

                context("The observation has not started") {
                    it("should return false") {
                        let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                        let result = observer.stopObservation()

                        expect(result).to(beFalse())
                    }

                    it("should return false when the observation has already stopped") {
                        let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                        observer.stopObservation()
                        let result = observer.stopObservation()

                        expect(result).to(beFalse())
                    }

                    it("should set delegate to nil") {
                        let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                        observer.stopObservation()

                        expect(observer.delegate).to(beNil())
                    }
                }
            }
        }
    }
}

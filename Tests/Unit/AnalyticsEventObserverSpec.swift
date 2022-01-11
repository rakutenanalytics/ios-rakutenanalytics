import Quick
import Nimble
@testable import RAnalytics

final class AnalyticsEventObserverSpec: QuickSpec {

    override func spec() {
        describe("AnalyticsEventObserver") {
            let eventsToCache = [[PushEventPayloadKeys.eventNameKey: RAnalyticsEvent.Name.pushNotification,
                                  PushEventPayloadKeys.eventParametersKey: ["rid": "abcd1234"]]]
            var fileURL: URL!
            let fileManagerMock = FileManagerMock()
            let pushEventHandler: PushEventHandler = {
                let bundleMock = BundleMock()
                bundleMock.dictionary = [:]
                bundleMock.dictionary?[AppGroupUserDefaultsKeys.AppGroupIdentifierPlistKey] = "group.test"
                let sharedUserDefaults = UserDefaultsMock(suiteName: "group.test")
                sharedUserDefaults?.dictionary = [:]

                return PushEventHandler(sharedUserStorageHandler: sharedUserDefaults,
                                        appGroupId: bundleMock.appGroupId,
                                        fileManager: fileManagerMock,
                                        serializerType: JSONSerializationMock.self)
            }()
            let delegate = AnalyticsManagerMock()

            beforeEach {
                fileManagerMock.mockedContainerURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
                fileManagerMock.fileExists = true
                fileURL = fileManagerMock.mockedContainerURL?
                    .appendingPathComponent(PushEventHandlerKeys.OpenCountCachedEventsFileName)
                FileManager.default.createSafeFile(at: fileURL)
            }

            afterEach {
                fileManagerMock.mockedContainerURL = nil
                JSONSerializationMock.mockedJsonObject = [[String: Any]]()
                try? FileManager.default.removeItem(at: fileURL)
                delegate.eventIsProcessed = false
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
                    JSONSerializationMock.mockedJsonObject = eventsToCache
                    pushEventHandler.save(events: eventsToCache, completion: { _ in
                        DarwinNotificationHelper.send(notificationName: AnalyticsDarwinNotification.eventsTrackingRequest)
                    })

                    expect(delegate.eventIsProcessed).toEventually(beTrue())
                    expect(delegate.processedEvent?.name).to(equal(RAnalyticsEvent.Name.pushNotification))
                    expect(delegate.processedEvent?.parameters as? [String: AnyHashable]).to(equal(["rid": "abcd1234"]))
                }
            }

            context("When the observation has not started") {
                let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                observer.stopObservation()

                it("should not process a cached event when a Darwin Notification is sent") {
                    JSONSerializationMock.mockedJsonObject = eventsToCache
                    pushEventHandler.save(events: eventsToCache, completion: { _ in
                        DarwinNotificationHelper.send(notificationName: AnalyticsDarwinNotification.eventsTrackingRequest)
                    })

                    expect(delegate.eventIsProcessed).toAfterTimeout(beFalse())
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

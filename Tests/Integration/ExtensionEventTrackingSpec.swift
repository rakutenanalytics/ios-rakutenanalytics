import Quick
import Nimble
@testable import RAnalytics

final class ExtensionEventTrackingSpec: QuickSpec {

    override func spec() {
        describe("ExtensionEventTracking") {
            let pushEventHandler: PushEventHandler = {
                return PushEventHandler(sharedUserStorageHandler: UserDefaults(suiteName: "group.test"),
                                        appGroupId: "group.test",
                                        fileManager: FileManager.default,
                                        serializerType: JSONSerialization.self)
            }()

            let analyticsManager = AnalyticsManagerMock()

            let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)

            context("AnalyticsEventObserver starts the observation before any posted events") {
                beforeEach {
                    observer.startObservation(delegate: analyticsManager)
                }

                afterEach {
                    observer.stopObservation()
                }

                context("An event is posted") {
                    it("should process the event and clear the events cache") {
                        (0..<100).forEach { index in
                            AnalyticsEventPoster.post(name: RAnalyticsEvent.Name.pushNotification,
                                                      parameters: ["rid": "helloworld\(index)"],
                                                      pushEventHandler: pushEventHandler)

                            expect(analyticsManager.processedEvents).toEventuallyNot(beEmpty())
                            expect(analyticsManager.processedEvents.count).to(equal(1))
                            expect(analyticsManager.processedEvents.first?.name).to(equal(RAnalyticsEvent.Name.pushNotification))
                            expect(analyticsManager.processedEvents.first?.parameters as? [String: AnyHashable])
                                .to(equal(["rid": "helloworld\(index)"]))

                            var eventsCache: [[String: Any]]?
                            pushEventHandler.cachedEvents { result in
                                switch result {
                                case .success(let cache): eventsCache = cache
                                case .failure(_): ()
                                }
                            }
                            expect(eventsCache).toEventuallyNot(beNil())
                            expect(eventsCache).to(beEmpty())

                            analyticsManager.processedEvents = [RAnalyticsEvent]()
                        }
                    }
                }

                context("No event is posted") {
                    it("should not process any events") {
                        expect(analyticsManager.processedEvents).to(beEmpty())
                    }

                    it("should have an empty cache") {
                        var eventsCache: [[String: Any]]?
                        pushEventHandler.cachedEvents { result in
                            switch result {
                            case .success(let cache): eventsCache = cache
                            case .failure(_): ()
                            }
                        }
                        expect(eventsCache).toEventuallyNot(beNil())
                        expect(eventsCache).to(beEmpty())
                    }
                }
            }

            context("AnalyticsEventObserver starts the observation after any posted events") {
                afterEach {
                    observer.stopObservation()
                    analyticsManager.processedEvents = [RAnalyticsEvent]()
                }

                context("Many events are posted") {
                    it("should process the event and clear the events cache") {
                        (0..<100).forEach { index in
                            AnalyticsEventPoster.post(name: RAnalyticsEvent.Name.pushNotification,
                                                      parameters: ["rid": "helloworld\(index)"],
                                                      pushEventHandler: pushEventHandler)
                        }

                        observer.startObservation(delegate: analyticsManager)
                        observer.trackCachedEvents()

                        expect(analyticsManager.processedEvents).toEventuallyNot(beEmpty())
                        expect(analyticsManager.processedEvents.count).to(equal(100))

                        (0..<100).forEach { index in
                            expect(analyticsManager.processedEvents[index].name).to(equal(RAnalyticsEvent.Name.pushNotification))
                            expect(analyticsManager.processedEvents[index].parameters as? [String: AnyHashable])
                                .to(equal(["rid": "helloworld\(index)"]))
                        }

                        var eventsCache: [[String: Any]]?
                        pushEventHandler.cachedEvents { result in
                            switch result {
                            case .success(let cache): eventsCache = cache
                            case .failure(_): ()
                            }
                        }
                        expect(eventsCache).toEventuallyNot(beNil())
                        expect(eventsCache).to(beEmpty())
                    }
                }

                context("No event is posted") {
                    it("should not process any events") {
                        observer.startObservation(delegate: analyticsManager)
                        observer.trackCachedEvents()

                        expect(analyticsManager.processedEvents).to(beEmpty())
                    }

                    it("should have an empty cache") {
                        observer.startObservation(delegate: analyticsManager)
                        observer.trackCachedEvents()

                        var eventsCache: [[String: Any]]?
                        pushEventHandler.cachedEvents { result in
                            switch result {
                            case .success(let cache): eventsCache = cache
                            case .failure(_): ()
                            }
                        }
                        expect(eventsCache).toEventuallyNot(beNil())
                        expect(eventsCache).to(beEmpty())
                    }
                }
            }
        }
    }
}

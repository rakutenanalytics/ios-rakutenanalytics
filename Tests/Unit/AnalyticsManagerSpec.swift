import Quick
import Nimble
import AdSupport
import WebKit
import CoreLocation
@testable import RAnalytics

private final class SimpleContainerWithEmptyBundleMock: NSObject, SimpleDependenciesContainable {
    public let notificationHandler: NotificationObservable = NotificationCenter.default
    public let userStorageHandler: UserStorageHandleable = UserDefaults.standard
    public let adIdentifierManager: AdvertisementIdentifiable = ASIdentifierManager.shared()
    public let httpCookieStore: WKHTTPCookieStorable = WKWebsiteDataStore.default().httpCookieStore
    public let keychainHandler: KeychainHandleable = KeychainHandler()
    public let analyticsTracker = AnalyticsTracker()
    public let locationManager: LocationManageable = LocationManagerMock()
    public let bundle: EnvironmentBundle = BundleMock()
    public let tracker: Trackable = AnalyticsTracker()
}

final class AnalyticsManagerSpec: QuickSpec {
    override func spec() {
        describe("AnalyticsManager") {
            let dependenciesContainerWithEmptyBundle = SimpleContainerWithEmptyBundleMock()
            let dependenciesContainer = SimpleContainerMock()

            beforeEach {
                (dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled = false
                (dependenciesContainer.locationManager as? LocationManagerMock)?.stopUpdatingLocationIsCalled = false
            }

            describe("shared") {
                it("should be equal") {
                    expect(AnalyticsManager.shared() == AnalyticsManager.shared()).to(beTrue())
                }
            }

            describe("add") {
                it("should add the trackers as expected") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                    expect(analyticsManager.trackersLockableObject.get().count).to(equal(2))
                    analyticsManager.add(TrackerMock())
                    expect(analyticsManager.trackersLockableObject.get().count).to(equal(3))
                }
            }

            describe("set(endpointURL:)") {
                it("should set the expected endpoint to the added trackers") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                    analyticsManager.trackersLockableObject.get().forEach {
                        if let tracker = $0 as? Tracker {
                            expect(tracker.endpointURL).to(equal(Bundle.main.endpointAddress))
                        }
                    }

                    (0..<10).forEach { _ in
                        analyticsManager.add(TrackerMock())
                    }

                    analyticsManager.set(endpointURL: URL(string: "https://endpoint.com")!)
                    analyticsManager.trackersLockableObject.get().forEach {
                        if let tracker = $0 as? Tracker {
                            expect(tracker.endpointURL).to(equal(URL(string: "https://endpoint.com")!))
                        }
                    }

                    analyticsManager.set(endpointURL: nil)
                    analyticsManager.trackersLockableObject.get().forEach {
                        if let tracker = $0 as? Tracker {
                            expect(tracker.endpointURL).to(equal(Bundle.main.endpointAddress))
                        }
                    }
                }
            }

            describe("process") {
                it("should not process the event if its prefix is unknown") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let result = analyticsManager.process(RAnalyticsEvent(name: "foo", parameters: nil))
                    expect(result).to(beFalse())
                }

                it("should process the event if its prefix is known") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let result = analyticsManager.process(RAnalyticsEvent(name: "rat.foo", parameters: nil))
                    expect(result).to(beTrue())
                }
            }

            describe("shouldTrackPageView") {
                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: ["page_id": "TestPage"])
                let state: RAnalyticsState = {
                    let state = RAnalyticsState(sessionIdentifier: "CA7A88AB-82FE-40C9-A836-B1B3455DECAB", deviceIdentifier: "deviceId")
                    state.currentPage = UIViewController()
                    return state
                }()

                it("RAnalyticsRATTracker should process the page visit event when shouldTrackPageView is true") {
                    let shouldTrackPageView = AnalyticsManager.shared().shouldTrackPageView ?? false
                    AnalyticsManager.shared().shouldTrackPageView = true
                    expect(RAnalyticsRATTracker.shared().process(event: event, state: state)).to(beTrue())

                    AnalyticsManager.shared().shouldTrackPageView = shouldTrackPageView
                }

                it("RAnalyticsRATTracker should not process the page visit event when shouldTrackPageView is false") {
                    let shouldTrackPageView = AnalyticsManager.shared().shouldTrackPageView ?? false
                    AnalyticsManager.shared().shouldTrackPageView = false
                    expect(RAnalyticsRATTracker.shared().process(event: event, state: state)).to(beFalse())

                    AnalyticsManager.shared().shouldTrackPageView = shouldTrackPageView
                }
            }

            // Note: RAnalyticsSessionEndEventName is added to the RAnalyticsConfiguration.plist file for the key: RATDisabledEventsList
            describe("shouldTrackEventHandler") {
                context("shouldTrackEventHandler is nil") {
                    context("build time configuration file is missing") {
                        it("process event should return true") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainerWithEmptyBundle)
                            analyticsManager.shouldTrackEventHandler = nil

                            expect(analyticsManager.process(event)).to(beTrue())
                        }
                    }

                    context("build time configuration file exists") {
                        it("process event should return false if the event is disabled at build time") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionEnd, parameters: nil)
                            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                            analyticsManager.shouldTrackEventHandler = nil

                            expect(Bundle.main.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionEnd)).to(beTrue())
                            expect(analyticsManager.process(event)).to(beFalse())
                        }

                        it("process event should return true if the event is not disabled at build time") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                            analyticsManager.shouldTrackEventHandler = nil

                            expect(Bundle.main.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionEnd)).to(beTrue())
                            expect(analyticsManager.process(event)).to(beTrue())
                        }
                    }
                }

                context("shouldTrackEventHandler is not nil") {
                    context("build time configuration file is missing") {
                        it("process event should return false if the event is disabled at runtime") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainerWithEmptyBundle)
                            analyticsManager.shouldTrackEventHandler = { $0 != RAnalyticsEvent.Name.sessionStart }
                            expect(analyticsManager.process(event)).to(beFalse())
                        }

                        it("process event should return true if the event is enabled at runtime") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainerWithEmptyBundle)
                            analyticsManager.shouldTrackEventHandler = { $0 == RAnalyticsEvent.Name.sessionStart }
                            expect(analyticsManager.process(event)).to(beTrue())
                        }
                    }

                    context("build time configuration file exists") {
                        it("process event should return true if the event is disabled at build time and enabled at runtime") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionEnd, parameters: nil)
                            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                            analyticsManager.shouldTrackEventHandler = { $0 == RAnalyticsEvent.Name.sessionEnd }

                            expect(Bundle.main.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionEnd)).to(beTrue())
                            expect(analyticsManager.process(event)).to(beTrue())
                        }

                        it("process event should return true if the event is not disabled at build time and enabled at runtime") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                            analyticsManager.shouldTrackEventHandler = { $0 == RAnalyticsEvent.Name.sessionStart }

                            expect(Bundle.main.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionStart)).to(beFalse())
                            expect(analyticsManager.process(event)).to(beTrue())
                        }

                        it("process event should return false if the event is disabled at build time and disabled at runtime") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionEnd, parameters: nil)
                            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                            analyticsManager.shouldTrackEventHandler = { $0 != RAnalyticsEvent.Name.sessionEnd }

                            expect(Bundle.main.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionEnd)).to(beTrue())
                            expect(analyticsManager.process(event)).to(beFalse())
                        }

                        it("process event should return false if the event is not disabled at build time and disabled at runtime") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                            analyticsManager.shouldTrackEventHandler = { $0 != RAnalyticsEvent.Name.sessionStart }

                            expect(Bundle.main.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionStart)).to(beFalse())
                            expect(analyticsManager.process(event)).to(beFalse())
                        }
                    }
                }
            }

            describe("locationManager") {
                it("should start updating location at start") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    expect(analyticsManager.shouldTrackLastKnownLocation).to(beTrue())
                    expect((dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled).to(beTrue())
                }

                it("should stop updating location when shouldTrackLastKnownLocation is set to false") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

                    analyticsManager.shouldTrackLastKnownLocation = false
                    expect(analyticsManager.shouldTrackLastKnownLocation).to(beFalse())

                    expect((dependenciesContainer.locationManager as? LocationManagerMock)?.stopUpdatingLocationIsCalled).to(beTrue())
                    expect(analyticsManager.locationManagerIsUpdating).to(beFalse())
                }

                it("should not start updating location at start when shouldTrackLastKnownLocation is set to true") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

                    (dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled = false

                    analyticsManager.shouldTrackLastKnownLocation = true
                    expect(analyticsManager.shouldTrackLastKnownLocation).to(beTrue())

                    expect((dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled).to(beFalse())
                    expect(analyticsManager.locationManagerIsUpdating).to(beTrue())
                }

                it("should start updating location when it is stopped") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

                    analyticsManager.shouldTrackLastKnownLocation = false
                    expect(analyticsManager.shouldTrackLastKnownLocation).to(beFalse())

                    expect((dependenciesContainer.locationManager as? LocationManagerMock)?.stopUpdatingLocationIsCalled).to(beTrue())

                    analyticsManager.shouldTrackLastKnownLocation = true
                    expect(analyticsManager.shouldTrackLastKnownLocation).to(beTrue())

                    expect((dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled).to(beTrue())
                    expect(analyticsManager.locationManagerIsUpdating).to(beTrue())
                }

                it("should stop updating location when the application will resign active") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    expect(analyticsManager.shouldTrackLastKnownLocation).to(beTrue())
                    expect((dependenciesContainer.locationManager as? LocationManagerMock)?.stopUpdatingLocationIsCalled).to(beFalse())

                    NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil, userInfo: nil)
                    expect((dependenciesContainer.locationManager as? LocationManagerMock)?.stopUpdatingLocationIsCalled).toEventually(beTrue())
                }

                it("should start updating location when the application did become active") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    expect(analyticsManager.shouldTrackLastKnownLocation).to(beTrue())
                    expect((dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled).to(beTrue())

                    (dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled = false
                    (dependenciesContainer.locationManager as? LocationManagerMock)?.stopUpdatingLocationIsCalled = false

                    NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil, userInfo: nil)
                    expect((dependenciesContainer.locationManager as? LocationManagerMock)?.stopUpdatingLocationIsCalled).toEventually(beTrue())

                    NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
                    expect((dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled).toEventually(beTrue())
                }
            }
        }
    }
}

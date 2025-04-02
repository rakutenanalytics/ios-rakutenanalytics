// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import Quick
import Nimble
import AdSupport
import WebKit
import CoreLocation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

final class AnalyticsManagerSpec: QuickSpec {
    override class func spec() {
        describe("AnalyticsManager") {
            let bundleIdentifier = "jp.co.rakuten.app"
            let model = ReferralAppModel(bundleIdentifier: bundleIdentifier,
                                         accountIdentifier: 1,
                                         applicationIdentifier: 2,
                                         link: nil,
                                         component: nil,
                                         customParameters: [:])
            let parameters = "\(CpParameterKeys.Ref.accountIdentifier)=1&\(CpParameterKeys.Ref.applicationIdentifier)=2"
            let appURL = URL(string: "app://?\(parameters)")!
            let appURLWithRef = URL(string: "app://?\(PayloadParameterKeys.ref)=\(bundleIdentifier)&\(parameters)")!
            let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(PayloadParameterKeys.ref)=\(bundleIdentifier)&\(parameters)")!
            let universalLinkURLWithoutRef = URL(string: "https://www.rakuten.co.jp?\(parameters)")!

            let dependenciesContainerWithEmptyBundle = SimpleContainerMock()
            dependenciesContainerWithEmptyBundle.bundle = BundleMock()

            let dependenciesContainerWithRatIds = SimpleContainerMock()
            dependenciesContainerWithRatIds.bundle = BundleMock.create()

            let dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.locationManager = LocationManagerMock()

            let bundle = BundleMock.create()
            #if SWIFT_PACKAGE
            // SPM version: Set Bundle.module in order to get RAnalyticsConfiguration.plist from Unit module
            bundle.disabledEventsAtBuildTime = Bundle.module.disabledEventsAtBuildTime
            #else
            bundle.disabledEventsAtBuildTime = Bundle.main.disabledEventsAtBuildTime
            #endif
            dependenciesContainer.bundle = bundle

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
                    expect(analyticsManager.trackersLockableObject.get().count).to(equal(1))
                    analyticsManager.add(TrackerMock())
                    expect(analyticsManager.trackersLockableObject.get().count).to(equal(2))
                }
            }

            describe("isTrackingGeoLocation") {
                it("should return true when userStorageHandler has locationCollectionStatus as true") {
                    dependenciesContainer.userStorageHandler.set(value: true, forKey: UserDefaultsKeys.locationCollectionKey)
                    expect(AnalyticsManager.shared().isTrackingGeoLocation).to(beTrue())
                }

                it("should return false when userStorageHandler has locationCollectionStatus as false") {
                    dependenciesContainer.userStorageHandler.set(value: false, forKey: UserDefaultsKeys.locationCollectionKey)
                    expect(AnalyticsManager.shared().isTrackingGeoLocation).to(beFalse())
                }

                afterEach {
                    dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationCollectionKey)
                }
            }

            describe("deviceIdentifier") {
                context("When idfvUUID is nil") {
                    it("should return a non-empty string value") {
                        let deviceMock = DeviceMock()
                        deviceMock.idfvUUID = nil

                        let dependenciesContainer = SimpleContainerMock()
                        dependenciesContainer.deviceCapability = deviceMock

                        let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

                        expect(analyticsManager.deviceIdentifier).toNot(beEmpty())
                    }
                }

                context("When idfvUUID is an empty String") {
                    it("should return a non-empty string value") {
                        let deviceMock = DeviceMock()
                        deviceMock.idfvUUID = ""
                        
                        let dependenciesContainer = SimpleContainerMock()
                        dependenciesContainer.deviceCapability = deviceMock
                        
                        let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                        
                        expect(analyticsManager.deviceIdentifier).toNot(beEmpty())
                    }
                }

                context("When idfvUUID equals 00000000-0000-0000-0000-000000000000") {
                    it("should return a non-empty string value") {
                        let deviceMock = DeviceMock()
                        deviceMock.idfvUUID = "00000000-0000-0000-0000-000000000000"
                        
                        let dependenciesContainer = SimpleContainerMock()
                        dependenciesContainer.deviceCapability = deviceMock
                        
                        let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                        
                        expect(analyticsManager.deviceIdentifier).toNot(beEmpty())
                    }
                }

                context("When idfvUUID equals 123e4567-e89b-12d3-a456-426652340000") {
                    it("should return 428529fb27609e73dce768588ba6f1a1c1647451") {
                        let deviceMock = DeviceMock()
                        deviceMock.idfvUUID = "123e4567-e89b-12d3-a456-426652340000"
                        
                        let dependenciesContainer = SimpleContainerMock()
                        dependenciesContainer.deviceCapability = deviceMock
                        
                        let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                        
                        expect(analyticsManager.deviceIdentifier).to(equal("428529fb27609e73dce768588ba6f1a1c1647451"))
                    }
                }
            }

            describe("appToWebTracking") {
                let analyticsCookieName = "ra_uid"

                it("should clear cookies when disabled") {
                    let cookieStore = WKHTTPCookieStorageMock()
                    let containerMock = SimpleContainerMock()
                    containerMock.wkHttpCookieStore = cookieStore
                    let cookieInjector = RAnalyticsCookieInjector(dependenciesContainer: containerMock)
                    let analyticsManager = AnalyticsManager(dependenciesContainer: containerMock)
                    let deviceID = "cc851516e51366f4856d165c3ea117e592db6fba"

                    var hasCookie = true
                    let cookieStoreObserver = CookieStoreObserver {
                        cookieStore.allCookies { cookies in
                            hasCookie = !cookies.filter { $0.name == analyticsCookieName }.isEmpty
                        }
                    }
                    cookieStore.add(cookieStoreObserver)
                    cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) { _ in
                        analyticsManager.enableAppToWebTracking = false
                    }
                    expect(hasCookie).toEventually(beFalse(), timeout: .seconds(5))
                }

                it("should inject cookie when enabled") {
                    let cookieStore = WKHTTPCookieStorageMock()
                    let containerMock = SimpleContainerMock()
                    containerMock.wkHttpCookieStore = cookieStore
                    let analyticsManager = AnalyticsManager(dependenciesContainer: containerMock)

                    var hasCookie = false
                    let cookieStoreObserver = CookieStoreObserver {
                        cookieStore.allCookies { cookies in
                            hasCookie = !cookies.filter { $0.name == analyticsCookieName }.isEmpty
                        }
                    }
                    cookieStore.add(cookieStoreObserver)
                    analyticsManager.enableAppToWebTracking = true

                    expect(hasCookie).toEventually(beTrue(), timeout: .seconds(5))
                }
            }

            describe("webTrackingCookieDomain()") {
                context("When web tracking cookie domain is nil") {
                    it("should return a nil web tracking cookie domain") {
                        let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                        analyticsManager.setWebTrackingCookieDomain {
                            nil
                        }
                        expect(analyticsManager.webTrackingCookieDomain()).to(beNil())
                    }
                }
                
                context("When web tracking cookie domain is not nil") {
                    it("should return a non nil web tracking cookie domain") {
                        let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                        analyticsManager.setWebTrackingCookieDomain {
                            "mydomain.com"
                        }
                        expect(analyticsManager.webTrackingCookieDomain()).to(equal("mydomain.com"))
                    }
                }
            }
                
            describe("webTrackingCookieMultipleDomains()") {
                context("When web tracking multiple domains are nil") {
                    it("should return a nil web tracking cookie domains") {
                        let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                        analyticsManager.setWebTrackingCookieMultipleDomains(array: nil)
                        expect(analyticsManager.webTrackingCookieMultipleDomains()).to(beNil())
                    }
                }
                
                context("When web tracking cookie multiple domains is not nil") {
                    it("should return a non nil web tracking cookie multiple domains") {
                        let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                        let domains = ["mydomain.com", "example.com"]
                        analyticsManager.setWebTrackingCookieMultipleDomains(array: domains)
                        expect(analyticsManager.webTrackingCookieMultipleDomains()).to(equal(domains))
                    }
                }
            }

            describe("errorHandler") {
                let bundleMock = BundleMock()
                bundleMock.dictionary = [:]
                bundleMock.dictionary = [AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey: "group.app"]

                let nonFailableDependenciesContainer = SimpleContainerMock()
                nonFailableDependenciesContainer.bundle = bundleMock

                context("When an embedded error occurs") {
                    it("should raise the expected NSError") {
                        let analyticsManager = AnalyticsManager(dependenciesContainer: nonFailableDependenciesContainer)

                        var error: NSError?
                        analyticsManager.errorHandler = { anError in
                            error = anError
                        }

                        let raisedError = AnalyticsError.embeddedError(ErrorConstants.unknownError)
                        ErrorRaiser.raise(raisedError)

                        expect(error).toEventuallyNot(beNil(), timeout: .seconds(1))
                        expect(error).to(equal(raisedError.nsError()))
                    }
                }

                context("When a detailed error occurs") {
                    it("should raise the expected NSError") {
                        let analyticsManager = AnalyticsManager(dependenciesContainer: nonFailableDependenciesContainer)

                        var error: NSError?
                        analyticsManager.errorHandler = { anError in
                            error = anError
                        }

                        let raisedError = AnalyticsError.detailedError(domain: "domain",
                                                                       code: 123,
                                                                       description: "description",
                                                                       reason: "reason")
                        ErrorRaiser.raise(raisedError)

                        expect(error).toEventuallyNot(beNil())
                        expect(error).to(equal(raisedError.nsError()))
                    }
                }
            }

            describe("enableExtensionEventTracking") {
                it("should return true when it is set to true") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                    analyticsManager.enableExtensionEventTracking = true

                    expect(analyticsManager.enableExtensionEventTracking).to(beTrue())
                }

                it("should return false when it is set to false") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                    analyticsManager.enableExtensionEventTracking = false

                    expect(analyticsManager.enableExtensionEventTracking).to(beFalse())
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

            describe("trackReferralApp") {
                it("should not track the referral app when a URL Scheme has no source application") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let tracker = TrackerMock()

                    analyticsManager.add(tracker)
                    analyticsManager.trackReferralApp(url: appURL, sourceApplication: nil)

                    expect(tracker.state).to(beNil())
                }

                it("should not track the referral app when a Universal Link has no ref") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let tracker = TrackerMock()

                    analyticsManager.add(tracker)
                    analyticsManager.trackReferralApp(url: universalLinkURLWithoutRef, sourceApplication: nil)

                    expect(tracker.state).to(beNil())
                }

                it("should track the referral app when a URL Scheme is opened") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let tracker = TrackerMock()

                    analyticsManager.add(tracker)
                    analyticsManager.trackReferralApp(url: appURL, sourceApplication: bundleIdentifier)

                    expect(tracker.state).toNot(beNil())
                    expect(tracker.state?.referralTracking).to(equal(ReferralTrackingType.referralApp(model)))
                }

                it("should track the referral app when a Universal Link is opened") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let tracker = TrackerMock()

                    analyticsManager.add(tracker)
                    analyticsManager.trackReferralApp(url: universalLinkURL, sourceApplication: nil)

                    expect(tracker.state).toNot(beNil())
                    expect(tracker.state?.referralTracking).to(equal(ReferralTrackingType.referralApp(model)))
                }
            }

            describe("tryToTrackReferralApp(with:)") {
                it("should noy track the referral app when a Universal Link is nil") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let tracker = TrackerMock()

                    analyticsManager.add(tracker)
                    analyticsManager.tryToTrackReferralApp(with: nil)

                    expect(tracker.state).to(beNil())
                }

                it("should track the referral app when a Universal Link is opened") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let tracker = TrackerMock()

                    analyticsManager.add(tracker)
                    analyticsManager.tryToTrackReferralApp(with: universalLinkURL)

                    expect(tracker.state).toNot(beNil())
                    expect(tracker.state?.referralTracking).to(equal(ReferralTrackingType.referralApp(model)))
                }
            }

            describe("tryToTrackReferralApp(with:sourceApplication:)") {
                it("should not track the referral app when a URL Scheme is nil") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let tracker = TrackerMock()

                    analyticsManager.add(tracker)
                    analyticsManager.tryToTrackReferralApp(with: nil, sourceApplication: nil)

                    expect(tracker.state).to(beNil())
                }

                it("should track the referral app when a URL Scheme is opened") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let tracker = TrackerMock()

                    analyticsManager.add(tracker)
                    analyticsManager.tryToTrackReferralApp(with: appURLWithRef, sourceApplication: nil)

                    expect(tracker.state).toNot(beNil())
                    expect(tracker.state?.referralTracking).to(equal(ReferralTrackingType.referralApp(model)))
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
                    analyticsManager.remove(RAnalyticsRATTracker.shared())
                    analyticsManager.add(RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer))
                    let result = analyticsManager.process(RAnalyticsEvent(name: "rat.foo", parameters: nil))
                    expect(result).to(beTrue())
                }

                it("should process the event without referral tracking") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let tracker = TrackerMock()

                    analyticsManager.launchCollector.referralTracking = ReferralTrackingType.none

                    analyticsManager.add(tracker)
                    analyticsManager.process(RAnalyticsEvent(name: "custom", parameters: nil))

                    expect(tracker.state).toNot(beNil())
                    expect(tracker.state?.referralTracking).to(equal(ReferralTrackingType.none))
                }

                it("should process the event with a visited UIKit page") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let tracker = TrackerMock()
                    let referralTrackingType = ReferralTrackingType.page(currentPage: UIViewController())

                    analyticsManager.add(tracker)
                    analyticsManager.launchCollector.referralTracking = referralTrackingType
                    analyticsManager.process(RAnalyticsEvent(name: AnalyticsManager.Event.Name.pageVisit, parameters: nil))

                    expect(tracker.state).toNot(beNil())
                    expect(tracker.state?.referralTracking).to(equal(referralTrackingType))
                }

                it("should process the event with a visited SwiftUI page") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let tracker = TrackerMock()
                    let referralTrackingType = ReferralTrackingType.swiftuiPage(pageName: "MyView")

                    analyticsManager.add(tracker)
                    analyticsManager.launchCollector.referralTracking = referralTrackingType
                    analyticsManager.process(RAnalyticsEvent(name: AnalyticsManager.Event.Name.pageVisit, parameters: nil))

                    expect(tracker.state).toNot(beNil())
                    expect(tracker.state?.referralTracking).to(equal(referralTrackingType))
                }

                it("should process the event with a referral app tracking") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    let tracker = TrackerMock()
                    let model = ReferralAppModel(bundleIdentifier: "jp.co.rakuten.app",
                                                 accountIdentifier: 1,
                                                 applicationIdentifier: 2,
                                                 link: nil,
                                                 component: nil,
                                                 customParameters: nil)
                    let referralTrackingType = ReferralTrackingType.referralApp(model)

                    analyticsManager.add(tracker)
                    analyticsManager.launchCollector.referralTracking = referralTrackingType
                    analyticsManager.process(RAnalyticsEvent(name: AnalyticsManager.Event.Name.pageVisit, parameters: nil))

                    expect(tracker.state).toNot(beNil())
                    expect(tracker.state?.referralTracking).to(equal(referralTrackingType))
                }
            }

            // Note: RAnalyticsSessionEndEventName is added to the RAnalyticsConfiguration.plist file for the key: RATDisabledEventsList
            describe("shouldTrackEventHandler") {
                context("shouldTrackEventHandler is nil") {
                    context("build time configuration file is missing") {
                        context("The RAT identifiers are not set") {
                            it("process event should return false") {
                                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                                let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainerWithEmptyBundle)
                                analyticsManager.remove(RAnalyticsRATTracker.shared())
                                analyticsManager.add(RAnalyticsRATTracker(dependenciesContainer: dependenciesContainerWithEmptyBundle))
                                analyticsManager.shouldTrackEventHandler = nil

                                expect(analyticsManager.process(event)).to(beFalse())
                            }
                        }

                        context("The RAT identifiers are set") {
                            it("process event should return true") {
                                let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                                let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainerWithRatIds)
                                analyticsManager.remove(RAnalyticsRATTracker.shared())
                                analyticsManager.add(RAnalyticsRATTracker(dependenciesContainer: dependenciesContainerWithRatIds))
                                analyticsManager.shouldTrackEventHandler = nil

                                expect(analyticsManager.process(event)).to(beTrue())
                            }
                        }
                    }

                    context("build time configuration file exists") {
                        var analyticsManager: AnalyticsManager!

                        beforeEach {
                            analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                            analyticsManager.remove(RAnalyticsRATTracker.shared())
                            analyticsManager.add(RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer))
                        }

                        it("process event should return false if the event is disabled at build time") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionEnd, parameters: nil)

                            analyticsManager.shouldTrackEventHandler = nil

                            let disabledEventsAtBuildTime = dependenciesContainer.bundle.disabledEventsAtBuildTime

                            expect(disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionEnd)).to(beTrue())
                            expect(analyticsManager.process(event)).to(beFalse())
                        }

                        it("process event should return true if the event is not disabled at build time") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                            analyticsManager.shouldTrackEventHandler = nil

                            expect(dependenciesContainer.bundle.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionEnd)).to(beTrue())
                            expect(analyticsManager.process(event)).to(beTrue())
                        }
                    }
                }

                context("shouldTrackEventHandler is not nil") {
                    context("build time configuration file is missing") {
                        var analyticsManager: AnalyticsManager!

                        beforeEach {
                            analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainerWithRatIds)
                            analyticsManager.remove(RAnalyticsRATTracker.shared())
                            analyticsManager.add(RAnalyticsRATTracker(dependenciesContainer: dependenciesContainerWithRatIds))
                        }

                        it("process event should return false if the event is disabled at runtime") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                            analyticsManager.shouldTrackEventHandler = { $0 != RAnalyticsEvent.Name.sessionStart }
                            expect(analyticsManager.process(event)).to(beFalse())
                        }

                        it("process event should return true if the event is enabled at runtime") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                            analyticsManager.shouldTrackEventHandler = { $0 == RAnalyticsEvent.Name.sessionStart }
                            expect(analyticsManager.process(event)).to(beTrue())
                        }
                    }

                    context("build time configuration file exists") {
                        var analyticsManager: AnalyticsManager!

                        beforeEach {
                            analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                            analyticsManager.remove(RAnalyticsRATTracker.shared())
                            analyticsManager.add(RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer))
                        }

                        it("process event should return true if the event is disabled at build time and enabled at runtime") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionEnd, parameters: nil)
                            analyticsManager.shouldTrackEventHandler = { $0 == RAnalyticsEvent.Name.sessionEnd }

                            expect(dependenciesContainer.bundle.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionEnd)).to(beTrue())
                            expect(analyticsManager.process(event)).to(beTrue())
                        }

                        it("process event should return true if the event is not disabled at build time and enabled at runtime") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                            analyticsManager.shouldTrackEventHandler = { $0 == RAnalyticsEvent.Name.sessionStart }

                            expect(dependenciesContainer.bundle.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionStart)).to(beFalse())
                            expect(analyticsManager.process(event)).to(beTrue())
                        }

                        it("process event should return false if the event is disabled at build time and disabled at runtime") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionEnd, parameters: nil)
                            analyticsManager.shouldTrackEventHandler = { $0 != RAnalyticsEvent.Name.sessionEnd }

                            expect(dependenciesContainer.bundle.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionEnd)).to(beTrue())
                            expect(analyticsManager.process(event)).to(beFalse())
                        }

                        it("process event should return false if the event is not disabled at build time and disabled at runtime") {
                            let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                            analyticsManager.shouldTrackEventHandler = { $0 != RAnalyticsEvent.Name.sessionStart }

                            expect(dependenciesContainer.bundle.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionStart)).to(beFalse())
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

            describe("setMemberIdentifier()") {
                it("should set easyIdentifier to idsdkIdentifier") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    analyticsManager.setMemberIdentifier("idsdkIdentifier")

                    expect(analyticsManager.easyIdentifier).to(equal("idsdkIdentifier"))
                }
            }

            describe("removeMemberIdentifier()") {
                it("should set easyIdentifier to nil") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    analyticsManager.removeMemberIdentifier()

                    expect(analyticsManager.easyIdentifier).to(beNil())
                }
            }

            describe("setMemberError()") {
                it("should set easyIdentifier to nil") {
                    let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    analyticsManager.setMemberError(ErrorConstants.unknownError)

                    expect(analyticsManager.easyIdentifier).to(beNil())
                }
            }
        }
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable function_body_length

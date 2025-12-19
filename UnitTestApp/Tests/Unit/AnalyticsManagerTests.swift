// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import Testing
import AdSupport
import WebKit
import CoreLocation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("AnalyticsManager")
struct AnalyticsManagerTests {
    static let bundleIdentifier = "jp.co.rakuten.app"
    static let parameters = "\(CpParameterKeys.Ref.accountIdentifier)=1&\(CpParameterKeys.Ref.applicationIdentifier)=2"
    static let appURL = URL(string: "app://?\(parameters)")!
    static let appURLWithRef = URL(string: "app://?\(PayloadParameterKeys.ref)=\(bundleIdentifier)&\(parameters)")!
    static let universalLinkURL = URL(string: "https://www.rakuten.co.jp?\(PayloadParameterKeys.ref)=\(bundleIdentifier)&\(parameters)")!
    static let universalLinkURLWithoutRef = URL(string: "https://www.rakuten.co.jp?\(parameters)")!
    static let model = ReferralAppModel(
        bundleIdentifier: bundleIdentifier,
        accountIdentifier: 1,
        applicationIdentifier: 2,
        link: nil,
        component: nil,
        customParameters: [:])

    static var dependenciesContainerWithEmptyBundle: SimpleContainerMock {
        let container = SimpleContainerMock()
        container.bundle = BundleMock()
        return container
    }

    static var dependenciesContainerWithRatIds: SimpleContainerMock {
        let container = SimpleContainerMock()
        container.bundle = BundleMock.create()
        return container
    }

    static var dependenciesContainer: SimpleContainerMock {
        let container = SimpleContainerMock()
        container.locationManager = LocationManagerMock()
        let bundle = BundleMock.create()
        #if SWIFT_PACKAGE
        // SPM version: Set Bundle.module in order to get RAnalyticsConfiguration.plist from Unit module
        bundle.disabledEventsAtBuildTime = Bundle.module.disabledEventsAtBuildTime
        #else
        bundle.disabledEventsAtBuildTime = Bundle.main.disabledEventsAtBuildTime
        #endif
        container.bundle = bundle
        return container
    }

    var dependenciesContainer: SimpleContainerMock

    init() {
        dependenciesContainer = Self.dependenciesContainer
    }

    mutating func setUp() {
        (dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled = false
        (dependenciesContainer.locationManager as? LocationManagerMock)?.stopUpdatingLocationIsCalled = false
    }

    @Suite("shared")
    struct SharedTests {
        @Test("should be equal")
        func testIsEqual() {
            #expect(AnalyticsManager.shared() == AnalyticsManager.shared())
        }
    }

    @Suite("manual configuration")
    struct ManualConfigurationTests {
        @Suite("when manual initialization is enabled")
        struct WhenManualInitializationEnabledTests {
            @Test("should return singleton instance after configure() is called")
            @MainActor
            func testReturnsSingletonInstanceAfterConfigure() {
                let dependenciesContainer = SimpleContainerMock()
                let bundle = BundleMock()
                bundle.isManualInitializationEnabled = true
                dependenciesContainer.bundle = bundle

                AnalyticsManager.configure()

                // Verify instance can be created (non-optional, so creation is guaranteed)
                let _ = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            }
        }

        @Suite("configure()")
        struct ConfigureTests {
            @Test("should set AnalyticsManager.isConfigured to true")
            func testSetsIsConfiguredToTrue() {
                AnalyticsManager.isConfigured = false
                AnalyticsManager.configure()
                #expect(AnalyticsManager.isConfigured == true)
            }
        }
    }

    @Suite("add")
    struct AddTests {
        @Test("should add the trackers as expected")
        func testAddsTrackersAsExpected() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
            #expect(analyticsManager.trackersLockableObject.get().count == 1)
            analyticsManager.add(TrackerMock())
            #expect(analyticsManager.trackersLockableObject.get().count == 2)
        }
    }

    @Suite("isTrackingGeoLocation")
    struct IsTrackingGeoLocationTests {
        var dependenciesContainer: SimpleContainerMock

        init() {
            dependenciesContainer = AnalyticsManagerTests.dependenciesContainer
        }

        mutating func tearDown() {
            dependenciesContainer.userStorageHandler.removeObject(forKey: UserDefaultsKeys.locationCollectionKey)
        }

        @Test("should return true when userStorageHandler has locationCollectionStatus as true")
        mutating func testReturnsTrueWhenLocationCollectionStatusIsTrue() {
            defer { tearDown() }
            dependenciesContainer.userStorageHandler.set(value: true, forKey: UserDefaultsKeys.locationCollectionKey)
            #expect(AnalyticsManager.shared().isTrackingGeoLocation == true)
        }

        @Test("should return false when userStorageHandler has locationCollectionStatus as false")
        mutating func testReturnsFalseWhenLocationCollectionStatusIsFalse() {
            defer { tearDown() }
            dependenciesContainer.userStorageHandler.set(value: false, forKey: UserDefaultsKeys.locationCollectionKey)
            #expect(AnalyticsManager.shared().isTrackingGeoLocation == false)
        }
    }

    @Suite("deviceIdentifier")
    struct DeviceIdentifierTests {
        @Suite("When idfvUUID is nil")
        struct WhenIdfvUUIDIsNilTests {
            @Test("should return a non-empty string value")
            func testReturnsNonEmptyStringValue() {
                let deviceMock = DeviceMock()
                deviceMock.idfvUUID = nil

                let dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.deviceCapability = deviceMock

                let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                #expect(!analyticsManager.deviceIdentifier.isEmpty)
            }
        }

        @Suite("When idfvUUID is an empty String")
        struct WhenIdfvUUIDIsEmptyStringTests {
            @Test("should return a non-empty string value")
            func testReturnsNonEmptyStringValue() {
                let deviceMock = DeviceMock()
                deviceMock.idfvUUID = ""

                let dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.deviceCapability = deviceMock

                let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                #expect(!analyticsManager.deviceIdentifier.isEmpty)
            }
        }

        @Suite("When idfvUUID equals 00000000-0000-0000-0000-000000000000")
        struct WhenIdfvUUIDEqualsZeroTests {
            @Test("should return a non-empty string value")
            func testReturnsNonEmptyStringValue() {
                let deviceMock = DeviceMock()
                deviceMock.idfvUUID = "00000000-0000-0000-0000-000000000000"

                let dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.deviceCapability = deviceMock

                let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                #expect(!analyticsManager.deviceIdentifier.isEmpty)
            }
        }

        @Suite("When idfvUUID equals 123e4567-e89b-12d3-a456-426652340000")
        struct WhenIdfvUUIDEqualsSpecificValueTests {
            @Test("should return 428529fb27609e73dce768588ba6f1a1c1647451")
            func testReturnsExpectedHash() {
                let deviceMock = DeviceMock()
                deviceMock.idfvUUID = "123e4567-e89b-12d3-a456-426652340000"

                let dependenciesContainer = SimpleContainerMock()
                dependenciesContainer.deviceCapability = deviceMock

                let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                #expect(analyticsManager.deviceIdentifier == "428529fb27609e73dce768588ba6f1a1c1647451")
            }
        }
    }

    @Suite("appToWebTracking")
    struct AppToWebTrackingTests {
        static let analyticsCookieName = "ra_uid"

        @Test("should clear cookies when disabled")
        func testClearsCookiesWhenDisabled() async throws {
            let cookieStore = WKHTTPCookieStorageMock()
            let containerMock = SimpleContainerMock()
            containerMock.wkHttpCookieStore = cookieStore
            let cookieInjector = RAnalyticsCookieInjector(dependenciesContainer: containerMock)
            let analyticsManager = AnalyticsManager(dependenciesContainer: containerMock)
            let deviceID = "cc851516e51366f4856d165c3ea117e592db6fba"

            var hasCookie = true
            let cookieStoreObserver = CookieStoreObserver {
                cookieStore.allCookies { cookies in
                    hasCookie = !cookies.filter { $0.name == AppToWebTrackingTests.analyticsCookieName }.isEmpty
                }
            }
            cookieStore.add(cookieStoreObserver)
            cookieInjector.injectAppToWebTrackingCookie(domain: nil, deviceIdentifier: deviceID) { _ in
                analyticsManager.enableAppToWebTracking = false
            }
            try await TestingHelpers.eventuallyOnMain(timeout: 5.0) { !hasCookie }
        }

        @Test("should inject cookie when enabled")
        func testInjectsCookieWhenEnabled() async throws {
            let cookieStore = WKHTTPCookieStorageMock()
            let containerMock = SimpleContainerMock()
            containerMock.wkHttpCookieStore = cookieStore
            let analyticsManager = AnalyticsManager(dependenciesContainer: containerMock)

            var hasCookie = false
            let cookieStoreObserver = CookieStoreObserver {
                cookieStore.allCookies { cookies in
                    hasCookie = !cookies.filter { $0.name == AppToWebTrackingTests.analyticsCookieName }.isEmpty
                }
            }
            cookieStore.add(cookieStoreObserver)
            analyticsManager.enableAppToWebTracking = true

            try await TestingHelpers.eventuallyOnMain(timeout: 5.0) { hasCookie }
        }
    }

    @Suite("webTrackingCookieDomain()")
    struct WebTrackingCookieDomainTests {
        @Suite("When web tracking cookie domain is nil")
        struct WhenWebTrackingCookieDomainIsNilTests {
            @Test("should return a nil web tracking cookie domain")
            func testReturnsNilWebTrackingCookieDomain() {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.setWebTrackingCookieDomain {
                    nil
                }
                #expect(analyticsManager.webTrackingCookieDomain() == nil)
            }
        }

        @Suite("When web tracking cookie domain is not nil")
        struct WhenWebTrackingCookieDomainIsNotNilTests {
            @Test("should return a non nil web tracking cookie domain")
            func testReturnsNonNilWebTrackingCookieDomain() {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.setWebTrackingCookieDomain {
                    "mydomain.com"
                }
                #expect(analyticsManager.webTrackingCookieDomain() == "mydomain.com")
            }
        }
    }

    @Suite("webTrackingCookieMultipleDomains()")
    struct WebTrackingCookieMultipleDomainsTests {
        @Suite("When web tracking multiple domains are nil")
        struct WhenWebTrackingMultipleDomainsAreNilTests {
            @Test("should return a nil web tracking cookie domains")
            func testReturnsNilWebTrackingCookieDomains() {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                analyticsManager.setWebTrackingCookieMultipleDomains(array: nil)
                #expect(analyticsManager.webTrackingCookieMultipleDomains() == nil)
            }
        }

        @Suite("When web tracking cookie multiple domains is not nil")
        struct WhenWebTrackingCookieMultipleDomainsIsNotNilTests {
            @Test("should return a non nil web tracking cookie multiple domains")
            func testReturnsNonNilWebTrackingCookieMultipleDomains() {
                let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
                let domains = ["mydomain.com", "example.com"]
                analyticsManager.setWebTrackingCookieMultipleDomains(array: domains)
                #expect(analyticsManager.webTrackingCookieMultipleDomains() == domains)
            }
        }
    }

    @Suite("errorHandler")
    struct ErrorHandlerTests {
        static var bundleMock: BundleMock {
            let bundle = BundleMock()
            bundle.dictionary = [:]
            bundle.dictionary = [AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey: "group.app"]
            return bundle
        }

        static var nonFailableDependenciesContainer: SimpleContainerMock {
            let container = SimpleContainerMock()
            container.bundle = ErrorHandlerTests.bundleMock
            return container
        }

        @Suite("When an embedded error occurs")
        struct WhenEmbeddedErrorOccursTests {
            @Test("should raise the expected NSError")
            func testRaisesExpectedNSError() async throws {
                let analyticsManager = AnalyticsManager(dependenciesContainer: ErrorHandlerTests.nonFailableDependenciesContainer)

                var error: NSError?
                analyticsManager.errorHandler = { anError in
                    error = anError
                }

                let raisedError = AnalyticsError.embeddedError(ErrorConstants.unknownError)
                ErrorRaiser.raise(raisedError)

                try await TestingHelpers.eventuallyOnMain(timeout: 1.0) { error != nil }
                #expect(error == raisedError.nsError())
            }
        }

        @Suite("When a detailed error occurs")
        struct WhenDetailedErrorOccursTests {
            @Test("should raise the expected NSError")
            func testRaisesExpectedNSError() async throws {
                let analyticsManager = AnalyticsManager(dependenciesContainer: ErrorHandlerTests.nonFailableDependenciesContainer)

                var error: NSError?
                analyticsManager.errorHandler = { anError in
                    error = anError
                }
                
                let raisedError = AnalyticsError.detailedError(
                    domain: "domain",
                    code: 123,
                    description: "description",
                    reason: "reason")
                
                ErrorRaiser.raise(raisedError)

                try await TestingHelpers.eventuallyOnMain { error != nil }
                #expect(error == raisedError.nsError())
            }
        }
    }

    @Suite("enableExtensionEventTracking")
    struct EnableExtensionEventTrackingTests {
        @Test("should return true when it is set to true")
        func testReturnsTrueWhenSetToTrue() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
            analyticsManager.enableExtensionEventTracking = true
            #expect(analyticsManager.enableExtensionEventTracking == true)
        }

        @Test("should return false when it is set to false")
        func testReturnsFalseWhenSetToFalse() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
            analyticsManager.enableExtensionEventTracking = false
            #expect(analyticsManager.enableExtensionEventTracking == false)
        }
    }

    @Suite("set(endpointURL:)")
    struct SetEndpointURLTests {
        @Test("should set the expected endpoint to the added trackers")
        func testSetsExpectedEndpointToAddedTrackers() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())
            analyticsManager.trackersLockableObject.get().forEach {
                if let tracker = $0 as? Tracker {
                    #expect(tracker.endpointURL == Bundle.main.endpointAddress)
                }
            }

            (0..<10).forEach { _ in
                analyticsManager.add(TrackerMock())
            }

            analyticsManager.set(endpointURL: URL(string: "https://endpoint.com")!)
            analyticsManager.trackersLockableObject.get().forEach {
                if let tracker = $0 as? Tracker {
                    #expect(tracker.endpointURL == URL(string: "https://endpoint.com")!)
                }
            }

            analyticsManager.set(endpointURL: nil)
            analyticsManager.trackersLockableObject.get().forEach {
                if let tracker = $0 as? Tracker {
                    #expect(tracker.endpointURL == Bundle.main.endpointAddress)
                }
            }
        }
    }

    @Suite("trackReferralApp")
    struct TrackReferralAppTests {
        var dependenciesContainer: SimpleContainerMock

        init() {
            dependenciesContainer = AnalyticsManagerTests.dependenciesContainer
        }

        @Test("should not track the referral app when a URL Scheme has no source application")
        func testDoesNotTrackReferralAppWhenURLSchemeHasNoSourceApplication() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let tracker = TrackerMock()

            analyticsManager.add(tracker)
            analyticsManager.trackReferralApp(url: AnalyticsManagerTests.appURL, sourceApplication: nil)

            #expect(tracker.state == nil)
        }

        @Test("should not track the referral app when a Universal Link has no ref")
        func testDoesNotTrackReferralAppWhenUniversalLinkHasNoRef() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let tracker = TrackerMock()

            analyticsManager.add(tracker)
            analyticsManager.trackReferralApp(url: AnalyticsManagerTests.universalLinkURLWithoutRef, sourceApplication: nil)

            #expect(tracker.state == nil)
        }

        @Test("should track the referral app when a URL Scheme is opened")
        func testTracksReferralAppWhenURLSchemeIsOpened() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let tracker = TrackerMock()

            analyticsManager.add(tracker)
            analyticsManager.trackReferralApp(url: AnalyticsManagerTests.appURL, sourceApplication: AnalyticsManagerTests.bundleIdentifier)

            #expect(tracker.state != nil)
            #expect(tracker.state?.referralTracking == ReferralTrackingType.referralApp(AnalyticsManagerTests.model))
        }

        @Test("should track the referral app when a Universal Link is opened")
        func testTracksReferralAppWhenUniversalLinkIsOpened() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let tracker = TrackerMock()

            analyticsManager.add(tracker)
            analyticsManager.trackReferralApp(url: AnalyticsManagerTests.universalLinkURL, sourceApplication: nil)

            #expect(tracker.state != nil)
            #expect(tracker.state?.referralTracking == ReferralTrackingType.referralApp(AnalyticsManagerTests.model))
        }
    }

    @Suite("tryToTrackReferralApp(with:)")
    struct TryToTrackReferralAppWithTests {
        var dependenciesContainer: SimpleContainerMock

        init() {
            dependenciesContainer = AnalyticsManagerTests.dependenciesContainer
        }

        @Test("should noy track the referral app when a Universal Link is nil")
        func testDoesNotTrackReferralAppWhenUniversalLinkIsNil() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let tracker = TrackerMock()

            analyticsManager.add(tracker)
            analyticsManager.tryToTrackReferralApp(with: nil)

            #expect(tracker.state == nil)
        }

        @Test("should track the referral app when a Universal Link is opened")
        func testTracksReferralAppWhenUniversalLinkIsOpened() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let tracker = TrackerMock()

            analyticsManager.add(tracker)
            analyticsManager.tryToTrackReferralApp(with: AnalyticsManagerTests.universalLinkURL)

            #expect(tracker.state != nil)
            #expect(tracker.state?.referralTracking == ReferralTrackingType.referralApp(AnalyticsManagerTests.model))
        }
    }

    @Suite("tryToTrackReferralApp(with:sourceApplication:)")
    struct TryToTrackReferralAppWithSourceApplicationTests {
        var dependenciesContainer: SimpleContainerMock

        init() {
            dependenciesContainer = AnalyticsManagerTests.dependenciesContainer
        }

        @Test("should not track the referral app when a URL Scheme is nil")
        func testDoesNotTrackReferralAppWhenURLSchemeIsNil() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let tracker = TrackerMock()

            analyticsManager.add(tracker)
            analyticsManager.tryToTrackReferralApp(with: nil, sourceApplication: nil)

            #expect(tracker.state == nil)
        }

        @Test("should track the referral app when a URL Scheme is opened")
        func testTracksReferralAppWhenURLSchemeIsOpened() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let tracker = TrackerMock()

            analyticsManager.add(tracker)
            analyticsManager.tryToTrackReferralApp(with: AnalyticsManagerTests.appURLWithRef, sourceApplication: nil)

            #expect(tracker.state != nil)
            #expect(tracker.state?.referralTracking == ReferralTrackingType.referralApp(AnalyticsManagerTests.model))
        }
    }

    @Suite("process")
    struct ProcessTests {
        var dependenciesContainer: SimpleContainerMock

        init() {
            dependenciesContainer = AnalyticsManagerTests.dependenciesContainer
        }

        @Test("should not process the event if its prefix is unknown")
        func testDoesNotProcessEventIfPrefixIsUnknown() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let result = analyticsManager.process(RAnalyticsEvent(name: "foo", parameters: nil))
            #expect(result == false)
        }

        @Test("should process the event if its prefix is known")
        func testProcessesEventIfPrefixIsKnown() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            analyticsManager.remove(RAnalyticsRATTracker.shared())
            analyticsManager.add(RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer))
            let result = analyticsManager.process(RAnalyticsEvent(name: "rat.foo", parameters: nil))
            #expect(result == true)
        }

        @Suite("when manual initialization is enabled")
        struct WhenManualInitializationEnabledTests {
            @Test("should not process the event if SDK not initialized")
            func testDoesNotProcessEventIfSDKNotInitialized() {
                let dependenciesContainer = SimpleContainerMock()
                let bundle = BundleMock()
                bundle.isManualInitializationEnabled = true
                dependenciesContainer.bundle = bundle

                let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                analyticsManager.remove(RAnalyticsRATTracker.shared())
                analyticsManager.add(RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer))
                AnalyticsManager.isConfigured = false

                let result = analyticsManager.process(RAnalyticsEvent(name: "rat.foo", parameters: nil))
                #expect(result == false)
                AnalyticsManager.isConfigured = true
            }
        }

        @Test("should process the event without referral tracking")
        func testProcessesEventWithoutReferralTracking() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let tracker = TrackerMock()

            analyticsManager.launchCollector.referralTracking = ReferralTrackingType.none

            analyticsManager.add(tracker)
            analyticsManager.process(RAnalyticsEvent(name: "custom", parameters: nil))

            #expect(tracker.state != nil)
            #expect(tracker.state?.referralTracking == ReferralTrackingType.none)
        }

        @Test("should process the event with a visited UIKit page")
        @MainActor
        func testProcessesEventWithVisitedUIKitPage() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let tracker = TrackerMock()
            let referralTrackingType = ReferralTrackingType.page(currentPage: UIViewController())

            analyticsManager.add(tracker)
            analyticsManager.launchCollector.referralTracking = referralTrackingType
            analyticsManager.process(RAnalyticsEvent(name: AnalyticsManager.Event.Name.pageVisit, parameters: nil))

            #expect(tracker.state != nil)
            #expect(tracker.state?.referralTracking == referralTrackingType)
        }

        @Test("should process the event with a visited SwiftUI page")
        func testProcessesEventWithVisitedSwiftUIPage() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let tracker = TrackerMock()
            let referralTrackingType = ReferralTrackingType.swiftuiPage(pageName: "MyView")

            analyticsManager.add(tracker)
            analyticsManager.launchCollector.referralTracking = referralTrackingType
            analyticsManager.process(RAnalyticsEvent(name: AnalyticsManager.Event.Name.pageVisit, parameters: nil))

            #expect(tracker.state != nil)
            #expect(tracker.state?.referralTracking == referralTrackingType)
        }

        @Test("should process the event with a referral app tracking")
        func testProcessesEventWithReferralAppTracking() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let tracker = TrackerMock()
            let model = ReferralAppModel(
                bundleIdentifier: "jp.co.rakuten.app",
                accountIdentifier: 1,
                applicationIdentifier: 2,
                link: nil,
                component: nil,
                customParameters: nil)
            let referralTrackingType = ReferralTrackingType.referralApp(model)

            analyticsManager.add(tracker)
            analyticsManager.launchCollector.referralTracking = referralTrackingType
            analyticsManager.process(RAnalyticsEvent(name: AnalyticsManager.Event.Name.pageVisit, parameters: nil))

            #expect(tracker.state != nil)
            #expect(tracker.state?.referralTracking == referralTrackingType)
        }
    }

    // Note: RAnalyticsSessionEndEventName is added to the RAnalyticsConfiguration.plist file for the key: RATDisabledEventsList
    @Suite("shouldTrackEventHandler")
    struct ShouldTrackEventHandlerTests {
        @Suite("shouldTrackEventHandler is nil")
        struct ShouldTrackEventHandlerIsNilTests {
            @Suite("build time configuration file is missing")
            struct BuildTimeConfigurationFileIsMissingTests {
                @Suite("The RAT identifiers are not set")
                struct TheRATIdentifiersAreNotSetTests {
                    @Test("process event should return false")
                    func testProcessEventShouldReturnFalse() {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                        let analyticsManager = AnalyticsManager(dependenciesContainer: AnalyticsManagerTests.dependenciesContainerWithEmptyBundle)
                        analyticsManager.remove(RAnalyticsRATTracker.shared())
                        analyticsManager.add(RAnalyticsRATTracker(dependenciesContainer: AnalyticsManagerTests.dependenciesContainerWithEmptyBundle))
                        analyticsManager.shouldTrackEventHandler = nil
                        #expect(analyticsManager.process(event) == false)
                    }
                }

                @Suite("The RAT identifiers are set")
                struct TheRATIdentifiersAreSetTests {
                    @Test("process event should return true")
                    func testProcessEventShouldReturnTrue() {
                        let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                        let analyticsManager = AnalyticsManager(dependenciesContainer: AnalyticsManagerTests.dependenciesContainerWithRatIds)
                        analyticsManager.remove(RAnalyticsRATTracker.shared())
                        analyticsManager.add(RAnalyticsRATTracker(dependenciesContainer: AnalyticsManagerTests.dependenciesContainerWithRatIds))
                        analyticsManager.shouldTrackEventHandler = nil
                        #expect(analyticsManager.process(event) == true)
                    }
                }
            }

            @Suite("build time configuration file exists")
            struct BuildTimeConfigurationFileExistsTests {
                var dependenciesContainer: SimpleContainerMock
                var analyticsManager: AnalyticsManager!

                init() {
                    dependenciesContainer = AnalyticsManagerTests.dependenciesContainer
                }

                mutating func setUp() {
                    analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    analyticsManager.remove(RAnalyticsRATTracker.shared())
                    analyticsManager.add(RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer))
                }

                @Test("process event should return false if the event is disabled at build time")
                mutating func testProcessEventShouldReturnFalseIfEventIsDisabledAtBuildTime() {
                    setUp()
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionEnd, parameters: nil)

                    analyticsManager.shouldTrackEventHandler = nil

                    let disabledEventsAtBuildTime = dependenciesContainer.bundle.disabledEventsAtBuildTime

                    #expect(disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionEnd) == true)
                    #expect(analyticsManager.process(event) == false)
                }

                @Test("process event should return true if the event is not disabled at build time")
                mutating func testProcessEventShouldReturnTrueIfEventIsNotDisabledAtBuildTime() {
                    setUp()
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                    analyticsManager.shouldTrackEventHandler = nil

                    #expect(dependenciesContainer.bundle.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionEnd) == true)
                    #expect(analyticsManager.process(event) == true)
                }
            }
        }

        @Suite("shouldTrackEventHandler is not nil")
        struct ShouldTrackEventHandlerIsNotNilTests {
            @Suite("build time configuration file is missing")
            struct BuildTimeConfigurationFileIsMissingTests {
                var dependenciesContainer: SimpleContainerMock
                var analyticsManager: AnalyticsManager!

                init() {
                    dependenciesContainer = AnalyticsManagerTests.dependenciesContainerWithRatIds
                }

                mutating func setUp() {
                    analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    analyticsManager.remove(RAnalyticsRATTracker.shared())
                    analyticsManager.add(RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer))
                }

                @Test("process event should return false if the event is disabled at runtime")
                mutating func testProcessEventShouldReturnFalseIfEventIsDisabledAtRuntime() {
                    setUp()
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                    analyticsManager.shouldTrackEventHandler = { $0 != RAnalyticsEvent.Name.sessionStart }
                    #expect(analyticsManager.process(event) == false)
                }

                @Test("process event should return true if the event is enabled at runtime")
                mutating func testProcessEventShouldReturnTrueIfEventIsEnabledAtRuntime() {
                    setUp()
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                    analyticsManager.shouldTrackEventHandler = { $0 == RAnalyticsEvent.Name.sessionStart }
                    #expect(analyticsManager.process(event) == true)
                }
            }

            @Suite("build time configuration file exists")
            struct BuildTimeConfigurationFileExistsTests {
                var dependenciesContainer: SimpleContainerMock
                var analyticsManager: AnalyticsManager!

                init() {
                    dependenciesContainer = AnalyticsManagerTests.dependenciesContainer
                }

                mutating func setUp() {
                    analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
                    analyticsManager.remove(RAnalyticsRATTracker.shared())
                    analyticsManager.add(RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer))
                }

                @Test("process event should return true if the event is disabled at build time and enabled at runtime")
                mutating func testProcessEventShouldReturnTrueIfDisabledAtBuildTimeAndEnabledAtRuntime() {
                    setUp()
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionEnd, parameters: nil)
                    analyticsManager.shouldTrackEventHandler = { $0 == RAnalyticsEvent.Name.sessionEnd }

                    #expect(dependenciesContainer.bundle.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionEnd) == true)
                    #expect(analyticsManager.process(event) == true)
                }

                @Test("process event should return true if the event is not disabled at build time and enabled at runtime")
                mutating func testProcessEventShouldReturnTrueIfNotDisabledAtBuildTimeAndEnabledAtRuntime() {
                    setUp()
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                    analyticsManager.shouldTrackEventHandler = { $0 == RAnalyticsEvent.Name.sessionStart }

                    #expect(dependenciesContainer.bundle.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionStart) == false)
                    #expect(analyticsManager.process(event) == true)
                }

                @Test("process event should return false if the event is disabled at build time and disabled at runtime")
                mutating func testProcessEventShouldReturnFalseIfDisabledAtBuildTimeAndDisabledAtRuntime() {
                    setUp()
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionEnd, parameters: nil)
                    analyticsManager.shouldTrackEventHandler = { $0 != RAnalyticsEvent.Name.sessionEnd }

                    #expect(dependenciesContainer.bundle.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionEnd) == true)
                    #expect(analyticsManager.process(event) == false)
                }

                @Test("process event should return false if the event is not disabled at build time and disabled at runtime")
                mutating func testProcessEventShouldReturnFalseIfNotDisabledAtBuildTimeAndDisabledAtRuntime() {
                    setUp()
                    let event = RAnalyticsEvent(name: RAnalyticsEvent.Name.sessionStart, parameters: nil)
                    analyticsManager.shouldTrackEventHandler = { $0 != RAnalyticsEvent.Name.sessionStart }

                    #expect(dependenciesContainer.bundle.disabledEventsAtBuildTime?.contains(RAnalyticsEvent.Name.sessionStart) == false)
                    #expect(analyticsManager.process(event) == false)
                }
            }
        }
    }

    @Suite("locationManager")
    struct LocationManagerTests {
        var dependenciesContainer: SimpleContainerMock

        init() {
            dependenciesContainer = AnalyticsManagerTests.dependenciesContainer
        }

        mutating func setUp() {
            (dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled = false
            (dependenciesContainer.locationManager as? LocationManagerMock)?.stopUpdatingLocationIsCalled = false
        }

        @Test("should start updating location at start")
        mutating func testStartsUpdatingLocationAtStart() {
            setUp()
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            #expect(analyticsManager.shouldTrackLastKnownLocation == true)
            #expect((dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled == true)
        }

        @Test("should stop updating location when shouldTrackLastKnownLocation is set to false")
        mutating func testStopsUpdatingLocationWhenShouldTrackLastKnownLocationIsSetToFalse() {
            setUp()
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

            analyticsManager.shouldTrackLastKnownLocation = false
            #expect(analyticsManager.shouldTrackLastKnownLocation == false)

            #expect((dependenciesContainer.locationManager as? LocationManagerMock)?.stopUpdatingLocationIsCalled == true)
            #expect(analyticsManager.locationManagerIsUpdating == false)
        }

        @Test("should not start updating location at start when shouldTrackLastKnownLocation is set to true")
        mutating func testDoesNotStartUpdatingLocationAtStartWhenShouldTrackLastKnownLocationIsSetToTrue() {
            setUp()
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

            (dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled = false

            analyticsManager.shouldTrackLastKnownLocation = true
            #expect(analyticsManager.shouldTrackLastKnownLocation == true)

            #expect((dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled == false)
            #expect(analyticsManager.locationManagerIsUpdating == true)
        }

        @Test("should start updating location when it is stopped")
        mutating func testStartsUpdatingLocationWhenItIsStopped() {
            setUp()
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

            analyticsManager.shouldTrackLastKnownLocation = false
            #expect(analyticsManager.shouldTrackLastKnownLocation == false)

            #expect((dependenciesContainer.locationManager as? LocationManagerMock)?.stopUpdatingLocationIsCalled == true)

            analyticsManager.shouldTrackLastKnownLocation = true
            #expect(analyticsManager.shouldTrackLastKnownLocation == true)

            #expect((dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled == true)
            #expect(analyticsManager.locationManagerIsUpdating == true)
        }

        @Test("should stop updating location when the application will resign active")
        mutating func testStopsUpdatingLocationWhenApplicationWillResignActive() async throws {
            setUp()
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            #expect(analyticsManager.shouldTrackLastKnownLocation == true)
            #expect((dependenciesContainer.locationManager as? LocationManagerMock)?.stopUpdatingLocationIsCalled == false)

            NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil, userInfo: nil)
            let testLocationManager = dependenciesContainer.locationManager as? LocationManagerMock
            try await TestingHelpers.eventuallyOnMain { testLocationManager?.stopUpdatingLocationIsCalled == true }
        }

        @Test("should start updating location when the application did become active")
        mutating func testStartsUpdatingLocationWhenApplicationDidBecomeActive() async throws {
            setUp()
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            #expect(analyticsManager.shouldTrackLastKnownLocation == true)
            #expect((dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled == true)

            (dependenciesContainer.locationManager as? LocationManagerMock)?.startUpdatingLocationIsCalled = false
            (dependenciesContainer.locationManager as? LocationManagerMock)?.stopUpdatingLocationIsCalled = false

            NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil, userInfo: nil)
            let testLocationManager = dependenciesContainer.locationManager as? LocationManagerMock
            try await TestingHelpers.eventuallyOnMain { testLocationManager?.stopUpdatingLocationIsCalled == true }

            NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
            try await TestingHelpers.eventuallyOnMain { testLocationManager?.startUpdatingLocationIsCalled == true }
        }
    }

    @Suite("setMemberIdentifier()")
    struct SetMemberIdentifierTests {
        var dependenciesContainer: SimpleContainerMock

        init() {
            dependenciesContainer = AnalyticsManagerTests.dependenciesContainer
        }

        @Test("should set easyIdentifier to idsdkIdentifier")
        func testSetsEasyIdentifierToIdsdkIdentifier() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            analyticsManager.setMemberIdentifier("idsdkIdentifier")
            #expect(analyticsManager.easyIdentifier == "idsdkIdentifier")
        }

        @Test("should set easyIdentifier to idsdkIdentifier and delete stored userIdentifier")
        func testSetsEasyIdentifierToIdsdkIdentifierAndDeletesStoredUserIdentifier() {
            dependenciesContainer.userStorageHandler.set(
                value: "testUserIdentifier",
                forKey: RAnalyticsExternalCollector.Constants.userIdentifierKey
            )
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            analyticsManager.setMemberIdentifier("idsdkIdentifier")

            #expect(analyticsManager.easyIdentifier == "idsdkIdentifier")
            #expect(dependenciesContainer.userStorageHandler.string(forKey: RAnalyticsExternalCollector.Constants.userIdentifierKey) == nil)
        }
    }

    @Suite("removeMemberIdentifier()")
    struct RemoveMemberIdentifierTests {
        var dependenciesContainer: SimpleContainerMock

        init() {
            dependenciesContainer = AnalyticsManagerTests.dependenciesContainer
        }

        @Test("should set easyIdentifier to nil")
        func testSetsEasyIdentifierToNil() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            analyticsManager.removeMemberIdentifier()
            #expect(analyticsManager.easyIdentifier == nil)
        }
    }

    @Suite("setMemberError()")
    struct SetMemberErrorTests {
        var dependenciesContainer: SimpleContainerMock

        init() {
            dependenciesContainer = AnalyticsManagerTests.dependenciesContainer
        }

        @Test("should set easyIdentifier to nil")
        func testSetsEasyIdentifierToNil() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            analyticsManager.setMemberError(ErrorConstants.unknownError)
            #expect(analyticsManager.easyIdentifier == nil)
        }
    }

    @Suite("generatePageId")
    struct GeneratePageIdTests {
        var dependenciesContainer: SimpleContainerMock

        init() {
            dependenciesContainer = AnalyticsManagerTests.dependenciesContainer
        }

        @Test("should generate a page ID with correct format")
        func testGeneratesPageIDWithCorrectFormat() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

            let pageId = analyticsManager.generatePageId()

            #expect(pageId.contains("_"))
            let components = pageId.components(separatedBy: "_")
            #expect(components.count == 2)
            #expect(!components[0].isEmpty)

            let timestamp = components[1]
            #expect(Double(timestamp) != nil)
            #expect(Double(timestamp)! > 0)
        }

        @Test("should generate different page IDs when called multiple times")
        func testGeneratesDifferentPageIDsWhenCalledMultipleTimes() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)

            let firstPageId = analyticsManager.generatePageId()
            Thread.sleep(forTimeInterval: 0.001)
            let secondPageId = analyticsManager.generatePageId()

            #expect(firstPageId != secondPageId)
        }

        @Test("should include device identifier in generated page ID")
        func testIncludesDeviceIdentifierInGeneratedPageID() {
            let analyticsManager = AnalyticsManager(dependenciesContainer: dependenciesContainer)
            let expectedDeviceId = AnalyticsManager.shared().deviceIdentifier

            let pageId = analyticsManager.generatePageId()
            let components = pageId.components(separatedBy: "_")

            #expect(components[0] == expectedDeviceId)
        }
    }
}

@Suite("Carrier Names API")
struct CarrierNamesAPITests {
    let analyticsManager = AnalyticsManager.shared()

    mutating func tearDown() {
        analyticsManager.clearCarrierNames()
    }

    @Suite("setCarrierNames and getCarrierNames")
    struct SetCarrierNamesAndGetCarrierNamesTests {
        let analyticsManager = AnalyticsManager.shared()

        mutating func tearDown() {
            analyticsManager.clearCarrierNames()
        }

        @Test("should set and get primary carrier name only")
        mutating func testSetsAndGetsPrimaryCarrierNameOnly() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "Rakuten Mobile")

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == "Rakuten Mobile")
            #expect(carrierNames.secondary == nil)
        }

        @Test("should set and get secondary carrier name only")
        mutating func testSetsAndGetsSecondaryCarrierNameOnly() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: nil, secondary: "NTT Docomo")

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == nil)
            #expect(carrierNames.secondary == "NTT Docomo")
        }

        @Test("should set and get both carrier names")
        mutating func testSetsAndGetsBothCarrierNames() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "SoftBank", secondary: "au")

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == "SoftBank")
            #expect(carrierNames.secondary == "au")
        }

        @Test("should handle empty strings")
        mutating func testHandlesEmptyStrings() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "", secondary: "")

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == "")
            #expect(carrierNames.secondary == "")
        }

        @Test("should update existing carrier names")
        mutating func testUpdatesExistingCarrierNames() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "Initial Primary", secondary: "Initial Secondary")
            analyticsManager.setCarrierNames(primary: "Updated Primary", secondary: "Updated Secondary")

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == "Updated Primary")
            #expect(carrierNames.secondary == "Updated Secondary")
        }
    }

    @Suite("clearCarrierNames")
    struct ClearCarrierNamesTests {
        let analyticsManager = AnalyticsManager.shared()

        mutating func tearDown() {
            analyticsManager.clearCarrierNames()
        }

        @Test("should clear both carrier names when both were set")
        mutating func testClearsBothCarrierNamesWhenBothWereSet() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "Test Primary", secondary: "Test Secondary")

            var carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == "Test Primary")
            #expect(carrierNames.secondary == "Test Secondary")

            analyticsManager.clearCarrierNames()

            carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == nil)
            #expect(carrierNames.secondary == nil)
        }

        @Test("should clear carrier names when only primary was set")
        mutating func testClearsCarrierNamesWhenOnlyPrimaryWasSet() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "Only Primary")

            analyticsManager.clearCarrierNames()

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == nil)
            #expect(carrierNames.secondary == nil)
        }

        @Test("should clear carrier names when only secondary was set")
        mutating func testClearsCarrierNamesWhenOnlySecondaryWasSet() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: nil, secondary: "Only Secondary")

            analyticsManager.clearCarrierNames()

            let carrierNames = analyticsManager.getCarrierNames()
            #expect(carrierNames.primary == nil)
            #expect(carrierNames.secondary == nil)
        }

        @Test("should be safe to call when no carrier names are set")
        mutating func testIsSafeToCallWhenNoCarrierNamesAreSet() {
            defer { tearDown() }
            let initialCarrierNames = analyticsManager.getCarrierNames()
            #expect(initialCarrierNames.primary == nil)
            #expect(initialCarrierNames.secondary == nil)

            analyticsManager.clearCarrierNames()

            let finalCarrierNames = analyticsManager.getCarrierNames()
            #expect(finalCarrierNames.primary == nil)
            #expect(finalCarrierNames.secondary == nil)
        }
    }

    @Suite("API integration")
    struct APIIntegrationTests {
        let analyticsManager = AnalyticsManager.shared()

        mutating func tearDown() {
            analyticsManager.clearCarrierNames()
        }

        @Test("should work with method chaining pattern")
        mutating func testWorksWithMethodChainingPattern() {
            defer { tearDown() }
            analyticsManager.setCarrierNames(primary: "Chain Primary", secondary: "Chain Secondary")
            let carrierNames1 = analyticsManager.getCarrierNames()

            analyticsManager.clearCarrierNames()
            let carrierNames2 = analyticsManager.getCarrierNames()

            analyticsManager.setCarrierNames(primary: "New Primary")
            let carrierNames3 = analyticsManager.getCarrierNames()

            #expect(carrierNames1.primary == "Chain Primary")
            #expect(carrierNames1.secondary == "Chain Secondary")

            #expect(carrierNames2.primary == nil)
            #expect(carrierNames2.secondary == nil)

            #expect(carrierNames3.primary == "New Primary")
            #expect(carrierNames3.secondary == nil)
        }
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable function_body_length

import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("AnalyticsEventObserver")
struct AnalyticsEventObserverTests {
    static let eventsToCache = [[PushEventPayloadKeys.eventNameKey: RAnalyticsEvent.Name.pushNotificationExternal,
                                 PushEventPayloadKeys.eventParametersKey: ["rid": "abcd1234"]]]
    
    static var pushEventHandler: PushEventHandler {
        let bundleMock = BundleMock()
        bundleMock.dictionary = [:]
        bundleMock.dictionary?[AppGroupUserDefaultsKeys.appGroupIdentifierPlistKey] = "group.test"
        let sharedUserDefaults = UserDefaultsMock(suiteName: "group.test")
        sharedUserDefaults?.dictionary = [:]

        return PushEventHandler(sharedUserStorageHandler: sharedUserDefaults, appGroupId: bundleMock.appGroupId)
    }
    
    var delegate: AnalyticsManagerMock
    
    init() {
        delegate = AnalyticsManagerMock()
    }
    
    func resetDelegate() {
        delegate.processedEvents = [RAnalyticsEvent]()
    }

    @Suite("When the observation has started")
    struct WhenObservationHasStartedTests {
        let pushEventHandler = AnalyticsEventObserverTests.pushEventHandler
        var delegate: AnalyticsManagerMock
        var observer: AnalyticsEventObserver
        
        init() {
            delegate = AnalyticsManagerMock()
            observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
        }
        
        mutating func setUp() {
            observer.startObservation(delegate: delegate)
        }
        
        mutating func tearDown() {
            observer.stopObservation()
            delegate.processedEvents = [RAnalyticsEvent]()
        }

        @Test("should process a cached event when a Darwin Notification is sent")
        mutating func testProcessesCachedEventWhenDarwinNotificationSent() async throws {
            setUp()
            defer { tearDown() }
            
            pushEventHandler.save(darwinEvents: AnalyticsEventObserverTests.eventsToCache)
            DarwinNotificationHelper.send(notificationName: AnalyticsDarwinNotification.eventsTrackingRequest)

            let testDelegate = delegate
            try await TestingHelpers.eventuallyOnMain { !testDelegate.processedEvents.isEmpty }
            #expect(testDelegate.processedEvents.count == 1)
            #expect(testDelegate.processedEvents.first?.name == RAnalyticsEvent.Name.pushNotificationExternal)
            #expect(testDelegate.processedEvents.first?.parameters as? [String: AnyHashable] == ["rid": "abcd1234"])
        }
    }

    @Suite("When the observation has not started")
    struct WhenObservationHasNotStartedTests {
        let pushEventHandler = AnalyticsEventObserverTests.pushEventHandler
        var delegate: AnalyticsManagerMock
        var observer: AnalyticsEventObserver
        
        init() {
            delegate = AnalyticsManagerMock()
            observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
            observer.stopObservation()
        }
        
        mutating func tearDown() {
            delegate.processedEvents = [RAnalyticsEvent]()
        }

        @Test("should not process a cached event when a Darwin Notification is sent")
        mutating func testDoesNotProcessCachedEventWhenDarwinNotificationSent() async throws {
            defer { tearDown() }
            
            pushEventHandler.save(darwinEvents: AnalyticsEventObserverTests.eventsToCache)
            DarwinNotificationHelper.send(notificationName: AnalyticsDarwinNotification.eventsTrackingRequest)

            let testDelegate = delegate
            try await TestingHelpers.performAsyncTestOnMain(timeForExecution: 1.0, timeout: 1.0) {
                #expect(testDelegate.processedEvents.isEmpty)
            }
        }
    }

    @Suite("init")
    struct InitTests {
        let pushEventHandler = AnalyticsEventObserverTests.pushEventHandler

        @Test("should set delegate to nil")
        func testSetsDelegateToNil() {
            let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
            #expect(observer.delegate == nil)
        }
    }

    @Suite("startObservation")
    struct StartObservationTests {
        let pushEventHandler = AnalyticsEventObserverTests.pushEventHandler
        var delegate: AnalyticsManagerMock
        
        init() {
            delegate = AnalyticsManagerMock()
        }
        
        mutating func tearDown() {
            delegate.processedEvents = [RAnalyticsEvent]()
        }

        @Test("should return true at first call")
        mutating func testReturnsTrueAtFirstCall() {
            defer { tearDown() }
            let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
            let result = observer.startObservation(delegate: delegate)
            #expect(result == true)
        }

        @Test("should return false when the observation has already started")
        mutating func testReturnsFalseWhenAlreadyStarted() {
            defer { tearDown() }
            let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
            observer.startObservation(delegate: delegate)
            let result = observer.startObservation(delegate: delegate)
            #expect(result == false)
        }

        @Test("should set a non-nil delegate")
        mutating func testSetsNonNilDelegate() {
            defer { tearDown() }
            let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
            observer.startObservation(delegate: delegate)
            #expect(observer.delegate != nil)
        }

        @Suite("The observation has stopped")
        struct ObservationHasStoppedTests {
            let pushEventHandler = AnalyticsEventObserverTests.pushEventHandler
            var delegate: AnalyticsManagerMock
            
            init() {
                delegate = AnalyticsManagerMock()
            }
            
            mutating func tearDown() {
                delegate.processedEvents = [RAnalyticsEvent]()
            }

            @Test("should set a non-nil expected delegate")
            mutating func testSetsNonNilDelegateAfterStopped() {
                defer { tearDown() }
                let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                observer.startObservation(delegate: delegate)
                observer.stopObservation()
                observer.startObservation(delegate: delegate)
                #expect(observer.delegate != nil)
            }
        }
    }

    @Suite("stopObservation")
    struct StopObservationTests {
        let pushEventHandler = AnalyticsEventObserverTests.pushEventHandler
        var delegate: AnalyticsManagerMock
        
        init() {
            delegate = AnalyticsManagerMock()
        }
        
        mutating func tearDown() {
            delegate.processedEvents = [RAnalyticsEvent]()
        }

        @Suite("The observation has started")
        struct ObservationHasStartedTests {
            let pushEventHandler = AnalyticsEventObserverTests.pushEventHandler
            var delegate: AnalyticsManagerMock
            
            init() {
                delegate = AnalyticsManagerMock()
            }
            
            mutating func tearDown() {
                delegate.processedEvents = [RAnalyticsEvent]()
            }

            @Test("should return true")
            mutating func testReturnsTrue() {
                defer { tearDown() }
                let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                observer.startObservation(delegate: delegate)
                let result = observer.stopObservation()
                #expect(result == true)
            }

            @Test("should return false when the observation has already stopped")
            mutating func testReturnsFalseWhenAlreadyStopped() {
                defer { tearDown() }
                let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                observer.startObservation(delegate: delegate)
                observer.stopObservation()
                let result = observer.stopObservation()
                #expect(result == false)
            }

            @Test("should set delegate to nil")
            mutating func testSetsDelegateToNil() {
                defer { tearDown() }
                let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                observer.startObservation(delegate: delegate)
                observer.stopObservation()
                #expect(observer.delegate == nil)
            }
        }

        @Suite("The observation has not started")
        struct ObservationHasNotStartedTests {
            let pushEventHandler = AnalyticsEventObserverTests.pushEventHandler
            var delegate: AnalyticsManagerMock
            
            init() {
                delegate = AnalyticsManagerMock()
            }
            
            mutating func tearDown() {
                delegate.processedEvents = [RAnalyticsEvent]()
            }

            @Test("should return false")
            mutating func testReturnsFalse() {
                defer { tearDown() }
                let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                let result = observer.stopObservation()
                #expect(result == false)
            }

            @Test("should return false when the observation has already stopped")
            mutating func testReturnsFalseWhenAlreadyStopped() {
                defer { tearDown() }
                let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                observer.stopObservation()
                let result = observer.stopObservation()
                #expect(result == false)
            }

            @Test("should set delegate to nil")
            mutating func testSetsDelegateToNil() {
                defer { tearDown() }
                let observer = AnalyticsEventObserver(pushEventHandler: pushEventHandler)
                observer.stopObservation()
                #expect(observer.delegate == nil)
            }
        }
    }
}

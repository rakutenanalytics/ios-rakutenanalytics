import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsRATTrackerInitTests

@Suite("RAnalyticsRATTracker")
struct RAnalyticsRATTrackerInitTests {
    @Suite("init")
    struct InitTests {
        @Test("should not be nil")
        func testShouldNotBeNil() {
            let ratTracker = RAnalyticsRATTracker(dependenciesContainer: SimpleContainerMock())
            _ = ratTracker
        }
    }
    
    @Suite("markAsConfigured")
    struct MarkAsConfiguredTests {
        @Test("should set isRATConfigured to true when called")
        func testSetsIsRATConfiguredToTrueWhenCalled() {
            let dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.bundle = BundleMock.create()
            let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
            #expect(ratTracker.isRATConfigured == false)

            ratTracker.markAsConfigured()

            #expect(ratTracker.isRATConfigured == true, "markAsConfigured should set isRATConfigured to true")
        }
    }

    @Suite("shared")
    struct SharedTests {
        @Test("should not be nil")
        func testShouldNotBeNil() {
            _ = RAnalyticsRATTracker.shared()
        }
        
        @Test("should be a singleton")
        func testShouldBeSingleton() {
            #expect(RAnalyticsRATTracker.shared() === RAnalyticsRATTracker.shared())
        }
    }
    
    @Suite("accountIdentifier")
    struct AccountIdentifierTests {
        @Test("should equal to the given account identifier")
        func testShouldEqualGivenAccountIdentifier() {
            let bundle = BundleMock()
            bundle.endpointAddress = URL(string: "https://endpoint.co.jp/")!
            bundle.accountIdentifier = 10
            let dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.bundle = bundle
            
            let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
            #expect(ratTracker.accountIdentifier == 10)
        }
        
        @Test("should equal to 0 when the plist key is not set")
        func testShouldEqualZeroWhenPlistKeyNotSet() {
            #expect(RAnalyticsRATTracker.shared().accountIdentifier == 0)
        }
    }
    
    @Suite("applicationIdentifier")
    struct ApplicationIdentifierTests {
        @Test("should equal to the given application identifier")
        func testShouldEqualGivenApplicationIdentifier() {
            let bundle = BundleMock()
            bundle.endpointAddress = URL(string: "https://endpoint.co.jp/")!
            bundle.applicationIdentifier = 10
            let dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.bundle = bundle
            
            let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
            #expect(ratTracker.applicationIdentifier == 10)
        }
        
        @Test("should equal to 1 when the plist key is not set")
        func testShouldEqualOneWhenPlistKeyNotSet() {
            #expect(RAnalyticsRATTracker.shared().applicationIdentifier == 1)
        }
    }
    
    @Suite("event(withEventType:parameters:)")
    struct EventWithEventTypeParametersTests {
        @Test("should not return nil")
        func testShouldNotReturnNil() {
            let params: [String: Any] = [PayloadParameterKeys.acc: 555]
            let bundle = BundleMock()
            bundle.endpointAddress = URL(string: "https://endpoint.co.jp/")!
            let dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.bundle = bundle
            let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
            let event = ratTracker.event(withEventType: "login", parameters: params)
            #expect(event.name == "rat.login")
            #expect(event.parameters[PayloadParameterKeys.acc] as? Int == params[PayloadParameterKeys.acc] as? Int)
        }
    }
    
    @Suite("endpointURL")
    struct EndpointURLTests {
        @Test("should set the expected endpoint to its sender and rpCookieFetcher")
        func testShouldSetExpectedEndpointToSenderAndRpCookieFetcher() {
            let bundle = BundleMock()
            bundle.endpointAddress = URL(string: "https://endpoint.co.jp/")!
            let dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.bundle = bundle
            let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
            let originalEndpointURL = ratTracker.endpointURL
            let sender = ratTracker.perform(Selector((("sender"))))?.takeUnretainedValue() as? RAnalyticsSender
            let rpCookieFetcher = ratTracker.perform(Selector((("rpCookieFetcher"))))?.takeUnretainedValue() as? RAnalyticsRpCookieFetcher
            
            let endpointURL1 = URL(string: "https://endpoint1.com")!
            ratTracker.endpointURL = endpointURL1
            #expect(sender?.endpointURL == endpointURL1)
            #expect(rpCookieFetcher?.endpointURL == endpointURL1)
            #expect(ratTracker.endpointURL == endpointURL1)
            
            let endpoint2 = URL(string: "https://endpoint2.com")!
            ratTracker.endpointURL = endpoint2
            #expect(sender?.endpointURL == endpoint2)
            #expect(rpCookieFetcher?.endpointURL == endpoint2)
            #expect(ratTracker.endpointURL == endpoint2)
            
            ratTracker.endpointURL = originalEndpointURL
        }
    }
    
    @Suite("batchingDelay")
    struct BatchingDelayTests {
        @Test("should be set to 1.0 by default")
        func testShouldBeSetToOneByDefault() {
            let bundle = BundleMock()
            bundle.endpointAddress = URL(string: "https://endpoint.co.jp/")!
            let dependenciesContainer = SimpleContainerMock()
            dependenciesContainer.bundle = bundle
            let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
            #expect(ratTracker.batchingDelay() == 1.0)
        }
    }
}

import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

// MARK: - RAnalyticsRATTrackerInitSpec

class RAnalyticsRATTrackerInitSpec: QuickSpec {
    override class func spec() {
        describe("RAnalyticsRATTracker") {
            let dependenciesContainer = SimpleContainerMock()
            let bundle = BundleMock()
            bundle.endpointAddress = URL(string: "https://endpoint.co.jp/")!
            dependenciesContainer.bundle = bundle

            describe("init") {
                it("should not be nil") {
                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: SimpleContainerMock())
                    expect(ratTracker).toNot(beNil())
                }
            }

            describe("shared") {
                it("should not be nil") {
                    expect(RAnalyticsRATTracker.shared()).toNot(beNil())
                }

                it("should be a singleton") {
                    expect(RAnalyticsRATTracker.shared()).to(beIdenticalTo(RAnalyticsRATTracker.shared()))
                }
            }

            describe("accountIdentifier") {
                it("should equal to the given account identifier") {
                    bundle.accountIdentifier = 10

                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    expect(ratTracker.accountIdentifier).to(equal(10))
                }

                it("should equal to 0 when the plist key is not set") {
                    expect(RAnalyticsRATTracker.shared().accountIdentifier).to(equal(0))
                }
            }

            describe("applicationIdentifier") {
                it("should equal to the given application identifier") {
                    bundle.applicationIdentifier = 10

                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    expect(ratTracker.applicationIdentifier).to(equal(10))
                }

                it("should equal to 1 when the plist key is not set") {
                    expect(RAnalyticsRATTracker.shared().applicationIdentifier).to(equal(1))
                }
            }

            describe("event(withEventType:parameters:)") {
                it("should not return nil") {
                    let params: [String: Any] = [PayloadParameterKeys.acc: 555]
                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    let event = ratTracker.event(withEventType: "login", parameters: params)
                    expect(event).toNot(beNil())
                    expect(event.name).to(equal("rat.login"))
                    expect(event.parameters[PayloadParameterKeys.acc] as? Int).to(equal(params[PayloadParameterKeys.acc] as? Int))
                }
            }

            describe("endpointURL") {
                it("should set the expected endpoint to its sender and rpCookieFetcher") {
                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    let originalEndpointURL = ratTracker.endpointURL
                    let sender = ratTracker.perform(Selector((("sender"))))?.takeUnretainedValue() as? RAnalyticsSender
                    let rpCookieFetcher = ratTracker.perform(Selector((("rpCookieFetcher"))))?.takeUnretainedValue() as? RAnalyticsRpCookieFetcher

                    let endpointURL1 = URL(string: "https://endpoint1.com")!
                    ratTracker.endpointURL = endpointURL1
                    expect(sender?.endpointURL).to(equal(endpointURL1))
                    expect(rpCookieFetcher?.endpointURL).to(equal(endpointURL1))
                    expect(ratTracker.endpointURL).to(equal(endpointURL1))

                    let endpoint2 = URL(string: "https://endpoint2.com")!
                    ratTracker.endpointURL = endpoint2
                    expect(sender?.endpointURL).to(equal(endpoint2))
                    expect(rpCookieFetcher?.endpointURL).to(equal(endpoint2))
                    expect(ratTracker.endpointURL).to(equal(endpoint2))

                    ratTracker.endpointURL = originalEndpointURL
                }
            }

            describe("batchingDelay") {
                it("should be set to 1.0 by default") {
                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    expect(ratTracker.batchingDelay).to(equal(1.0))
                }
            }
            
            describe("setPageId") {
                it("should set the lastUniqueSearchIdentifier") {
                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    let testUniqueSearchId = "test_device_id_1234567890"
                    
                    ratTracker.setPageId(uniqueSearchId: testUniqueSearchId)
                    expect(ratTracker.lastUniqueSearchIdentifier).to(equal(testUniqueSearchId))
                }
                
                it("should update lastUniqueSearchIdentifier when called multiple times") {
                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    let firstUniqueSearchId = "first_unique_id_1111111111"
                    let secondUniqueSearchId = "second_unique_id_2222222222"
                    
                    ratTracker.setPageId(uniqueSearchId: firstUniqueSearchId)
                    expect(ratTracker.lastUniqueSearchIdentifier).to(equal(firstUniqueSearchId))
                    
                    ratTracker.setPageId(uniqueSearchId: secondUniqueSearchId)
                    expect(ratTracker.lastUniqueSearchIdentifier).to(equal(secondUniqueSearchId))
                }
                
                it("should accept empty string as valid input") {
                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    let emptyUniqueSearchId = ""
                    
                    ratTracker.setPageId(uniqueSearchId: emptyUniqueSearchId)
                    expect(ratTracker.lastUniqueSearchIdentifier).to(equal(emptyUniqueSearchId))
                }
                
                it("should handle special characters in unique search ID") {
                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    let specialCharUniqueSearchId = "device@123_#$%^&*()_timestamp_456"
                    
                    ratTracker.setPageId(uniqueSearchId: specialCharUniqueSearchId)
                    expect(ratTracker.lastUniqueSearchIdentifier).to(equal(specialCharUniqueSearchId))
                }
                
                it("should handle very long unique search ID") {
                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    let longUniqueSearchId = String(repeating: "a", count: 1000) + "_" + String(repeating: "1", count: 13)
                    
                    ratTracker.setPageId(uniqueSearchId: longUniqueSearchId)
                    expect(ratTracker.lastUniqueSearchIdentifier).to(equal(longUniqueSearchId))
                }
            }
        }
    }
}

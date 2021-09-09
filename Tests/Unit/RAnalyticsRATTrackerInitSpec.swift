import Quick
import Nimble
@testable import RAnalytics

// MARK: - RAnalyticsRATTrackerInitSpec

class RAnalyticsRATTrackerInitSpec: QuickSpec {
    override func spec() {
        describe("RAnalyticsRATTracker") {
            let dependenciesContainer = SimpleContainerMock()
            let bundle = BundleMock()
            bundle.mutableEndpointAddress = URL(string: "https://endpoint.co.jp/")!
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

                it("should equal to the default account identifier when the plist key is not set") {
                    expect(RAnalyticsRATTracker.shared().accountIdentifier).to(equal(477))
                }
            }

            describe("applicationIdentifier") {
                it("should equal to the given application identifier") {
                    bundle.applicationIdentifier = 10

                    let ratTracker = RAnalyticsRATTracker(dependenciesContainer: dependenciesContainer)
                    expect(ratTracker.applicationIdentifier).to(equal(10))
                }

                it("should equal to the default application identifier when the plist key is not set") {
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
        }
    }
}

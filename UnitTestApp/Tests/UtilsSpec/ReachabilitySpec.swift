import Foundation
import Quick
import Nimble
import struct SystemConfiguration.SCNetworkReachabilityFlags
@testable import RakutenAnalytics

class ReachabilitySpec: QuickSpec {

    override class func spec() {

        describe("Reachability") {

            context("init") {
                it("will create an instance of Reachability") {
                    let instance = Reachability()
                    expect(instance).toNot(beNil())
                }
            }

            context("connection available") {
                var reachability: Reachability!
                var observer: Observer!

                beforeEach {
                    reachability = Reachability()
                    observer = Observer()
                }

                afterEach {
                    reachability.removeObserver(observer)
                    reachability = nil
                    observer = nil
                }

                it("will return proper flags when connection is available") {
                    // Simulate a reachable network
                    reachability.setFlagsForTesting(.reachable)
                    expect(reachability.flags).to(equal([.reachable]))
                    expect(reachability.flags?.description).to(equal("-R"))
                }

                it("will return proper connection status for Wi-Fi") {
                    // Simulate a Wi-Fi connection
                    reachability.setFlagsForTesting(.reachable)
                    expect(reachability.connection).to(equal(.wifi))
                }

                it("will return proper connection status for cellular") {
                    // Simulate a cellular connection
                    reachability.setFlagsForTesting([.reachable, .isWWAN])
                    #if targetEnvironment(simulator)
                    expect(reachability.connection).toEventually(equal(.wifi))
                    #else
                    expect(reachability.connection).to(equal(.cellular))
                    #endif
                }

                it("will return unavailable connection status when not reachable") {
                    // Simulate no network connection
                    reachability.setFlagsForTesting([])
                    expect(reachability.connection).to(equal(.unavailable))
                }

                it("will notify observers when connection changes") {
                    reachability.addObserver(observer)

                    // Simulate a Wi-Fi connection
                    reachability.setFlagsForTesting(.reachable)
                    expect(observer.currentStatus).toEventually(equal(.wifi))

                    // Simulate a cellular connection
                    reachability.setFlagsForTesting([.reachable, .isWWAN])
                    #if targetEnvironment(simulator)
                    expect(observer.currentStatus).toEventually(equal(.wifi))
                    #else
                    expect(observer.currentStatus).toEventually(equal(.cellular))
                    #endif

                    // Simulate no network connection
                    reachability.setFlagsForTesting([])
                    expect(observer.currentStatus).toEventually(equal(.unavailable))
                }
            }
        }
    }
}

private class Observer: ReachabilityObserver {

    var currentStatus: Reachability.Connection?

    func reachabilityChanged(_ reachability: ReachabilityType) {
        currentStatus = reachability.connection
    }
}

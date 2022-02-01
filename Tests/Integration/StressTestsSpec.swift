import Quick
import Nimble
import Foundation
@testable import RAnalytics

#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

class StressTestsSpec: QuickSpec {

    override func spec() {
        describe("Stress tests") {

            let backgroundThread = DispatchQueue(label: "StressTests.Background", qos: .default)

            context("RAnalyticsSender") {
                context("send/upload concurrent calls") {
                    let publicSender = RAnalyticsSender(endpoint: URL(string: "https://endpoint.com")!,
                                                        databaseName: "databaseName",
                                                        databaseTableName: "databaseTableName")
                    let iterations = 100_000

                    // this test targets uploadTimer property
                    it("will not crash when calling send() from mutliple threads") {
                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()

                        backgroundThread.async {
                            for _ in 1...iterations {
                                publicSender!.send(jsonObject: ["key1": "value1", "key2": "value2"])
                            }
                            dispatchGroup.leave()
                        }
                        for _ in 1...iterations {
                            publicSender!.send(jsonObject: ["key1": "value1", "key2": "value2"])
                        }
                        dispatchGroup.wait()
                    }
                }
            }

            context("AnalyticsManager") {
                context("addTracker concurrent calls") {
                    let iterations = 10_000

                    it("will not crash when calling add() from mutliple threads") {
                        let analyticsManager = AnalyticsManager(dependenciesContainer: SimpleDependenciesContainer())

                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()

                        backgroundThread.async {
                            for _ in 1...iterations {
                                analyticsManager.add(TrackerMock())
                            }
                            dispatchGroup.leave()
                        }
                        for _ in 1...iterations {
                            analyticsManager.add(TrackerMock())
                        }
                        dispatchGroup.wait()
                    }
                }

                context("setEndpoint concurrent calls") {
                    let iterations = 100_000

                    // this test targets trackersLockableObject
                    it("will not crash when calling set() from mutliple threads") {
                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()

                        backgroundThread.async {
                            for _ in 1...iterations {
                                AnalyticsManager.shared().set(endpointURL: URL(string: "https://endpoint.com")!)
                            }
                            dispatchGroup.leave()
                        }
                        for _ in 1...iterations {
                            AnalyticsManager.shared().set(endpointURL: URL(string: "https://endpoint.com")!)
                        }
                        dispatchGroup.wait()
                    }
                }
            }
        }
    }

}

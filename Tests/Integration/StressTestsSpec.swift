import Quick
import Nimble
import RAnalytics

class StressTestsSpec: QuickSpec {

    override func spec() {
        describe("Stress tests") {

            context("RAnalyticsSender send/upload concurrent calls") {
                let publicSender = RAnalyticsSender(endpoint: URL(string: "https://endpoint.com")!,
                                                    databaseName: "databaseName",
                                                    databaseTableName: "databaseTableName")
                let backgroundThread = DispatchQueue(label: "StressTests.Background", qos: .default)
                let iterations = 100_000

                // this test targets uploadTimer property
                it("will not crash when calling send() from mutliple threads") {
                    let dispatchGroup = DispatchGroup()
                    dispatchGroup.enter()

                    backgroundThread.async {
                        for _ in [1...iterations] {
                            publicSender!.send(jsonObject: ["key1": "value1", "key2": "value2"])
                        }
                        dispatchGroup.leave()
                    }
                    for _ in [1...iterations] {
                        publicSender!.send(jsonObject: ["key1": "value1", "key2": "value2"])
                    }
                    dispatchGroup.wait()
                }
            }

            context("AnalyticsManager setEndpoint concurrent calls") {
                let backgroundThread = DispatchQueue(label: "StressTests.Background", qos: .default)
                let iterations = 100_000

                // this test targets trackersLockableObject
                it("will not crash when calling set() from mutliple threads") {
                    let dispatchGroup = DispatchGroup()
                    dispatchGroup.enter()

                    backgroundThread.async {
                        for _ in [1...iterations] {
                            AnalyticsManager.shared().set(endpointURL: URL(string: "https://endpoint.com")!)
                        }
                        dispatchGroup.leave()
                    }
                    for _ in [1...iterations] {
                        AnalyticsManager.shared().set(endpointURL: URL(string: "https://endpoint.com")!)
                    }
                    dispatchGroup.wait()
                }
            }
        }
    }

}

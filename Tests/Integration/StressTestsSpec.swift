import Quick
import Nimble
import Foundation
@testable import RAnalytics

#if canImport(RAnalyticsTestHelpers)
import class RAnalyticsTestHelpers.TrackerMock
#endif

#if canImport(RSDKUtils)
import class RSDKUtils.URLSessionMock
#else // SPM version
import class RSDKUtilsTestHelpers.URLSessionMock
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
                    it("will not crash when calling send() from multiple threads") {
                        stressUploadTimer()
                    }

                    it("will not crash when requests fail and calling send() from multiple threads") {
                        let sessionMock = URLSessionMock.mock(originalInstance: .shared)

                        URLSessionMock.startMockingURLSession()

                        sessionMock.stubRATResponse(statusCode: 400, completion: nil)

                        stressUploadTimer()

                        URLSessionMock.stopMockingURLSession()
                    }

                    func stressUploadTimer() {
                        // uploadTimer is set if the batching delay > 0
                        publicSender?.setBatchingDelayBlock(0.1)

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

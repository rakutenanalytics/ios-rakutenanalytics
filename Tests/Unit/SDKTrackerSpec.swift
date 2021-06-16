import Quick
import Nimble
@testable import RAnalytics

// MARK: - SDKTrackerSpec

final class SDKTrackerSpec: QuickSpec {
    override func spec() {
        describe("SDKTracker") {
            let urlSession = SwityURLSessionMock()
            let bundle = BundleMock()

            beforeEach {
                urlSession.urlRequest = nil
            }

            describe("init") {
                it("should return nil when the bundle does not define the endpoint URL") {
                    bundle.mutableEndpointAddress = nil

                    let sdkTracker = SDKTracker(bundle: bundle, session: urlSession)
                    expect(sdkTracker).to(beNil())
                }

                it("should return a new instance of SDKTracker when the bundle define the endpoint URL") {
                    bundle.mutableEndpointAddress = URL(string: "https://endpoint.co.jp")!

                    let sdkTracker = SDKTracker(bundle: bundle, session: urlSession)
                    expect(sdkTracker).toNot(beNil())
                }
            }

            describe("process") {
                let installEvent = RAnalyticsEvent(name: RAnalyticsEvent.Name.install, parameters: nil)
                let pageVisitEvent = RAnalyticsEvent(name: RAnalyticsEvent.Name.pageVisit, parameters: nil)
                let state = RAnalyticsState(sessionIdentifier: "CA7A88AB-82FE-40C9-A836-B1B3455DECAB", deviceIdentifier: "deviceId")

                it("should not process the event when the event is not _rem_install") {
                    bundle.mutableEndpointAddress = URL(string: "https://endpoint.co.jp")!
                    let sdkTracker = SDKTracker(bundle: bundle, session: urlSession, batchingDelay: 1)
                    expect(sdkTracker?.process(event: pageVisitEvent, state: state)).to(beFalse())
                    expect(urlSession.urlRequest?.httpBody).to(beNil())
                }

                it("should process the event when the event is _rem_install") {
                    bundle.mutableEndpointAddress = URL(string: "https://endpoint.co.jp")!
                    let sdkTracker = SDKTracker(bundle: bundle, session: urlSession, batchingDelay: 1)
                    expect(sdkTracker?.process(event: installEvent, state: state)).to(beTrue())
                    expect(urlSession.urlRequest).toNotEventually(beNil(), timeout: .seconds(2))
                    expect(urlSession.urlRequest?.httpBody).toNotEventually(beNil(), timeout: .seconds(2))

                    let str = String(data: urlSession.urlRequest!.httpBody!, encoding: .utf8)!
                    let jsonString = str["cpkg_none=".count..<str.count]
                    let dict = try? JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: [])
                    expect(dict).toNotEventually(beNil(), timeout: .seconds(2))

                    let json = dict as? [[String: Any]]
                    expect(json).toNotEventually(beNil(), timeout: .seconds(2))
                    expect(json?[0]["acc"] as? Int).toEventually(equal(477), timeout: .seconds(2))
                    expect(json?[0]["aid"] as? Int).toEventually(equal(1), timeout: .seconds(2))

                    let cpDictionary = json?[0]["cp"] as? [String: Any]
                    expect((cpDictionary?["app_info"] as? String)?.contains("xcode")).toEventually(beTrue(), timeout: .seconds(2))
                    expect((cpDictionary?["app_info"] as? String)?.contains("iphonesimulator")).toEventually(beTrue(), timeout: .seconds(2))
                }
            }
        }
    }
}

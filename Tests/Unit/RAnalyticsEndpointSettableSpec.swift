import Quick
import Nimble
@testable import RAnalytics

private final class RAnalyticsEndpointHandler: NSObject, EndpointSettable {
    var endpointURL: URL?
}

final class RAnalyticsEndpointSettableSpec: QuickSpec {
    override func spec() {
        describe("RAnalyticsEndpointSettable") {
            describe("endpointURL") {
                it("should return https//endpoint.com when the endpoint is https//endpoint.com") {
                    let endpoint = URL(string: "https//endpoint.com")
                    let analyticsEndpointHandler = RAnalyticsEndpointHandler()
                    analyticsEndpointHandler.endpointURL = endpoint
                    expect(analyticsEndpointHandler.endpointURL).to(equal(endpoint))
                    expect(analyticsEndpointHandler.endpointURL?.absoluteString).to(equal("https//endpoint.com"))
                }
            }
        }
    }
}

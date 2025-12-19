import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

private final class RAnalyticsEndpointHandler: NSObject, EndpointSettable {
    var endpointURL: URL?
}

@Suite("RAnalyticsEndpointSettable")
struct RAnalyticsEndpointSettableTests {
    @Suite("endpointURL")
    struct EndpointURLTests {
        @Test("should return https//endpoint.com when the endpoint is https//endpoint.com")
        func testShouldReturnHttpsEndpointComWhenTheEndpointIsHttpsEndpointCom() {
            let endpoint = URL(string: "https//endpoint.com")
            let analyticsEndpointHandler = RAnalyticsEndpointHandler()
            analyticsEndpointHandler.endpointURL = endpoint
            #expect(analyticsEndpointHandler.endpointURL == endpoint)
            #expect(analyticsEndpointHandler.endpointURL?.absoluteString == "https//endpoint.com")
        }
    }
}

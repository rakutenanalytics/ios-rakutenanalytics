import Foundation
import Quick
import Nimble
@testable import RAnalytics

// MARK: - RAnalyticsRATExpecter

public final class RAnalyticsRATExpecter {
    public var dependenciesContainer: SimpleDependenciesContainable! = nil
    public var endpointURL: URL! = nil
    public var databaseTableName: String! = nil
    public var databaseConnection: SQlite3Pointer! = nil
    public var ratTracker: RAnalyticsRATTracker! = nil

    public init() {
    }

    public func expectEvent(_ event: RAnalyticsEvent,
                     state: RAnalyticsState,
                     equal eventName: String,
                     completion: (([[String: Any]]) -> Void)? = nil) {
        let session = dependenciesContainer.session as? SwityURLSessionMock

        session?.response = HTTPURLResponse(url: endpointURL,
                                            statusCode: 200,
                                            httpVersion: nil,
                                            headerFields: nil)

        var payloads = [[String: Any]]()
        session?.completion = { [unowned self] in
            let result = DatabaseTestUtils.fetchTableContents(self.databaseTableName, connection: self.databaseConnection)
            payloads = result.deserialize()
        }

        let processed = ratTracker.process(event: event, state: state)
        expect(processed).to(beTrue())
        expect(payloads).toEventuallyNot(beNil())
        expect(payloads.first?[PayloadParameterKeys.etype] as? String).toEventually(equal(eventName))
        completion?(payloads)
    }
}

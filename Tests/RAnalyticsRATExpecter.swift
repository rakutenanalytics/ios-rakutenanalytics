import Foundation
import Quick
import Nimble
@testable import RAnalytics

// MARK: - RAnalyticsRATExpecter

final class RAnalyticsRATExpecter {
    var dependenciesContainer: SimpleDependenciesContainable! = nil
    var endpointURL: URL! = nil
    var databaseTableName: String! = nil
    var databaseConnection: SQlite3Pointer! = nil
    var ratTracker: RAnalyticsRATTracker! = nil

    func expectEvent(_ event: RAnalyticsEvent,
                     state: RAnalyticsState,
                     equal eventName: String,
                     completion: (([String: Any]?) -> Void)? = nil) {
        let session = dependenciesContainer.session as? SwityURLSessionMock

        session?.response = HTTPURLResponse(url: endpointURL,
                                            statusCode: 200,
                                            httpVersion: nil,
                                            headerFields: nil)

        var payload: [String: Any]?
        session?.completion = { [unowned self] in
            let data = DatabaseTestUtils.fetchTableContents(self.databaseTableName, connection: self.databaseConnection).first
            payload = try? JSONSerialization.jsonObject(with: data!,
                                                        options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: Any]
        }

        let processed = ratTracker.process(event: event, state: state)
        expect(processed).to(beTrue())
        expect(payload).toEventuallyNot(beNil())
        expect(payload?["etype"] as? String).toEventually(equal(eventName))
        completion?(payload)
    }
}

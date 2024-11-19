import Foundation
import Quick
import Nimble
@testable import RakutenAnalytics

// MARK: - RAnalyticsRATExpecter

public final class RAnalyticsRATExpecter {
    public var dependenciesContainer: SimpleDependenciesContainable! = nil
    public var endpointURL: URL! = nil
    public var databaseTableName: String! = nil
    public var databaseConnection: SQlite3Pointer! = nil
    public var ratTracker: RAnalyticsRATTracker! = nil

    public init() {
    }

    private func configureSession(completion: @escaping (() -> Void)) {
        let session = dependenciesContainer.session as? SwityURLSessionMock

        session?.response = HTTPURLResponse(url: endpointURL,
                                            statusCode: 200,
                                            httpVersion: nil,
                                            headerFields: nil)

        session?.completion = completion
    }

    private func processEventWithRATTracker(_ event: RAnalyticsEvent, state: RAnalyticsState) -> Bool {
        ratTracker.process(event: event, state: state)
    }

    public func expectEvent(_ event: RAnalyticsEvent,
                            state: RAnalyticsState,
                            equal eventName: String,
                            completion: (([[String: Any]]) -> Void)? = nil) {
        var payloads = [[String: Any]]()

        configureSession {
            let result = DatabaseTestUtils.fetchTableContents(self.databaseTableName, connection: self.databaseConnection)
            payloads = result.deserialize()
        }

        let processed = processEventWithRATTracker(event, state: state)
        expect(processed).to(beTrue())
        expect(payloads).toEventuallyNot(beNil())
        expect(payloads.first?[PayloadParameterKeys.etype] as? String).toEventually(equal(eventName))
        completion?(payloads)
    }

    public func processEvent(_ event: RAnalyticsEvent,
                             state: RAnalyticsState,
                             completion: (([[String: Any]]) -> Void)? = nil) {
        var payloads = [[String: Any]]()

        configureSession {
            let result = DatabaseTestUtils.fetchTableContents(self.databaseTableName, connection: self.databaseConnection)
            payloads = result.deserialize()
            completion?(payloads)
        }

        _ = processEventWithRATTracker(event, state: state)
    }
}

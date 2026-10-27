import Foundation
@testable import RakutenAnalytics

// MARK: - RAnalyticsRATExpecter

public final class RAnalyticsRATExpecter {
    public var dependenciesContainer: SimpleDependenciesContainable! = nil
    public var endpointURL: URL! = nil
    public var databaseTableName: String! = nil
    public var databaseConnection: SQlite3Pointer! = nil
    public var ratTracker: RAnalyticsRATTracker! = nil

    public init() {}

    enum ExpecterError: Error, CustomStringConvertible {
        case missingSessionMock
        case eventProcessingFailed
        case timedOut(TimeInterval)
        case eventNameMismatch(expected: String, got: String?)

        var description: String {
            switch self {
            case .missingSessionMock:
                return "RAnalyticsRATExpecter: dependenciesContainer.session is not SwiftyURLSessionMock"
            case .eventProcessingFailed:
                return "RAnalyticsRATExpecter: event processing failed"
            case .timedOut(let timeout):
                return "RAnalyticsRATExpecter: timed out after \(timeout)s waiting for upload completion"
            case .eventNameMismatch(let expected, let got):
                return "RAnalyticsRATExpecter: event name mismatch: expected \(expected), got \(got ?? "nil")"
            }
        }
    }

    private func sessionMock() throws -> SwiftyURLSessionMock {
        guard let session = dependenciesContainer.session as? SwiftyURLSessionMock else {
            throw ExpecterError.missingSessionMock
        }
        return session
    }

    private func captureCurrentPayloadsFromDB() -> [[String: Any]] {
        let result = DatabaseTestUtils.fetchTableContents(databaseTableName, connection: databaseConnection)
        return result.deserialize()
    }

    @objc private protocol RAnalyticsRATTrackerSenderAccess {
        var sender: AnalyticsSendable? { get }
    }

    private func sender() -> RAnalyticsSender? {
        // `sender` is `@objc private`; @testable import does not expose private members, so use runtime lookup.
        ratTracker.perform(#selector(getter: RAnalyticsRATTrackerSenderAccess.sender))?.takeUnretainedValue() as? RAnalyticsSender
    }

    /// 1) configure session mock response
    /// 2) process the event (sender inserts + uploads)
    /// 3) await upload completion via mocked session, capture DB payloads before delete
    /// 4) await sender idle for back-to-back expectations
    private func sendAndCapturePayloads(_ event: RAnalyticsEvent, state: RAnalyticsState, timeout: TimeInterval = 5.0) async throws -> [[String: Any]] {
        let session = try sessionMock()
        session.response = HTTPURLResponse(url: endpointURL, statusCode: 200, httpVersion: nil, headerFields: nil)

        var capturedPayloads: [[String: Any]] = []
        let processResult = ProcessResult()

        let payloads = try await TestingHelpers.awaitWithTimeout(timeout: timeout, timeoutError: ExpecterError.timedOut(timeout)) {
            try await TestingHelpers.awaitSenderUpload(session: session, timeout: timeout, onUploadComplete: {
                capturedPayloads = self.captureCurrentPayloadsFromDB()
            }) {
                Task { @MainActor in
                    processResult.processed = self.ratTracker.process(event: event, state: state)
                }
            }
            return capturedPayloads
        }

        guard processResult.processed == true else {
            throw ExpecterError.eventProcessingFailed
        }

        try await TestingHelpers.waitForSenderIdle(sender(), timeout: 2.0)
        return payloads
    }

    /// Async version of expectEvent for Swift Testing framework
    public func expectEventAsync(_ event: RAnalyticsEvent, state: RAnalyticsState, equal eventName: String) async throws -> [[String: Any]] {
        let payloads = try await sendAndCapturePayloads(event, state: state)

        let gotEtype = payloads.first?[PayloadParameterKeys.etype] as? String
        guard gotEtype == eventName else {
            throw ExpecterError.eventNameMismatch(expected: eventName, got: gotEtype)
        }

        return payloads
    }

    /// Async version of processEvent for Swift Testing framework
    public func processEventAsync(_ event: RAnalyticsEvent, state: RAnalyticsState) async throws -> [[String: Any]] {
        try await sendAndCapturePayloads(event, state: state)
    }
}

private final class ProcessResult: @unchecked Sendable {
    var processed: Bool?
}

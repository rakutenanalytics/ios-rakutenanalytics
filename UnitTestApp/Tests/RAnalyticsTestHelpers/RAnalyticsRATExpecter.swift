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

    /// One-shot async latch for a single payload capture.
    /// (Actor-based to be Swift 6 async-safe.)
    private actor PayloadLatch {
        private var result: Result<[[String: Any]], Error>?
        private var continuation: CheckedContinuation<[[String: Any]], Error>?

        func succeed(_ value: [[String: Any]]) {
            resolve(.success(value))
        }

        private func resolve(_ newResult: Result<[[String: Any]], Error>) {
            guard result == nil else { return }
            result = newResult
            if let continuation {
                self.continuation = nil
                continuation.resume(with: newResult)
            }
        }

        func wait(timeout: TimeInterval) async throws -> [[String: Any]] {
            try await withThrowingTaskGroup(of: [[String: Any]].self) { group in
                group.addTask { try await self.waitIndefinitely() }
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    throw ExpecterError.timedOut(timeout)
                }

                let value = try await group.next()!
                group.cancelAll()
                return value
            }
        }

        private func waitIndefinitely() async throws -> [[String: Any]] {
            if let result {
                return try result.get()
            }

            return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[[String: Any]], Error>) in
                if let result {
                    cont.resume(with: result)
                } else {
                    continuation = cont
                }
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

    /// 1) configure session completion
    /// 2) process the event (sender inserts + uploads)
    /// 3) await session completion, then read DB once and return payloads
    private func sendAndCapturePayloads(_ event: RAnalyticsEvent, state: RAnalyticsState, timeout: TimeInterval = 5.0) async throws -> [[String: Any]] {
        let latch = PayloadLatch()

        let session = try sessionMock()
        session.response = HTTPURLResponse(url: endpointURL, statusCode: 200, httpVersion: nil, headerFields: nil)
        session.completion = {
            // Called right after the sender's dataTask completion handler finishes.
            // `deleteBlobs` is queued asynchronously, so records should still be present here.
            let payloads = self.captureCurrentPayloadsFromDB()
            Task { await latch.succeed(payloads) }
        }

        guard ratTracker.process(event: event, state: state) else {
            throw ExpecterError.eventProcessingFailed
        }

        return try await latch.wait(timeout: timeout)
    }
    
    /// Async version of expectEvent for Swift Testing framework
    public func expectEventAsync(_ event: RAnalyticsEvent, state: RAnalyticsState, equal eventName: String, completion: @escaping ([[String: Any]]) -> Void) async throws {
        let payloads = try await sendAndCapturePayloads(event, state: state)

        let gotEtype = payloads.first?[PayloadParameterKeys.etype] as? String
        guard gotEtype == eventName else {
            throw ExpecterError.eventNameMismatch(expected: eventName, got: gotEtype)
        }

        completion(payloads)
    }
    
    /// Async version of processEvent for Swift Testing framework
    public func processEventAsync(_ event: RAnalyticsEvent, state: RAnalyticsState, completion: @escaping ([[String: Any]]) -> Void) async throws {
        let payloads = try await sendAndCapturePayloads(event, state: state)
        completion(payloads)
    }
}



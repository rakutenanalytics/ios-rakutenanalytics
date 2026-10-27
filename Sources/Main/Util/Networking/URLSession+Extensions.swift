import Foundation

// MARK: - Sessionable

protocol Sessionable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// MARK: - SwiftySessionable

protocol SwiftySessionable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

private extension URLSession {
    /// Routes through `dataTask(with:completionHandler:)` so URLSessionMock swizzling works in tests.
    func dataFromDataTask(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let response = response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                continuation.resume(returning: (data ?? Data(), response))
            }
            task.resume()
        }
    }
}

extension URLSession: Sessionable, SwiftySessionable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await dataFromDataTask(for: request)
    }
}

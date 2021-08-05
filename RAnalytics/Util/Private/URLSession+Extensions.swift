import Foundation

// MARK: - RAnalyticsSessionable

protocol RAnalyticsSessionable {
    func createDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTaskable
}

extension URLSession: RAnalyticsSessionable {
    func createDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTaskable {
        dataTask(with: request, completionHandler: completionHandler)
    }
}

// MARK: - SwiftySessionable

protocol SwiftySessionable {
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Result<(data: Data?, response: URLResponse), Error>) -> Void) -> URLSessionTaskable
}

extension URLSession: SwiftySessionable {}

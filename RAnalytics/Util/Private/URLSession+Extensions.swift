import Foundation

@objc protocol Sessionable {
    @objc func createDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTaskable
}

extension URLSession: Sessionable {
    @objc func createDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTaskable {
        dataTask(with: request, completionHandler: completionHandler)
    }
}

protocol SwiftySessionable {
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Result<(data: Data?, response: URLResponse), Error>) -> Void) -> URLSessionTaskable
}

extension URLSession: SwiftySessionable {}

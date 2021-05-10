import Foundation

@objc protocol Sessionable {
    @objc func createDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTaskable
}

extension URLSession: Sessionable {
    @objc func createDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTaskable {
        dataTask(with: request, completionHandler: completionHandler)
    }
}

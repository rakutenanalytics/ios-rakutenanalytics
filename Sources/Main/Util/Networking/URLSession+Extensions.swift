import Foundation

// MARK: - Sessionable

protocol Sessionable {

    func createDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTaskable
}

extension URLSession: Sessionable {
    func createDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTaskable {
        dataTask(with: request, completionHandler: completionHandler)
    }
}

// MARK: - SwiftySessionable

protocol SwiftySessionable {
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Result<(data: Data?, response: URLResponse), Error>) -> Void) -> URLSessionTaskable
}

extension URLSession: SwiftySessionable {
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Result<(data: Data?, response: URLResponse), Error>) -> Void) -> URLSessionTaskable {

        return dataTask(with: request) { (data, response, error) in
            if let error = error {
                completionHandler(.failure(error))
                return
            }

            guard let response = response else {
                assertionFailure()
                completionHandler(.failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown)))
                return
            }

            completionHandler(.success((data, response)))
        }
    }
}

// MARK: - URLSessionTaskable

protocol URLSessionTaskable {
    func resume()
}

extension URLSessionTask: URLSessionTaskable {}

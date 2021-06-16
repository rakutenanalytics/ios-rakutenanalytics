internal extension URLSession {

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

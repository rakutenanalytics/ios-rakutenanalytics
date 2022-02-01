import Foundation

#if canImport(RSDKUtils)
import protocol RSDKUtils.URLSessionTaskable
#else // SPM version
import protocol RSDKUtilsMain.URLSessionTaskable
#endif

internal extension URLSession {

    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Result<(data: Data?, response: URLResponse), Error>) -> Void) -> URLSessionTaskable {

        return dataTask(with: request) { (data, response, error) in
            if let error = error {
                completionHandler(.failure(AnalyticsError.embeddedError(error as NSError)))
                return
            }

            guard let response = response else {
                // This assertionFailure should be removed as it does not make sense to keep it.
                // Apple should have it on their side.
                assertionFailure()
                completionHandler(.failure(AnalyticsError.embeddedError(ErrorConstants.unknownError)))
                return
            }

            completionHandler(.success((data, response)))
        }
    }
}

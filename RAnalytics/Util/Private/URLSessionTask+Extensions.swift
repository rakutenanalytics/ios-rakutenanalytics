import Foundation

@objc protocol URLSessionTaskable {
    @objc func resume()
}

extension URLSessionTask: URLSessionTaskable {}

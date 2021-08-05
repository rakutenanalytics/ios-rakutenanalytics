import Foundation

protocol URLSessionTaskable {
    func resume()
}

extension URLSessionTask: URLSessionTaskable {}

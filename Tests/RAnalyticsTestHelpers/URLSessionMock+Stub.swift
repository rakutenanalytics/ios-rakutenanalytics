import Foundation

// MARK: - Stub Response

extension URLSessionMock {
    public func stubResponse(url: URL? = URL(string: "empty"),
                             statusCode: Int,
                             headerFields: [String: String]? = nil,
                             completion: (() -> Void)? = nil) {
        guard let url = url else {
            completion?()
            return
        }
        httpResponse = HTTPURLResponse(url: url,
                                       statusCode: statusCode,
                                       httpVersion: nil,
                                       headerFields: headerFields)

        onCompletedTask = completion
        responseData = nil
        responseError = nil
    }
}

// MARK: - Stub RAT Response

extension URLSessionMock {
    public func stubRATSuccessResponse(url: URL? = URL(string: "https://rat.rakuten.co.jp"),
                                       cookieName: String,
                                       cookieValue: String,
                                       expiryDate: String) {
        let cookie = "\(cookieName)=\(cookieValue); path=/; expires=\(expiryDate); session-only=false; domain=.rakuten.co.jp"

        stubResponse(url: url,
                     statusCode: 200,
                     headerFields: ["Set-Cookie": cookie])
    }
    
    public func stubRATServerErrorResponse(url: URL? = URL(string: "https://rat.rakuten.co.jp")) {
        stubResponse(url: url, statusCode: 500)
    }
}

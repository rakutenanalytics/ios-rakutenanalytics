import Foundation

#if canImport(RSDKUtils)
import RSDKUtils
#else // SPM version
import RSDKUtilsTestHelpers
#endif

extension URLSessionMock {
    public func stubRATResponse(statusCode: Int, completion: (() -> Void)?) {
        httpResponse = HTTPURLResponse(url: URL(string: "empty")!,
                                       statusCode: statusCode,
                                       httpVersion: nil,
                                       headerFields: nil)
        onCompletedTask = completion
        responseData = nil
        responseError = nil
    }
}

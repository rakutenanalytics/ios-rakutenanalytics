import Foundation
#if canImport(RSDKUtils)
import struct RSDKUtils.RLogger
#else // SPM version
import RLogger
#endif

enum AnalyticsError: Error, Equatable {
    case embeddedError(NSError)
    case detailedError(domain: String, code: Int, description: String, reason: String)
}

extension AnalyticsError {
    /// Convert `AnalyticsError` to `NSError`.
    func nsError() -> NSError {
        switch self {
        case .embeddedError(let error):
            return error as NSError

        case .detailedError(let domain, let code, let description, let reason):
            return NSError(domain: domain,
                           code: code,
                           userInfo: [NSLocalizedDescriptionKey: description, NSLocalizedFailureReasonErrorKey: reason])
        }
    }

    /// Log the error with `RLogger`.
    @discardableResult
    func log() -> String? {
        switch self {
        case .embeddedError(let error):
            return RLogger.error(message: error.localizedDescription)

        case .detailedError(let domain, let code, let description, let reason):
            return RLogger.error(message: "\(domain), \(code), \(description), \(reason)")
        }
    }
}

import Foundation

enum ClearDataError: Error, CustomNSError, Equatable {
    case alreadyRunning

    static var errorDomain: String { ErrorDomain.analyticsManagerErrorDomain }

    var errorCode: Int {
        switch self {
        case .alreadyRunning: return ErrorCode.clearDataAlreadyRunning.rawValue
        }
    }

    var errorUserInfo: [String: Any] {
        switch self {
        case .alreadyRunning: return [NSLocalizedDescriptionKey: ErrorDescription.clearDataAlreadyRunning]
        }
    }
}

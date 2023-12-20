import Foundation

// MARK: - Error Raiser

enum ErrorRaiser {
    static var errorHandler: RAnalyticsErrorBlock?

    static func raise(_ error: AnalyticsError) {
        DispatchQueue.main.async {
            error.log()
            errorHandler?(error.nsError())
        }
    }
}

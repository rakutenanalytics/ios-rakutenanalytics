import Foundation

enum ErrorDomain {
    private static let domainName = "com.rakuten.esd.sdk.analytics.error.domain"
    static let analyticsManagerErrorDomain = "\(domainName).analytics-manager"
    static let ratTrackerErrorDomain = "\(domainName).rat-tracker"
    static let sdkTrackerErrorDomain = "\(domainName).sdk-tracker"
    static let rpCookieFetcherErrorDomain = "\(domainName).rp-cookie-fetcher"
    static let databaseErrorDomain = "\(domainName).database"
    static let senderErrorDomain = "\(domainName).sender"
    static let pushEventHandlerErrorDomain = "\(domainName).push-event-handler"
    static let reachabilityNotifierErrorDomain = "\(domainName).reachability-notifier"
    static let analyticsEventTrackerErrorDomain = "\(domainName).analytics-event-tracker"
    static let analyticsEventObserverErrorDomain = "\(domainName).analytics-event-observer"
    static let pushConversionTrackingErrorDomain = "\(domainName).push-conversion-tracking"
}

enum ErrorCode: Int {
    // Database
    case databaseTableCreationFailure
    case databaseAppWillTerminate
    case databaseBeginTransactionFailure
    case databaseCommitTransactionFailure
    case databasePrepareStatementFailure

    // Rp Cookie Fetcher
    case rpCookieFetcherCreationFailed
    case getRpCookieFromCookieStorageFailed
    case rpCookieCantBeFetched
    case getRpCookieFromRATFailed

    // SDK Tracker
    case sdkTrackerCreationFailed

    // Reachability Notifier
    case scNetworkReachabilityCreateWithNameFailed
    case scNetworkReachabilitySetCallback
    case scNetworkReachabilityScheduleWithRunLoop

    // RAT Tracker
    case eventsNotProcessedByRATracker

    // Location
    case locationHasFailed

    // Push Event Handler
    case pushEventHandlerCacheFailed

    // Sender
    case senderCreationFailed
    case senderSendEventsHasFailed

    // Push Event Handler
    case pushEventHandlerCacheCouldNotBeCleared

    // Analytics Event Tracker
    case analyticsEventTrackerCantTrackEvent

    // Analytics Event Observer
    case analyticsEventObserverCantTrackEvent

    // Push conversion tracking
    case pushConversionTrackingFailure
}

enum ErrorDescription {
    // Status Code
    static let statusCodeError = "invalid_response"

    // SDK Tracker
    static let eventsNotProcessedBySDKTracker = "The events cannot be processed by the SDK Tracker."

    // RAT Tracker
    static let eventsNotProcessedByRATTracker = "The events cannot be processed by the RAT Tracker."

    // Rp Cookie Fetcher
    static let rpCookieFetcherCreationFailed = "RAnalyticsRpCookieFetcher could not be created."
    static let rpCookieCantBeFetched = "The Rp Cookie can't be fetched by RAnalyticsRpCookieFetcher."
    static let rpCookieFetcherError = "RAnalyticsRpCookieFetcher Error."
    static let getRpCookieFromRATFailed = "The Rp Cookie Fetcher could not get the Rp Cookie from RAT."

    // Sender
    static let senderCreationFailed = "The Sender could not be created."
    static let senderSendEventsHasFailed = "Sender could not send events."

    // Database
    static let databaseError = "An error occurred with RAnalyticsDatabase."
    static let databasePrepareTableError = "RAnalyticsDatabase's prepareTable is cancelled"

    // Location
    static let locationHasFailed = "Failed to acquire device location."

    // Reachability Notifier
    static let reachabilityNotifierCreationFailed = "ReachabilityNotifier creation has failed."

    // Push Event Handler
    static let pushEventHandlerCacheFailed = "PushEventHandler cache creation has failed."
    static let pushEventHandlerCacheCouldNotBeCleared = "PushEventHandler cache could not be cleared."

    // Analytics Event Tracker
    static let analyticsEventTrackerCantTrackEvent = "AnalyticsEventTracker can't track the Extension Event."

    // Analytics Event Observer
    static let analyticsEventObserverCantTrackEvent = "AnalyticsEventObserver can't track the Extension Event."

    // Push Conversion
    static let pushConversionTrackingFailed = "The push conversion tracking failed."
}

enum ErrorReason {
    // Status Code
    static func statusCodeError(_ statusCode: Int) -> String {
        "Expected status code 200, got \(statusCode)"
    }

    // Endpoint
    static let endpointMissing = "Your application's Info.plist must contain a key 'RATEndpoint' set to your endpoint URL."

    // Database
    static let databaseConnectionIsNil = "The database connection is nil."
    static let databaseAppIsTerminatingError = "The app is terminating."

    // Sender
    static let senderSerializationFailure = "Sender failed to serialize event dictionary."
    static let senderRequestBodyCreationFailure = "Failed to create RAT request body data."

    // Reachability Notifier
    static let networkReachabilityCreateWithNameFailure = "SCNetworkReachabilityCreateWithName failed."
    static let networkReachabilitySetCallbackFailure = "SCNetworkReachabilitySetCallback failed"
    static let networkReachabilityScheduleWithRunLoopFailure = "SCNetworkReachabilityScheduleWithRunLoop failed"

    // Connection
    static let connectionIsOffline = "The connection is offline."

    // Unknown
    static let unknown = "Unknown error."

    // Parameters
    static let emptyParameters = "One of the parameters is empty."
}

enum ErrorConstants {
    static let unknownError = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown)

    static func statusCodeError(with statusCode: Int) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey: ErrorDescription.statusCodeError,
                        NSLocalizedFailureReasonErrorKey: ErrorReason.statusCodeError(statusCode)]
        return NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: userInfo)
    }

    static func rpCookieCantBeFetchedError(reason: String) -> NSError {
        NSError(domain: ErrorDomain.rpCookieFetcherErrorDomain,
                code: ErrorCode.rpCookieCantBeFetched.rawValue,
                userInfo: [NSLocalizedDescriptionKey: ErrorDescription.rpCookieCantBeFetched,
                           NSLocalizedFailureReasonErrorKey: reason])
    }

    static let pushConversionError: NSError = {
        NSError(domain: ErrorDomain.pushConversionTrackingErrorDomain,
                code: ErrorCode.pushConversionTrackingFailure.rawValue,
                userInfo: [NSLocalizedDescriptionKey: ErrorDescription.pushConversionTrackingFailed,
                           NSLocalizedFailureReasonErrorKey: ErrorReason.emptyParameters])
    }()
}

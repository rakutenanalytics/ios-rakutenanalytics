import Foundation

enum ErrorMessage {
    static let endpointMissing = "Your application's Info.plist must contain a key 'RATEndpoint' set to your endpoint URL."
    static let eventsNotProcessedByRATTracker = "The events cannot be processed by the RAT Tracker."
    static let eventsNotProcessedBySDKTracker = "The events cannot be processed by the SDK Tracker."
    static let databaseConnectionIsNil = "The database connection is nil."
    static let rpCookieCantBeFetched = "The Rp Cookie can't be fetched."
    static let rpCookieFetcherCreationFailed = "The Rp Cookie Fetcher could not be created."
    static let senderCreationFailed = "The Sender could not be created."
}

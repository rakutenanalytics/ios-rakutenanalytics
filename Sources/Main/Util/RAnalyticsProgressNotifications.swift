import Foundation

public extension Notification.Name {

    /// The RAnalyticsSender instance sends this notification when it is about to make a request to upload a group of records.
    /// `Notification.object` is the JSON payload being uploaded, in its unserialized `Array` form.
    static let RAnalyticsWillUpload = Notification.Name(rawValue: "com.rakuten.esd.sdk.notifications.analytics.rat.will_upload")

    /// The RAnalyticsSender instance sends this notification after an upload failed.
    ///
    /// `object` is the JSON payload that was being uploaded, in its unserialized `Array` form.
    /// `userInfo` contains a `NSError` instance under the key `NSUnderlyingErrorKey`, that uses the `NSURLErrorDomain` domain.
    static let RAnalyticsUploadFailure = Notification.Name(rawValue: "com.rakuten.esd.sdk.notifications.analytics.rat.upload_failed")

    /// The RAnalyticsSender instance sends this notification after an upload succeeded.
    ///
    /// `object` is the JSON payload that was being uploaded, in its unserialized `Array` form.
    static let RAnalyticsUploadSuccess = Notification.Name(rawValue: "com.rakuten.esd.sdk.notifications.analytics.rat.upload_succeeded")
}

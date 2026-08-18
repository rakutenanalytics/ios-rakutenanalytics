import Foundation

/// Records inbound URL scheme deep links for QA display in the destination sample app.
enum IncomingDeepLinkStore {
    static let didReceiveNotification = Notification.Name("DestDeepLinkDidReceive")

    static var lastReceivedURL: URL?

    static func record(url: URL?) {
        lastReceivedURL = url
        NotificationCenter.default.post(name: didReceiveNotification, object: nil)
    }

    static var ref: String? {
        queryValue(named: "ref")
    }

    /// Path segment from the opened URL (without a leading slash), e.g. `path/to/resource`.
    /// Empty when the URL has no path component.
    static var pathComponent: String? {
        guard let path = lastReceivedURL?.path, !path.isEmpty, path != "/" else {
            return nil
        }
        return String(path.dropFirst())
    }

    private static func queryValue(named name: String) -> String? {
        guard let url = lastReceivedURL,
              let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            return nil
        }
        return queryItems.first(where: { $0.name == name })?.value
    }
}

import Foundation
import WebKit

extension UIView {
    /// Recursively try to find a URL in a view hierarchy.
    ///
    /// - Returns: the `WKWebView`'s URL or `nil`.
    func getWebViewURL() -> URL? {
        var url: URL?

        if let webViewURL = (self as? WKWebView)?.url {
            url = webViewURL
        }

        if let aURL = url?.absoluteURL {
            // If a URL is found, only keep a safe subpart of it (scheme+host+path) since
            // query parameters etc may have sensitive information (access tokens…).
            let fullComponents = NSURLComponents(url: aURL, resolvingAgainstBaseURL: false)
            let components = NSURLComponents()
            components.scheme = fullComponents?.scheme
            components.host   = fullComponents?.host
            components.path   = fullComponents?.path
            url = components.url?.absoluteURL

        } else {
            // - Warning: recursion
            for subview in subviews {
                if let result = subview.getWebViewURL() {
                    url = result
                    break
                }
            }
        }

        return url
    }
}

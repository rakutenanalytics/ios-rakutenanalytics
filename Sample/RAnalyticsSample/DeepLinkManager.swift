import Foundation
import UIKit

/// Records inbound deep links in the sample app.
enum DeepLinkManager {
    static let didReceiveNotification = Notification.Name("DeepLinkDidReceive")

    static var lastReceivedURL: URL?
    static var lastEntryPoint: String?

    static func record(url: URL?, entryPoint: String) {
        lastReceivedURL = url
        lastEntryPoint = entryPoint
        NotificationCenter.default.post(
            name: didReceiveNotification,
            object: nil,
            userInfo: [
                "url": url?.absoluteString ?? "",
                "entryPoint": entryPoint
            ]
        )
    }

    static var inboundURLScheme: String {
        "ranalyticssample"
    }

    static func makeInboundTestURL(ref: String? = nil) -> URL? {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "jp.co.rakuten.RAnalyticsSample"
        let accountId = (Bundle.main.object(forInfoDictionaryKey: "RATAccountIdentifier") as? NSNumber)?.stringValue ?? "123"
        let appId = (Bundle.main.object(forInfoDictionaryKey: "RATAppIdentifier") as? NSNumber)?.stringValue ?? "456"
        let refValue = ref ?? bundleIdentifier
        let query = "ref=\(refValue)&ref_acc=\(accountId)&ref_aid=\(appId)&ref_link=qa_campaign&ref_comp=qa_news"
        return URL(string: "\(inboundURLScheme)://?\(query)")
    }
}

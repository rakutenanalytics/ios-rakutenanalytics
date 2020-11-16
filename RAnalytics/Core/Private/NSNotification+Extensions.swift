import Foundation

/// Discover events
/// See https://confluence.rakuten-it.com/confluence/display/ESD/Usage+Tracking+for+Discover
extension Notification.Name {
    static let discoverPageVisit               = Self("_rem_discover_discoverpage_visit")
    static let discoverPageTap                 = Self("_rem_discover_discoverpage_tap")
    static let discoverPageRedirect            = Self("_rem_discover_discoverpage_redirect")
    static let discoverPreviewVisit            = Self("_rem_discover_discoverpreview_visit")
    static let discoverPreviewTap              = Self("_rem_discover_discoverpreview_tap")
    static let discoverPreviewRedirect         = Self("_rem_discover_discoverpreview_redirect")
    static let discoverPreviewShowMore         = Self("_rem_discover_discoverpreview_showmore")
}

/// @warning This extension is declared as public to be used in Objective-C classes
/// @warning This extension will have to be internal when the callers are migrated to Swift
@objc public extension NSNotification {
    static let discoverPageVisit = Notification.Name.discoverPageVisit
    static let discoverPageTap = Notification.Name.discoverPageTap
    static let discoverPageRedirect = Notification.Name.discoverPageRedirect
    static let discoverPreviewVisit = Notification.Name.discoverPreviewVisit
    static let discoverPreviewTap = Notification.Name.discoverPreviewTap
    static let discoverPreviewRedirect = Notification.Name.discoverPreviewRedirect
    static let discoverPreviewShowMore = Notification.Name.discoverPreviewShowMore
}

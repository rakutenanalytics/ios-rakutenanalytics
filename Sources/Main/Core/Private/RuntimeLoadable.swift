import Foundation

/// All classes that implement this protocol must be added
/// to the static list defined in _RAnalyticsSwiftLoader.m
@objc public protocol RuntimeLoadable {
    @objc static func loadSwift()
}

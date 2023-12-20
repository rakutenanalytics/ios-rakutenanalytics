import Foundation

/// Interface for any class to declare an endpoint URL property.
@objc(RAnalyticsEndpointSettable) public protocol EndpointSettable: NSObjectProtocol {
    /// Property for setting the endpoint URL at runtime.
    @objc var endpointURL: URL? { get set }
}

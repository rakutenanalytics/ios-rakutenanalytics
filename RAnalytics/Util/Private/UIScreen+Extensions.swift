import Foundation

@objc public protocol Screenable {
    var bounds: CGRect { get }
}

extension UIScreen: Screenable {}

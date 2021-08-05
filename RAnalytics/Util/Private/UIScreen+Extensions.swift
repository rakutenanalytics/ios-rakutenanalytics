import Foundation

protocol Screenable {
    var bounds: CGRect { get }
}

extension UIScreen: Screenable {}
